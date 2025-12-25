#!/bin/bash
# các biến 
FILE_PATH="/etc/nginx/conf.d/test.com.conf"
FILE_PATH_HTML="/home/www/test.com"
FILE_PATH_SSL="/etc/nginx/ssl"

KEY_FILE="$FILE_PATH_SSL/nginx.key"
CERT_FILE="$FILE_PATH_SSL/nginx.crt"
CONFIG_FILE="$FILE_PATH_SSL/openssl.cnf"
INDEX_FILE="$FILE_PATH_HTML/index.html"

# Mở firewall cho Nginx
echo "Opening firewall for Nginx..."
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload

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
    touch "$FILE_PATH
    echo "File created: $FILE_PATH"
else
    echo "File already exists: $FILE_PATH"
fi

if [ ! -f "$FILE_PATH_HTML" ]; then
    echo "File does not exist. Creating file..."
    touch "$FILE_PATH_HTML"
    echo "File created: $FILE_PATH_HTML"
else
    echo "File already exists: $FILE_PATH_HTML"
fi

#tạo html
touch "$INDEX_FILE"
sudo bash -c 'cat > /home/www/test.com/index.html << EOF
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

# tắt SElinux 
sudo setenforce 0
echo "đã tắt SElinux tạm thời"

# phân quyền
chown -R nginx:nginx /home/www/test.com
chmod 755 /home/www/test.com

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

# thay đổi file config 
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
    index index.html index.htm;

    location / {	# khối locaiton này sẽ xử lý các yêu cầu đến thư mục gốc kiểm tra xem thư mục có tồn tại hay không nếu không trả về lỗi 404
        try_files $uri $uri/ =404;
    }

    error_page 497 https://$host$request_uri; #xử lý lỗi 497, chuyển hướng ng dùng từ http sang https
    
}

server {		#chuyển hướng vĩnh viễn (301 redirect) từ HTTP sang HTTPS.
    listen 80;  
    server_name test.com www.test.com;
    return 301 https://$host$request_uri; #host đại diện cho tên miền người dùng yêu cầu (ví dụ: test.com), và $request_uri là phần đường dẫn yêu cầu(ví dụ: /index.html)
}
EOF'

# khởi động lại nginx
sudo systemctl restart nginx

echo "Cài đặt và config nginx success"

