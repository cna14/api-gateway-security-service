***

# 🚀 API Gateway Security Service – Hướng dẫn cài đặt và chạy cho người mới

Giải pháp bảo mật API tập trung dựa trên **Kong Gateway**, **JWT**, **Rate Limiting** và **ELK Logging** mà bạn có thể triển khai dễ dàng chỉ với vài bước!  

---

## 📁 1. Cấu trúc và ý nghĩa từng thư mục/file

```
api-gateway-security-service/
├── backend/             # Dịch vụ backend mẫu (NodeJS/Express)
│   ├── dockerfile
│   ├── index.js
│   └── package.json
├── logging/             # Cấu hình pipeline log Logstash
│   └── logstash.conf
├── configure_jwt.sh     # Script khởi tạo JWT consumer/key cho Kong
├── docker-compose.yml   # Khởi chạy toàn bộ Kong, backend, ELK
├── kong_register.sh     # Script tự động tạo service, route, plugin, log
├── DEMO_GUIDE.md        # Hướng dẫn kiểm thử đa kịch bản, checklist demo
├── permitFW5.txt        # (tùy chọn) File phụ trợ khác (nếu có)
└── README.md            # Tài liệu này!
```

---

## 📦 2. Cài đặt môi trường bắt buộc

- **Windows**: cài Docker Desktop, bật WSL2.  
- **Linux/Mac**: cài Docker, Docker Compose, Git.
- **Yêu cầu tối thiểu**: RAM 4GB+, network không proxy chặn port 8000/8001/5601.

**Dành cho người mới:** Nếu chưa cài Docker:
- Windows tải tại: https://www.docker.com/products/docker-desktop/
- Sau cài xong, mở Docker Desktop, chờ icon cá voi xanh hiện “Running” là thành công.

---

## 📝 3. Hướng dẫn từng bước build & chạy dự án

### **Bước 1: Mở Terminal/cmd vào thư mục dự án**

```
cd <thư-mục-chứa-dự-án>
```
Ví dụ:  
```
cd E:\university\V.1\CNPTUDDN\BTL\api-gateway-security-service
```

### **Bước 2: Build tất cả container**
Chỉ cần gõ:
```
docker compose build
```
> Lệnh này sẽ tạo image cho Kong, backend, logstash,... Chuẩn bị cho khởi chạy sau đó (có thể mất ~1-5 phút lần đầu).

### **Bước 3: Khởi động toàn bộ hệ thống**
```
docker compose up -d
```
> Lệnh này sẽ bật tất cả các dịch vụ trong nền. Đợi tầm 1-2 phút.

**Kiểm tra toàn bộ container đã chạy:**
```
docker compose ps
```
> Tất cả trạng thái phải là “running” hoặc “Up”.

### **Bước 4: Khởi tạo cấu hình Kong và JWT (rất quan trọng!)**
```
bash kong_register.sh
```
> Lệnh này sẽ tự động:
> - Tạo service, route (`/api`)
> - Bật JWT/Auth, Rate Limiting
> - Kích hoạt log UDP
> - Gọi luôn file cấu hình JWT (`configure_jwt.sh`)

---

## 🔍 4. Thử API – hướng dẫn từng lệnh test đơn giản

- **Test API Public:**
    ```
    curl http://localhost:8000/api/public
    ```

- **Test API Secure (có JWT):**
    ```
    curl -H "Authorization: Bearer <jwt_token>" http://localhost:8000/api/secure
    ```
    (Lấy `<jwt_token>` đã tạo/log ra từ script, hoặc hỏi nhóm trưởng/giảng viên)

- **Test lỗi bị chặn (không JWT):**
    ```
    curl http://localhost:8000/api/secure
    ```

- **Spam thử rate limit:**
    ```
    for i in {1..15}; do curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8000/api/public; done
    ```

---

## 📊 5. Theo dõi & xem log trên Kibana (giao diện web)

1. Mở trình duyệt truy cập: [http://localhost:5601](http://localhost:5601)
2. Chọn **Discover** (menu bên trái)
3. (Lần đầu setup) – Tạo index pattern:  
   - name: `kong-logs-*`
   - trường thời gian: `@timestamp`
4. Xem realtime log mỗi khi gửi request lên API Gateway
5. Lọc theo path, status, client_ip, user_agent...

---

## 🛑 6. Kết thúc/dừng hệ thống

- Dừng toàn bộ service (giữ dữ liệu):
    ```
    docker compose down
    ```
- Dừng và xóa SẠCH dữ liệu:
    ```
    docker compose down -v
    ```

---

## 💡 7. Các lỗi thường gặp và cách khắc phục

| Vấn đề                           | Xử lý                                                        |
|-----------------------------------|--------------------------------------------------------------|
| Không truy cập được Kibana        | Chờ thêm hoặc kiểm tra docker logs kibana, elasticsearch     |
| Kong không tạo được service       | Chờ 10s sau khi up rồi chạy lại script kong_register.sh      |
| Logstash không nhận log           | Kiểm tra port/logstash.conf, xem plugin udp-log trên Kong    |
| JWT không hợp lệ                  | Chạy lại configure_jwt.sh, lấy lại key/secret               |
| Docker lỗi permission             | Chạy terminal bằng quyền admin, restart Docker Desktop       |

---

## 📋 8. Tham khảo, demo thêm

- Toàn bộ kịch bản kiểm thử thực tế, lệnh CURL mẫu, cách kiểm thử automation hãy xem:  
    [`DEMO_GUIDE.md`](./DEMO_GUIDE.md)

---

## 👩‍💻 9. Ghi chú
- Mỗi lần cập nhật cấu hình Kong thì nên chạy lại `kong_register.sh`.
- Nếu file log/ELK bị lỗi, restart từng service bằng:
    ```
    docker compose restart <service-name>
    ```
    (vd: `docker compose restart kong`)

---

Chúc bạn thành công với bài thực hành bảo mật API Gateway!  
> **Nếu gặp bất kỳ lỗi nào không tìm được hướng dẫn, hãy chụp lại terminal và hỏi nhóm trợ giúp/khoá học.**

---

***

