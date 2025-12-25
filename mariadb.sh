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


