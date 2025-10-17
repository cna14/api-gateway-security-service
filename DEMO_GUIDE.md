Dưới đây là **file `demo_guide.md` hoàn chỉnh**, bao gồm cả **mục lục điều hướng**, đầy đủ **các kịch bản kiểm thử** và **hướng dẫn thao tác Kibana**, được tối ưu cho việc demo và báo cáo đồ án.

***

# Demo API Gateway Security Service – Kịch bản kiểm thử tổng hợp

Tài liệu này hướng dẫn kiểm thử toàn bộ hệ thống API Gateway Security Service: từ Kong Gateway, dịch vụ backend, bảo mật JWT, rate-limiting cho đến pipeline logging ELK (Logstash, Elasticsearch, Kibana).

---

## 📘 Mục lục

1. [Giới thiệu](#giới-thiệu)
2. [Kiểm thử các endpoint cơ bản](#1-kiểm-thử-các-endpoint-cơ-bản)
   - [a. Public endpoint (không cần auth)](#a-public-endpoint-không-cần-auth)
   - [b. Secure endpoint thiếu token](#b-secure-endpoint-thiếu-token)
   - [c. Secure endpoint với JWT hợp lệ](#c-secure-endpoint-với-jwt-hợp-lệ)
3. [Kiểm thử vượt rate limit](#2-kiểm-thử-vượt-rate-limit)
4. [Kiểm thử request lỗi](#3-kiểm-thử-request-lỗi)
   - [a. Truy cập sai path](#a-truy-cập-sai-path)
   - [b. Truy cập với JWT hết hạn](#b-truy-cập-với-jwt-hết-hạn)
5. [Kiểm thử phân tích log nâng cao](#4-kiểm-thử-phân-tích-log-nâng-cao)
   - [a. Request từ nhiều IP khác nhau](#a-request-từ-nhiều-ip-khác-nhau)
   - [b. Request gửi kèm user-agent đặc biệt](#b-request-gửi-kèm-user-agent-đặc-biệt)
6. [Kiểm thử brute-force/bot](#5-kiểm-thử-brute-forcebot)
7. [Kiểm thử các phương thức RESTful](#6-kiểm-thử-các-phương-thức-restful)
8. [Kiểm tra log trên Kibana](#7-hướng-dẫn-kiểm-tra-log-trên-kibana)
9. [Checklist xác nhận hệ thống hoạt động hoàn chỉnh](#8-checklist-xác-nhận-hệ-thống-hoạt-động-hoàn-chỉnh)

---

## Giới thiệu

Sau khi hệ thống được khởi động hoàn chỉnh (Kong, backend, PostgreSQL, Logstash, Elasticsearch, Kibana), hãy sử dụng các kịch bản sau để:
- Xác minh pipeline ghi log toàn diện.
- Thử nghiệm bảo mật (JWT, rate-limit).
- Sinh dữ liệu log thực tế để hiển thị trên Kibana dashboard.

---

## 1. Kiểm thử các endpoint cơ bản

### a. Public endpoint (không cần auth)
```
curl http://localhost:8000/api/public
# Kỳ vọng: {"message":"This is a public endpoint"}
```
- Log Kibana: method GET, path `/api/public`, status 200.

### b. Secure endpoint thiếu token
```
curl -i http://localhost:8000/api/secure
# Kỳ vọng: HTTP/1.1 401 Unauthorized
```
- Log: status 401, path `/api/secure`.

### c. Secure endpoint với JWT hợp lệ
```
curl -i -H "Authorization: Bearer <jwt_token>" http://localhost:8000/api/secure
# Kỳ vọng: HTTP/1.1 200 OK, trả về user info.
```
- Log: status 200, payload chứa user iss/sub từ token.

---

## 2. Kiểm thử vượt rate limit
```
for i in {1..15}; do
  curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8000/api/public
done
# Kỳ vọng: 10 lần đầu 200, sau đó 429 Too Many Requests.
```
- Kibana hiển thị nhiều bản ghi 200 và 429, thể hiện cơ chế throttling hoạt động.

---

## 3. Kiểm thử request lỗi

### a. Truy cập sai path
```
curl -i http://localhost:8000/api/unknown
# Kỳ vọng: HTTP/1.1 404 Not Found
```
- Log: status 404, path `/api/unknown`.

### b. Truy cập với JWT hết hạn
```
curl -i -H "Authorization: Bearer <expired_jwt>" http://localhost:8000/api/secure
# Kỳ vọng: HTTP/1.1 401 Unauthorized, thông báo token expired.
```
- Log: hiển thị lỗi expired, status 401.

---

## 4. Kiểm thử phân tích log nâng cao

### a. Request từ nhiều IP khác nhau
- Gửi request từ máy khách khác trong mạng LAN.
- Xem Kibana → lọc theo `client_ip`.  
→ Phân tích được nguồn request (monitoring theo IP).

### b. Request gửi kèm user-agent đặc biệt
```
curl -i -H "User-Agent: kong-demo-test" http://localhost:8000/api/public
```
- Kiểm tra log trường `user_agent` chứa giá trị `kong-demo-test`.

---

## 5. Kiểm thử brute-force/bot
```
for i in {1..15}; do
  curl -i http://localhost:8000/api/secure
done
```
- Kibana: log nhiều request 401 từ cùng IP.
- Dashboard: biểu đồ error rate tăng (phân tích tấn công bot/brute force).

---

## 6. Kiểm thử các phương thức RESTful
```
curl -X POST http://localhost:8000/api/public -d '{"data":"test"}'
curl -X PUT http://localhost:8000/api/public -d '{"data":"update"}'
curl -X DELETE http://localhost:8000/api/public
```
- Log: method POST/PUT/DELETE khác nhau, phản ánh chính xác hành động người dùng.

---

## 7. Hướng dẫn kiểm tra log trên Kibana

1. Truy cập [http://localhost:5601](http://localhost:5601)
2. Vào **Discover** → **Create index pattern**:  
   - Nhập `kong-logs-*`
   - Chọn `@timestamp`
3. Sử dụng filter hoặc search bar:
   - `status:200`
   - `status:[400 TO 499]`
   - `client_ip: "172.*"`
4. Xem biểu đồ request theo thời gian, top endpoint, top status code.
5. Dữ liệu log sẽ hiển thị chi tiết theo từng request từ Kong.

---

## 8. Checklist xác nhận hệ thống hoạt động hoàn chỉnh

| Hạng mục | Kỳ vọng |
|-----------|----------|
| Kong gateway | Trả về phản hồi đầy đủ qua 8000/8001 |
| JWT plugin | Xác thực token đúng, reject khi expired |
| Rate limit | Tự động chặn khi vượt ngưỡng 10 request/minute |
| Logging | Logstash nhận UDP (12201), Elasticsearch tạo index `kong-logs-*` |
| Kibana | Hiển thị log JSON realtime |
| Error test | Thống kê đủ 200, 401, 404, 429 trên dashboard |
| Dashboard | Có biểu đồ request/time, status code, IP, latency |

---

## 🎯 Tổng kết

Sau khi chạy toàn bộ kịch bản:
- Xác minh dịch vụ xuyên suốt từ client ➜ Kong ➜ backend ➜ Logstash ➜ Elasticsearch ➜ Kibana.  
- Thống kê dữ liệu thật để phục vụ báo cáo.  
- Các log được tự động index và truy vấn theo trường thời gian (`@timestamp`), hỗ trợ minh chứng tính **traceability & observability** cho hệ thống API Gateway Security Service.


***
