#!/bin/bash

# --- 1. 输入和检查 ---

# 输入密码 (使用 -s 静默输入)
#read -s -p "请输入密码 (passwd): " passwd
read -p "请输入trojan密码 (passwd): " passwd
echo # 换行
# 输入域名
read -p "请输入服务器域名 (server_domain): " server_domain

# 检查输入
if [ -z "$passwd" ] || [ -z "$server_domain" ]; then
    echo "错误：密码和域名不能为空！"
    exit 1
fi

# 将域名写入 admin 用户目录
echo "$server_domain" > /home/admin/domain.txt
echo "域名已写入 /home/admin/domain.txt"

# --- 2. 依赖安装和文件准备 (需要 Root 权限) ---

echo "正在安装依赖，需要输入 sudo 密码..."
# 确保安装了所有依赖
sudo apt update
sudo apt install -y curl nginx certbot trojan

# 复制证书文件 (假设 /etc/letsencrypt/archive/ 中证书已存在)
# 注意：此步骤依赖于证书已由 certbot 获取
sudo cp /etc/letsencrypt/archive/"$server_domain"/fullchain1.pem /etc/trojan/fullchain.pem
sudo cp /etc/letsencrypt/archive/"$server_domain"/privkey1.pem /etc/trojan/privkey.pem

# --- 3. 创建 trojan 用户和配置权限 ---

echo "正在创建 trojan 专用用户..."
# 创建 trojan 用户和用户组
# 注意：groupadd 和 useradd 命令本身是幂等的，重复执行不会报错
sudo groupadd -g 54321 trojan || true
sudo useradd -g trojan -s /usr/sbin/nologin trojan || true

# 更改配置和证书目录的所有权给 trojan 用户，确保其可以读取证书和配置
sudo chown -R trojan:trojan /etc/trojan

# --- 4. 修改 Trojan 配置 (已修复 jq 语法和权限问题) ---

sudo sed -i \
    -e '/^[[:space:]]*"password1",[[:space:]]*$/d' \
    -e "s/^[[:space:]]*\"password2\"[[:space:]]*$/        \"$passwd\"/" \
    -e '/"http\/1\.1"/ s/$/,/' \
    -e '/"http\/1\.1"/ a\            "h2"' \
    /etc/trojan/config.json

sudo sed -i '/"ssl": {/,/},/ {
    s#"cert": "[^"]*"#"cert": "/etc/trojan/fullchain.pem"#;
    s#"key": "[^"]*"#"key": "/etc/trojan/privkey.pem"#;
}' /etc/trojan/config.json

# --- 5. 修改 Systemd 服务文件 ---

# 修改服务运行用户 (使用 sed 模式匹配替换)
echo "正在修改 Trojan 服务文件以使用 'trojan' 用户运行..."
sudo sed -i '/^User=/c\User=trojan' /lib/systemd/system/trojan.service
sudo systemctl daemon-reload

# --- 6. 服务启动和系统优化 ---

echo "正在启动 Trojan 服务和应用 BBR 优化..."
# 启动和启用服务
sudo systemctl start trojan
sudo systemctl enable trojan

# 内核优化 BBR (使用 tee -a 安全写入)
echo "net.core.default_qdisc=fq" | sudo tee -a /etc/sysctl.conf > /dev/null
echo "net.ipv4.tcp_congestion_control=bbr" | sudo tee -a /etc/sysctl.conf > /dev/null

# 应用 sysctl 配置
sudo sysctl -p

# 检查 BBR 状态
lsmod | grep bbr
sudo sysctl net.ipv4.tcp_available_congestion_control

# 最后重启系统
echo "配置完成。系统将在 5 秒后重启..."
sleep 5
sudo reboot
