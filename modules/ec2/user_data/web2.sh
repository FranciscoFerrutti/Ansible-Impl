#!/usr/bin/env bash
set -euo pipefail

export BUCKET_NAME="${bucket_name}"
export AWS_REGION="${aws_region}"
export ZIP_FILE_NAME="${zip_file_name}"
ZIP_BASE_NAME=$(echo "$ZIP_FILE_NAME" | sed 's/\.zip$//')
export ZIP_BASE_NAME

apt update -y && apt upgrade -y

apt install -y nginx unzip wget firewalld
wget http://$BUCKET_NAME.s3.$AWS_REGION.amazonaws.com/$ZIP_FILE_NAME -O /tmp/$ZIP_FILE_NAME
unzip /tmp/$ZIP_FILE_NAME -d /tmp
mv /tmp/$ZIP_BASE_NAME/* /var/www/html

# enable password authentication
sudo sed -i 's/^#\?PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config
# enable password authentication in file /etc/ssh/sshd_config.d/60-cloudimg-settings.conf
sudo sed -i 's/^#\?PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config.d/60-cloudimg-settings.conf
sudo sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config.d/60-cloudimg-settings.conf
# enable root login via ssh
sudo sed -i 's/^#\?PermitRootLogin .*/PermitRootLogin yes/' /etc/ssh/sshd_config
# enable root login via ssh key
sudo sed -i 's/^#\?PubkeyAuthentication .*/PubkeyAuthentication yes/' /etc/ssh/sshd_config

# set password for ubuntu user
echo 'ubuntu:password' | sudo chpasswd

# restart ssh service to apply changes
sudo systemctl reload sshd
sudo systemctl restart ssh

chown -R www-data:www-data /var/www/html
chmod -R 777 /var/www/html

systemctl enable nginx
systemctl start nginx

# disable ufw if it is running
if systemctl is-active --quiet ufw; then
    systemctl stop ufw
    systemctl disable ufw

firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https
fiewwall-cmd --permanent --add-service=ssh
firewall-cmd --reload
systemctl enable firewalld
systemctl start firewalld

