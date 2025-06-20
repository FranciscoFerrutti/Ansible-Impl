#!/usr/bin/env bash
set -euo pipefail

export BUCKET_NAME="${bucket_name}"
export AWS_REGION="${aws_region}"
export ZIP_1_FILE_NAME="${zip_1_file_name}"
export ZIP_2_FILE_NAME="${zip_2_file_name}"
ZIP_1_BASE_NAME=$(echo "$ZIP_1_FILE_NAME" | sed 's/\.zip$//')
export ZIP_1_BASE_NAME
ZIP_2_BASE_NAME=$(echo "$ZIP_2_FILE_NAME" | sed 's/\.zip$//')
export ZIP_2_BASE_NAME

apt update -y && apt upgrade -y

apt install -y nginx unzip wget
wget http://$BUCKET_NAME.s3.$AWS_REGION.amazonaws.com/$ZIP_1_FILE_NAME -O /tmp/$ZIP_1_FILE_NAME
unzip /tmp/$ZIP_1_FILE_NAME -d /tmp
mv /tmp/$ZIP_1_BASE_NAME/* /var/www/html

wget http://$BUCKET_NAME.s3.$AWS_REGION.amazonaws.com/$ZIP_2_FILE_NAME -O /tmp/$ZIP_2_FILE_NAME
unzip /tmp/$ZIP_2_FILE_NAME -d /tmp
# create a new directory for the second web application
mkdir -p /var/www/html2
mv /tmp/$ZIP_2_BASE_NAME/* /var/www/html2

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
chown -R www-data:www-data /var/www/html2
chmod -R 777 /var/www/html2

systemctl enable nginx
systemctl start nginx

