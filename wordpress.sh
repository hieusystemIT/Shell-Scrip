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
sudo sed -i "s/database_name_here/$lấy biến từ db/g" /home/www/test.com/wp-config.php
echo "done_db"
sudo sed -i "s/username_here/$lấy biến từ db/g" /home/www/test.com/wp-config.php
echo "done_user"
sudo sed -i "s/password_here/$lấy biến từ db/g" /home/www/test.com/wp-config.php
echo "done_pass"

echo " khởi động lại nginx..."
systemctl restart nginx
echo " cài đặt wordpress done truy cập IP server để test "

