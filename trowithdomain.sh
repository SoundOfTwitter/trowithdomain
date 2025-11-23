#!/bin/bash

# 输入密码
read -p "请输入密码 (passwd): " passwd
# 输入域名
read -p "请输入域名 (server_domain): " server_domain
# 检查输入
if [ -z "$passwd" ] || [ -z "$server_domain" ]; then
    echo "错误：密码和域名不能为空！"
    exit 1
fi
echo "$server_domain" > /home/domain.txt
echo "域名已写入 /home/domain.txt"

apt install -y curl jq nginx certbot trojan

systemctl enable nginx
systemctl start nginx

CONFIG="/etc/trojan/config.json"
# 修改 password
jq --arg p "$passwd" '.password = [$p]' "$CONFIG" > /tmp/config.tmp && mv /tmp/config.tmp "$CONFIG"

# 修改 ssl
jq --arg d "$server_domain" '
  .ssl.cert = "/home/trojan/fullchain.pem"
  | .ssl.key = "/home/trojan/privkey.pem"
  | .ssl.alpn += ["h2"]
' "$CONFIG" > /tmp/config.tmp && mv /tmp/config.tmp "$CONFIG"
echo "配置已更新：$CONFIG"

# 修改 ssl
#jq --arg d "$server_domain" '
  #.ssl.cert = "/etc/letsencrypt/live/\($d)/fullchain.pem"
  #| .ssl.key = "/etc/letsencrypt/live/\($d)/privkey.pem"
  #| .ssl.alpn += ["h2"]
#' "$CONFIG" > /tmp/config.tmp && mv /tmp/config.tmp "$CONFIG"
#echo "配置已更新：$CONFIG"

systemctl enable trojan
systemctl start trojan
