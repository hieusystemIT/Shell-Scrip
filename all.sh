#!/bin/bash
set -e 
# các biến 
FILE_PATH="/etc/nginx/conf.d/test.com.conf"
FILE_PATH_HTML="/home/www/test.com"
FILE_PATH_SSL="/etc/nginx/ssl"

KEY_FILE="$FILE_PATH_SSL/nginx.key"
CERT_FILE="$FILE_PATH_SSL/nginx.crt"
CONFIG_FILE="$FILE_PATH_SSL/openssl.cnf"
INDEX_FILE="$FILE_PATH_HTML/index.html"


# Cập nhật hệ thống
echo "Updating system..."
sudo yum update -y 

# Cài đặt nginx
echo "Installing Nginx..."
sudo yum install nginx -y

# Kiểm tra nginx đã cài đặt thành công hay chưa
if [ $? -eq 0 ]; then
    echo "Nginx installed successfully!"
else
    echo "Nginx installation failed!"
    exit 1
fi

# Mở firewall cho Nginx
echo "Opening firewall for Nginx..."
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload

# Khởi động và kích hoạt nginx
echo "Starting Nginx..."
sudo systemctl start nginx
sudo systemctl enable nginx

# Kiểm tra trạng thái nginx
echo "Checking Nginx status..."
sudo systemctl status nginx


# Thông báo hoàn tất
echo "Nginx installation and configuration completed successfully!"

# Kiểm tra nếu file không tồn tại
if [ ! -f "$FILE_PATH" ]; then
    echo "File does not exist. Creating file..."
    touch "$FILE_PATH"
    echo "File created: $FILE_PATH"
else
    echo "File already exists: $FILE_PATH"
fi

if [ ! -f "$FILE_PATH_HTML" ]; then
    echo "File does not exist. Creating file..."
    mkdir -p "$FILE_PATH_HTML"
    echo "File created: $FILE_PATH_HTML"
else
    echo "File already exists: $FILE_PATH_HTML"
fi

#tạo html
touch "$INDEX_FILE"
sudo bash -c 'cat > /home/www/test.com/index.hmtl << EOF 
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Test Nginx</title>
</head>
<body>
    <h1>Hello, Nginx is working!</h1>
</body>
</html>
EOF'

echo "tạo html done"

# tắt SElinux 
sudo setenforce 0
echo "đã tắt SElinux tạm thời"

# phân quyền
chown -R nginx:nginx $FILE_PATH_HTML
chmod 755 $FILE_PATH_HTML

# tạo ssl
echo "install openssl..."
yum install mod_ssl openssl -y

# Tạo thư mục lưu chứng chỉ SSL
echo "Creating directory for SSL certificates..."
sudo mkdir -p $FILE_PATH_SSL
sudo chmod 700 $FILE_PATH_SSL

# Tạo file cấu hình OpenSSL (openssl.cnf)
echo "Creating OpenSSL config file..."
sudo bash -c "cat > $CONFIG_FILE << EOF
[req]
default_bits = 2048
default_keyfile = $KEY_FILE
distinguished_name = req_distinguished_name
x509_extensions = v3_ca
prompt = no

[req_distinguished_name]
countryName = US
stateOrProvinceName = SomeState
localityName = SomeCity
organizationName = SomeOrganization
commonName = localhost

[v3_ca]
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth, clientAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = localhost
EOF"

# tạo chứng chỉ khóa 
sudo openssl req -x509 -newkey rsa:4096 -keyout /etc/nginx/ssl/nginx.key -out /etc/nginx/ssl/nginx.crt -days 365 -config $CONFIG_FILE -nodes
echo "done ssl" 

echo "Cài đặt và config nginx success"

# INSTALL PHP
sudo dnf install -y epel-release
sudo dnf install -y https://rpms.remirepo.net/enterprise/remi-release-9.rpm
sudo dnf module list php
sudo dnf module enable php:remi-8.2 -y
sudo dnf install -y php-fpm php-cli php-mysqlnd


echo "installed php-FPM"

# Đường dẫn tới file cấu hình (Cập nhật đường dẫn đúng cho hệ thống của bạn)
PHP_FPM_CONF="/etc/php-fpm.d/www.conf"

# Kiểm tra xem file có tồn tại không
if [[ ! -f "$PHP_FPM_CONF" ]]; then
    echo "File cấu hình không tồn tại: $PHP_FPM_CONF"
    exit 1
fi

# Thay đổi các tham số cấu hình
echo "Đang thay đổi cấu hình PHP-FPM..."

# Nội dung cấu hình cần thêm
CONFIG_TO_ADD="\
listen = /var/run/php-fpm/www.sock\n\
listen.allowed_clients = 127.0.0.1\n\
listen.owner = nginx\n\
listen.group = nginx\n\
listen.mode = 0660\n\
user = nginx\n\
group = nginx\n\
pm = dynamic\n\
pm.max_children = 50\n\
pm.start_servers = 5\n\
pm.min_spare_servers = 5\n\
pm.max_spare_servers = 35\n\
slowlog = /var/log/php-fpm/www-slow.log\n\
php_admin_value[error_log] = /var/log/php-fpm/www-error.log\n\
php_admin_flag[log_errors] = on\n\
php_value[session.save_handler] = files\n\
php_value[session.save_path] = /var/lib/php/session\n\
security.limit_extensions = .php .php3 .php4 .php5 .php7"

