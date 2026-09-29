# ═══════════════════════════════════════════════════════════════════
# CP2 — Containerization
#
# Dưới đây là Dockerfile "chạy được nhưng chưa production": một stage,
# chạy bằng user root, không có health check, base image nặng.
#
# NHIỆM VỤ: sửa file này thành bản production-ready. Yêu cầu:
#   [ ] Multi-stage build: stage `builder` cài dependency, stage runtime
#       chỉ copy kết quả sang → image nhỏ hơn, không mang theo compiler.
#       Cú pháp: `FROM python:3.11-slim AS builder`
#   [ ] Base image slim (hoặc alpine), không dùng `python:3.11` bản đầy đủ
#   [ ] COPY requirements.txt và pip install TRƯỚC khi COPY source code
#       (Docker cache theo layer: sửa 1 dòng code không phải cài lại thư viện)
#   [ ] Tạo user thường và chuyển sang bằng lệnh `USER` — container chạy
#       root nghĩa là ai thoát được khỏi app cũng thành root trên host
#   [ ] Có `HEALTHCHECK` gọi vào endpoint /health
#   [ ] Đọc cổng từ biến môi trường PORT (cloud tự gán cổng, không cố định 8000)
#
# Kiểm tra:  pytest tests/test_cp2.py -v
# Build thử: docker build -t day12-agent:prod .
#            docker images day12-agent:prod     # xem dung lượng
# ═══════════════════════════════════════════════════════════════════

# Bắt đầu stage builder từ Python 3.11 bản slim và đặt tên stage là "builder".
# Stage này chỉ dùng để cài dependency, không phải image chạy cuối cùng.
FROM python:3.11-slim AS builder

# Đặt /build làm thư mục làm việc cho các lệnh tiếp theo trong stage builder.
WORKDIR /build

# Chỉ copy requirements.txt trước để Docker có thể tái sử dụng cache dependency
# khi mã nguồn thay đổi nhưng danh sách thư viện không đổi.
COPY requirements.txt .

# Cài các thư viện vào /install để có thể copy riêng sang stage runtime.
# --no-cache-dir không giữ cache tải xuống của pip, giúp image nhỏ hơn.
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt


# Bắt đầu stage chạy thật từ một image Python slim mới, sạch và gọn.
FROM python:3.11-slim AS runtime

# Ngăn Python tạo file bytecode .pyc và thư mục __pycache__ trong container.
ENV PYTHONDONTWRITEBYTECODE=1

# Buộc Python xuất log ngay lập tức, không giữ log tạm trong bộ đệm.
ENV PYTHONUNBUFFERED=1

# Đặt /app làm thư mục làm việc của ứng dụng trong container.
WORKDIR /app

# Copy các dependency đã cài từ stage builder vào nơi Python runtime tìm thư viện.
# Công cụ và dữ liệu tạm của builder không bị mang sang image cuối.
COPY --from=builder /install /usr/local

# Tạo một nhóm hệ thống tên appgroup dành cho ứng dụng.
RUN groupadd --system appgroup

# Tạo user hệ thống appuser, gán vào appgroup và tạo thư mục home cho user này.
RUN useradd --system --gid appgroup --create-home appuser

# Copy package app vào /app/app và giao quyền sở hữu cho user thường appuser.
COPY --chown=appuser:appgroup app ./app

# Copy package utils vào /app/utils và giao quyền sở hữu cho appuser.
COPY --chown=appuser:appgroup utils ./utils

# Từ đây, các lệnh chạy container sử dụng appuser thay vì tài khoản root.
USER appuser

# Ghi chú rằng ứng dụng dự kiến lắng nghe cổng 8000; lệnh này không tự mở cổng.
EXPOSE 8000

# Cứ 30 giây kiểm tra endpoint /health, chờ tối đa 5 giây cho mỗi lần kiểm tra.
# start-period cho ứng dụng 10 giây khởi động; 3 lần lỗi liên tiếp sẽ bị coi là unhealthy.
# Python đọc PORT từ môi trường, mặc định là 8000, rồi gửi HTTP request tới /health.
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 CMD python -c "import os, urllib.request; urllib.request.urlopen('http://127.0.0.1:' + os.getenv('PORT', '8000') + '/health', timeout=3)" || exit 1

# Khởi động Uvicorn và cho phép nhận kết nối từ bên ngoài container qua 0.0.0.0.
# Cổng lấy từ biến PORT; nếu PORT chưa được đặt thì dùng cổng 8000.
# exec giúp Uvicorn nhận trực tiếp các tín hiệu dừng của Docker để tắt an toàn.
CMD ["sh", "-c", "exec uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}"]
