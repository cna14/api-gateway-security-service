#!/bin/bash
set -e

echo "=== BẮT ĐẦU CẤU HÌNH KONG API GATEWAY ==="

# 1. Tạo Service cho backend
echo "=== Đăng ký Service: backend-service ==="
if curl -s http://localhost:8001/services/backend-service | grep -q "backend-service"; then
  echo "✔ Service backend-service đã tồn tại."
else
  curl -i -X POST http://localhost:8001/services \
    --data "name=backend-service" \
    --data "url=http://backend:3000"
  echo "✔ Service backend-service tạo thành công."
fi

# 2. Tạo Route cho /api
echo "=== Tạo Route: /api ==="
if curl -s http://localhost:8001/services/backend-service/routes | grep -q "/api"; then
  echo "✔ Route /api đã tồn tại."
else
  curl -i -X POST http://localhost:8001/services/backend-service/routes \
    --data "paths[]=/api"
  echo "✔ Route /api tạo thành công."
fi

# 3. Kích hoạt plugin rate-limiting
echo "=== Kích hoạt plugin rate-limiting cho backend-service ==="
if ! curl -s http://localhost:8001/services/backend-service/plugins | grep -q "rate-limiting"; then
  curl -i -X POST http://localhost:8001/services/backend-service/plugins \
    --data "name=rate-limiting" \
    --data "config.minute=10" \
    --data "config.policy=local"
  echo "✔ Plugin rate-limiting kích hoạt thành công."
else
  echo "✔ Plugin rate-limiting đã được kích hoạt trước đó."
fi

# 4. Kích hoạt plugin UDP log
echo "=== Kích hoạt plugin UDP-log (đẩy log sang Logstash:12201) ==="
if ! curl -s http://localhost:8001/services/backend-service/plugins | grep -q "udp-log"; then
  curl -i -X POST http://localhost:8001/services/backend-service/plugins \
    --data "name=udp-log" \
    --data "config.host=logstash" \
    --data "config.port=12201"
  echo "✔ Plugin UDP log kích hoạt thành công."
else
  echo "✔ Plugin UDP log đã tồn tại."
fi

# 5. Gọi script configure_jwt.sh để cấu hình JWT
if [ -f "./configure_jwt.sh" ]; then
  echo "=== Gọi configure_jwt.sh để cấu hình JWT ==="
  bash configure_jwt.sh
else
  echo "⚠ Không tìm thấy file configure_jwt.sh — bỏ qua bước cấu hình JWT."
fi

echo "=== KIỂM TRA DANH SÁCH PLUGIN HIỆN TẠI ==="
curl -s http://localhost:8001/services/backend-service/plugins | jq '.data[] | {name, config}'

echo "=== HOÀN TẤT CẤU HÌNH KONG API GATEWAY ==="
