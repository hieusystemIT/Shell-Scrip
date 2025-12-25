#!/bin/bash
# install
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
listen = 127.0.0.1:9000\n\
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