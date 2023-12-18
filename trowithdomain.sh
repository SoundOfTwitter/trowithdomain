#!/bin/bash

publicIP=$(curl -s ifconfig.me)

# 第一条命令
sudo useradd -m -s /bin/bash trojanuser

# 第二条命令，设置密码为"Liu2023"
echo -e "Liu2023\nLiu2023" | sudo passwd trojanuser

# 第三条命令
sudo usermod -G sudo trojanuser

# 第四条命令
# su -l trojanuser

# 第一条命令，创建组 certusers，询问密码时输入 "Liu2023"
su - trojanuser <<EOF
echo -e "Liu2023\n" | sudo -S groupadd certusers
sudo useradd -r -M -G certusers trojan
sudo useradd -r -m -G certusers acme
sudo apt update
sudo apt upgrade -y
sudo apt install -y socat cron curl
sudo systemctl start cron
sudo systemctl enable cron
sudo apt install -y libcap2-bin xz-utils
sudo apt install -y nginx
sudo rm /etc/nginx/sites-enabled/default
EOF
# sudo vim /etc/nginx/sites-available/mydomiantro
echo "server {" > /etc/nginx/sites-available/mydomiantro
echo "    listen 127.0.0.1:80 default_server;" > /etc/nginx/sites-available/mydomiantro
echo "" > /etc/nginx/sites-available/mydomiantro
echo "    server_name hunterliu.uk.eu.org;" > /etc/nginx/sites-available/mydomiantro
echo "" > /etc/nginx/sites-available/mydomiantro
echo "    location / {" > /etc/nginx/sites-available/mydomiantro
echo "        proxy_pass https://www.bjmu.edu.cn;" > /etc/nginx/sites-available/mydomiantro
echo "    }" > /etc/nginx/sites-available/mydomiantro
echo "" > /etc/nginx/sites-available/mydomiantro
echo "}" > /etc/nginx/sites-available/mydomiantro
echo "" > /etc/nginx/sites-available/mydomiantro
echo "server {" > /etc/nginx/sites-available/mydomiantro
echo "    listen 127.0.0.1:80;" > /etc/nginx/sites-available/mydomiantro
echo "" > /etc/nginx/sites-available/mydomiantro
echo "    server_name " > /etc/nginx/sites-available/mydomiantro
sed -i "s/\"$/&$publicIP/" /etc/nginx/sites-available/mydomiantro
sed -i '$s/$/;/' /etc/nginx/sites-available/mydomiantro
echo "" > /etc/nginx/sites-available/mydomiantro
echo "    return 301 https://hunterliu.uk.eu.org$request_uri;" > /etc/nginx/sites-available/mydomiantro
echo "}" > /etc/nginx/sites-available/mydomiantro
echo "" > /etc/nginx/sites-available/mydomiantro
echo "server {" > /etc/nginx/sites-available/mydomiantro
echo "    listen 0.0.0.0:80;" > /etc/nginx/sites-available/mydomiantro
echo "    listen [::]:80;" > /etc/nginx/sites-available/mydomiantro
echo "" > /etc/nginx/sites-available/mydomiantro
echo "    server_name _;" > /etc/nginx/sites-available/mydomiantro
echo "    location / {" > /etc/nginx/sites-available/mydomiantro
echo "        return 301 https://$host$request_uri;" > /etc/nginx/sites-available/mydomiantro
echo "    }" > /etc/nginx/sites-available/mydomiantro
echo "" > /etc/nginx/sites-available/mydomiantro
echo "    location /.well-known/acme-challenge {" > /etc/nginx/sites-available/mydomiantro
echo "       root /var/www/acme-challenge;" > /etc/nginx/sites-available/mydomiantro
echo "    }" > /etc/nginx/sites-available/mydomiantro
echo "}" > /etc/nginx/sites-available/mydomiantro
sudo ln -s /etc/nginx/sites-available/mydomiantro /etc/nginx/sites-enabled/
sudo systemctl restart nginx
sudo systemctl status nginx
sudo mkdir -p /etc/letsencrypt/live
sudo chown -R acme:acme /etc/letsencrypt/live
sudo usermod -G certusers nginx
sudo mkdir -p  /var/www/acme-challenge
sudo chown -R acme:certusers /var/www/acme-challenge
sudo su -l -s /bin/bash acme
curl  https://get.acme.sh | sh
exit
sudo su -l -s /bin/bash acme
acme.sh --set-default-ca  --server  letsencrypt
acme.sh --issue -d hunterliu.uk.eu.org -w /var/www/acme-challenge
acme.sh --install-cert -d liuxiantao.ml --key-file /etc/letsencrypt/live/private.key --fullchain-file /etc/letsencrypt/live/certificate.crt
acme.sh  --upgrade  --auto-upgrade
chown -R acme:certusers /etc/letsencrypt/live
chmod -R 750 /etc/letsencrypt/live
exit
sudo apt-get install -y trojan
sudo chown -R trojan:trojan /usr/local/etc/trojan
sudo cp /usr/local/etc/trojan/config.json /usr/local/etc/trojan/config.json.bak
sed -i '8s/.*/        "aDm8H%MdA"/' /usr/local/etc/trojan/config.json
sed -i '13s/.*/        "cert": "\/etc\/letsencrypt\/live\/certificate.crt",/' /usr/local/etc/trojan/config.json
sed -i '14s/.*/        "key": "\/etc\/letsencrypt\/live\/private.key",/' /usr/local/etc/trojan/config.json
sed -i '9d' /usr/local/etc/trojan/config.json
sed -i '9s/.*/User=trojan/' /etc/systemd/system/trojan.service
sudo systemctl daemon-reload
sudo setcap CAP_NET_BIND_SERVICE=+eip /usr/local/bin/trojan
sudo systemctl enable trojan
sudo systemctl restart trojan
sudo systemctl enable trojan
sudo systemctl enable nginx
