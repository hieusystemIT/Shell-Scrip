chmod là viết tắt của Change Mode
- Giúp kiểm soát ai đó có thể đọc, viết (chỉnh sửa) và thực thi 1 file.
- Có thể cho phép mọi người hoặc nhóm người cụ thể, hoặc chỉ mình mới có thể có các quyền đó

## Xem quyền: ls -l

```
$ ls -l file.txt
-rwxr-xr-- 1 hieudd developers 4096 Aug 27 10:00 file.txt
```

- Ký tự đầu tiên: loại file (`-` file thường, `d` thư mục, `l` symbolic link)
- 3 ký tự tiếp theo (`rwx`): quyền của owner (chủ sở hữu)
- 3 ký tự tiếp theo (`r-x`): quyền của group (nhóm)
- 3 ký tự cuối (`r--`): quyền của others (người khác)
- Sau đó: tên owner, tên group

### Sơ đồ

```
   -   rwx   r-x   r--
   |    |     |     |
 loại  owner group others
 file  (chủ) (nhóm) (khác)

 Trong mỗi nhóm 3 ký tự:
   vị trí 1 = r (read)    -> có thì +4
   vị trí 2 = w (write)   -> có thì +2
   vị trí 3 = x (execute) -> có thì +1

 owner  : r w x  =  4+2+1 = 7
 group  : r - x  =  4+0+1 = 5
 others : r - -  =  4+0+0 = 4
                        ↓
                gộp lại => 754
```

## Ý nghĩa r, w, x

- r (read = 4): đọc nội dung file / liệt kê file trong thư mục
- w (write = 2): sửa, xóa nội dung file / tạo-xóa file trong thư mục
- x (execute = 1): chạy file như chương trình / cd vào thư mục đó

## Bảng giá trị octal

| Số | Ký hiệu | Ý nghĩa |
|---|---|---|
| 0 | `---` | Không có quyền |
| 1 | `--x` | Thực thi |
| 2 | `-w-` | Ghi |
| 3 | `-wx` | Thực thi + Ghi |
| 4 | `r--` | Đọc |
| 5 | `r-x` | Đọc + Thực thi |
| 6 | `rw-` | Đọc + Ghi |
| 7 | `rwx` | Đọc + Ghi + Thực thi |

## Đổi quyền bằng chmod

Dạng số (octal) — cộng 4+2+1 cho từng nhóm owner/group/others:

```
chmod 754 file.txt   # owner=rwx(7), group=r-x(5), others=r--(4)
```

Dạng ký hiệu — u (user/owner), g (group), o (others), a (all):

```
chmod u+x file.txt   # thêm quyền x cho owner
chmod g-w file.txt   # bỏ quyền w của group
chmod o=r file.txt   # đặt others chỉ có quyền r
chmod a+r file.txt   # thêm quyền r cho tất cả
```

## Đổi owner / group

```
chown hieudd file.txt              # đổi owner
chown hieudd:developers file.txt   # đổi cả owner và group
chgrp developers file.txt          # chỉ đổi group
```
(thường cần sudo nếu không phải file của mình)