# Sử dụng echo và append nội dung cấu hình vào sau [www]
sudo sed -i "/\[www\]/a $CONFIG_TO_ADD" "$PHP_FPM_CONF"

echo "Cập nhật cấu hình PHP-FPM thành công!"

# Khởi động lại dịch vụ PHP-FPM để áp dụng thay đổi
echo "Khởi động lại dịch vụ PHP-FPM..."
sudo systemctl restart php-fpm
sudo systemctl status php-fpm

echo "Dịch vụ PHP-FPM đã được khởi động lại."

# thêm cấu hình để nginx connect php
echo "sửa file cấu hình nginx"

sudo tee /etc/nginx/conf.d/test.com.conf <<EOF > /dev/null
server {
    listen 443 ssl;
    
    server_name test.com www.test.com;

    ssl_certificate /etc/nginx/ssl/nginx.crt;    
    ssl_certificate_key /etc/nginx/ssl/nginx.key;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers 'HIGH:!aNULL:!MD5';
    ssl_prefer_server_ciphers on;

    access_log /var/log/nginx/test.com.access.log;
    error_log /var/log/nginx/test.com.error.log warn;

    root /home/www/test.com;    
    index index.php index.htm;

    location ~ \.php$ {   
        include fastcgi_params;
        fastcgi_pass unix:/var/run/php-fpm/www.sock; 	
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name; 
        fastcgi_index index.php; 
    }

    error_page 497 https://\$host\$request_uri; #xử lý lỗi 497, chuyển hướng ng dùng từ http sang https
    
}

server {		#chuyển hướng vĩnh viễn (301 redirect) từ HTTP sang HTTPS.
    listen 80;  
    server_name test.com www.test.com;
    return 301 https://\$host\$request_uri; #host đại diện cho tên miền người dùng yêu cầu (ví dụ: test.com), và \$request_uri là phần đường dẫn yêu cầu(ví dụ: /index.html)
}
EOF

echo "done"

# install mariadb
echo "install mariadb ..."
sudo dnf install mariadb-server mariadb -y

# Kiểm tra mariadb đã cài đặt thành công hay chưa
if [ $? -eq 0 ]; then
    echo "mariadb installed successfully!"
else
    echo "ariadb installation failed!"
    exit 1
fi

sudo systemctl start mariadb
sudo systemctl enable mariadb
sudo systemctl status mariadb

sudo mysql_secure_installation <<EOF
y
Citigo@2024
Citigo@2024
y
y
y
y
EOF

# Đăng nhập vào MariaDB và tạo database + user
echo "Tạo database và user mới..."

# Nhập tên database và user
read -p "Nhập tên database: " db_name
read -p "Nhập tên user: " db_user
read -sp "Nhập mật khẩu cho user $db_user: " db_user_password
echo ""

# Tạo database và user, cấp quyền
sudo mysql -uroot -p"Citigo@2024" <<MYSQL_SCRIPT
CREATE DATABASE $db_name;
CREATE USER '$db_user'@'localhost' IDENTIFIED BY '$db_user_password';
GRANT ALL PRIVILEGES ON $db_name.* TO '$db_user'@'localhost';
FLUSH PRIVILEGES;
MYSQL_SCRIPT

echo "Database '$db_name' và user '$db_user' đã được tạo thành công."

# Kiểm tra kết nối với user mới
echo "Kiểm tra kết nối MariaDB với user mới..."
sudo mysql -u$db_user -p"$db_user_password" -e "SHOW DATABASES;"

echo "Hoàn tất cài đặt MariaDB."

# WORDPRESS

#  điều hướng vào root
echo "install..."
cd /home/www/test.com && sudo curl -O https://wordpress.org/latest.tar.gz



# Giải nén WordPress
sudo tar -xvf latest.tar.gz
sudo mv wordpress/* .
sudo rm -rf wordpress latest.tar.gz

echo "giải nén done"

# Đặt quyền sở hữu và phân quyền
sudo chown -R nginx:nginx /home/www/test.com
sudo chmod -R 755 /home/www/test.com

# copy config mẫu
sudo cp wp-config-sample.php wp-config.php

# thay đổi file config
sudo sed -i "s/database_name_here/$db_name/g" /home/www/test.com/wp-config.php
echo "done_db"
sudo sed -i "s/username_here/$db_user/g" /home/www/test.com/wp-config.php
echo "done_user"
sudo sed -i "s/password_here/$db_user_password/g" /home/www/test.com/wp-config.php
echo "done_pass"

echo " khởi động lại nginx..."

echo " cài đặt wordpress done "
