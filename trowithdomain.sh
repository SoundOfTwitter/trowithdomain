#!/bin/bash

# 输入密码
read -sp "请输入密码 (passwd): " passwd
echo

# 输入域名
read -p "请输入域名 (server_domain): " server_domain

# 检查输入
if [ -z "$passwd" ] || [ -z "$server_domain" ]; then
    echo "错误：密码和域名不能为空！"
    exit 1
fi

apt install -y curl jq nginx trojan

# 安装 certbot 和 nginx 插件
apt install -y certbot python3-certbot-nginx

systemctl enable nginx
#systemctl start nginx

# 使用 certbot 为域名申请证书（自动配置 nginx）
#certbot --nginx -d "$server_domain" --non-interactive --agree-tos --email admin@$server_domain || {
#    echo "错误：证书申请失败！"
#    exit 1
#}
systemctl stop nginx
# certbot certonly --standalone -d "$server_domain" --email admin@$server_domain --agree-tos --noninteractive
systemctl start nginx


# 创建或覆盖续期任务（每天 0点 和 12点 执行两次）
echo "0 0,12 * * * root certbot renew --quiet --nginx" > /etc/cron.d/certbot-renew

CONFIG="/etc/trojan/config.json"
# 修改 password
jq --arg p "$passwd" '.password = [$p]' "$CONFIG" > /tmp/config.tmp && mv /tmp/config.tmp "$CONFIG"

# 修改 ssl
jq --arg d "$server_domain" '
  .ssl.cert = "/etc/letsencrypt/live/\($d)/fullchain.pem"
  | .ssl.key = "/etc/letsencrypt/live/\($d)/privkey.pem"
  | .ssl.alpn += ["h2"]
' "$CONFIG" > /tmp/config.tmp && mv /tmp/config.tmp "$CONFIG"

echo "配置已更新：$CONFIG"


systemctl enable trojan
systemctl start trojan

