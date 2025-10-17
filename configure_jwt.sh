#!/bin/bash

set -e

# 1. Kích hoạt plugin JWT cho service
echo "=== Kích hoạt plugin JWT cho backend-service ==="
code=$(curl -s -o /dev/null -w "%{http_code}" -X POST http://localhost:8001/services/backend-service/plugins --data "name=jwt")
if [[ $code == 201 ]]; then echo "✔ Kích hoạt JWT thành công."; else echo "✗ Kích hoạt JWT thất bại (HTTP: $code)."; fi

# 2. Tạo consumer
echo "=== Tạo consumer user1 ==="
code=$(curl -s -o /dev/null -w "%{http_code}" -X POST http://localhost:8001/consumers --data "username=user1")
if [[ $code == 201 ]]; then echo "✔ Tạo consumer thành công."; else echo "✗ Tạo consumer thất bại (HTTP: $code)."; fi

# 3. Cấp JWT credential
echo "=== Sinh credential JWT cho user1 ==="
resp=$(curl -s -X POST http://localhost:8001/consumers/user1/jwt)
key=$(echo $resp | grep -o '"key":"[^"]*' | cut -d':' -f2 | tr -d '"')
secret=$(echo $resp | grep -o '"secret":"[^"]*' | cut -d':' -f2 | tr -d '"')
if [[ -n "$key" && -n "$secret" ]]; then
  echo "✔ Nhận key: $key"
  echo "✔ Nhận secret: $secret"
  echo "→ Hãy copy key vào trường iss và secret lên JWT.io để sinh token"
else
  echo "✗ Sinh credential thất bại. Thông tin trả về:"
  echo "$resp"
fi

echo
echo "=== Test Request: Dán Authorization Bearer <JWT> vào /api/secure ==="
echo "Ví dụ sử dụng curl:"
echo 'curl -i -H "Authorization: Bearer <jwt_token>" http://localhost:8000/api/secure'
