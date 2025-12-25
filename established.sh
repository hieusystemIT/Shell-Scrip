#!/bin/bash
# Hàm kiểm tra tính hợp lệ của port
check_port_validity() {
    if [[ "$1" -ge 1 && "$1" -le 65535 ]]; then
        return 0  # Port hợp lệ
    else
        return 1  # Port không hợp lệ
    fi
}
# Nhập địa chỉ IP và port
read -p "Nhập port: " port

if ! check_port_validity "$port"; then
    echo "Port không hợp lệ. Port phải nằm trong khoảng từ 1 đến 65535."
    exit 1
fi

# Kiểm tra số lượng kết nối đến IP và port đó
connections=$(ss -tn state established | grep ":$port" | wc -l)

# In kết quả
echo "Số lượng kết nối qua port $port là: $connections"
