# 🚀 API Gateway Security Service – Quick Start Guide

Giải pháp bảo mật API tập trung với Kong Gateway, JWT Authentication, Rate Limiting và ELK Logging.

---

## 📁 Cấu trúc thư mục dự án

api-gateway-security-service/
├── backend/ # Backend API mẫu (NodeJS/Express)
│ ├── dockerfile
│ ├── index.js
│ └── package.json
├── logging/ # Cấu hình Logstash
│ └── logstash.conf
├── configure_jwt.sh
├── docker-compose.yml
├── kong_register.sh
├── DEMO_GUIDE.md
├── README.md
└── permitFW5.txt # (tuỳ chọn) Dữ liệu hoặc cấu hình phụ trợ


---

## 1. Chuẩn bị hệ thống

- [ ] Cài **Docker Desktop**: https://www.docker.com/products/docker-desktop
- [ ] Cài **Git** (Windows tải tại https://git-scm.com)
- [ ] Kiểm tra có **curl** (nên dùng PowerShell hoặc cmd mới nhất)
- [ ] Kiểm tra Docker đã khởi động (cá voi xanh ở thanh taskbar)

---

## 2. Các bước build và chạy dự án

### **Bước 1: Clone project về máy**

text

git clone https://github.com/<username>/<repo>.git
cd api-gateway-security-service

text

### **Bước 2: Build Docker Compose**

text

docker compose build

text

### **Bước 3: Khởi động toàn bộ service**

text

docker compose up -d

text

### **Bước 4: Đăng ký service và cấu hình bảo mật**

text

bash kong_register.sh

text
> Nếu bash lỗi trên Windows, chạy bằng WSL hoặc đổi sang Git Bash/MINGW64.

---

## 3. Kiểm thử nhanh hệ thống

Copy & paste trực tiếp từng lệnh dưới đây vào terminal/cmd/PowerShell.

#### Test API public:

text

curl http://localhost:8000/api/public

text

#### Test API bảo vệ JWT (cần token):

text

curl -H "Authorization: Bearer <jwt_token>" http://localhost:8000/api/secure

text

#### Test bị chặn không token:

text

curl http://localhost:8000/api/secure

text

#### Kiểm thử rate-limit:

text

for i in {1..15}; do curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8000/api/public; done

text

---

## 4. Mở Kibana để xem hệ thống log

1. Truy cập http://localhost:5601
2. Vào (menu) **Discover**
3. Tạo index pattern: `kong-logs-*` với trường thời gian `@timestamp`
4. Dữ liệu sẽ hiện realtime mỗi khi bạn test API

---

## 5. Kết thúc và cleanup

- Dừng toàn bộ service:
    ```
    docker compose down
    ```
- Dừng và xóa sạch dữ liệu:
    ```
    docker compose down -v
    ```

---

## 6. Troubleshooting nhanh

- Nếu **Kong lỗi DB**: kiểm tra `kong-db` trong compose, logs.
- Nếu **Kibana không có log**: kiểm tra logstash/conf, plugin udp-log trên Kong.
- Nếu **JWT sai**: chạy lại cấu hình bằng `configure_jwt.sh`.

---

## 7. Demo & kiểm thử đầy đủ

Tham khảo checklist, ví dụ, hướng dẫn kịch bản tại [`DEMO_GUIDE.md`](./DEMO_GUIDE.md).