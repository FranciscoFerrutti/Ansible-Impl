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

chown -R www-data:www-data /var/www/html
chmod -R 777 /var/www/html

systemctl enable nginx
systemctl start nginx

firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https
firewall-cmd --reload
systemctl enable firewalld
systemctl start firewalld

