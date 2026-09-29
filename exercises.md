# Phiếu Phản Ánh — K4 Level 3B, Ngày 12

> **Bài làm cá nhân.** Trả lời bằng lời của chính bạn, dựa trên những gì bạn
> quan sát được khi chạy code — không sao chép đáp án của người khác.
>
> Cách trả lời: thay dòng `> *Câu trả lời của bạn*` bằng câu trả lời.
> `grade.py` đếm số câu đã trả lời (15 điểm cho 10 câu).
>
> Họ và tên: Bùi Việt Anh
>
> Mã học viên: 2A202602611

---

### Câu 1 — Fail fast (CP1)

Trong `Settings`, `agent_api_key` không có giá trị mặc định nên app chết ngay
khi khởi động nếu thiếu biến môi trường. Hãy mô tả một tình huống cụ thể mà
việc "chết sớm" này cứu bạn, so với việc để mặc định `"changeme"`.

> *"changeme" sẽ khiến cho biến agent_api_key được khai báo, và hệ thống sẽ chỉ dừng khi gọi đến agent_api_key (vì api không chuẩn).*

> *để trống thì agent_api_key không được khai báo, dev sẽ biết luôn, đỡ phải trace bug*

---

### Câu 2 — Log cho máy đọc (CP1)

Chạy service và gọi `/ask` vài lần. Dán một dòng log JSON bạn thu được, rồi
nêu **hai** việc bạn làm được với dòng log đó mà `print("đã trả lời xong")`
không làm được.

> `{"event": "ask_completed", "level": "info", "timestamp": "2026-09-29T04:26:51.404542+00:00", "user_id": "sv01", "tokens_in": 8, "tokens_out": 12, "cost_usd": 0.0001}`
>
> - Lọc các lần gọi theo `user_id`, `timestamp`, `event`. 
>
> - Tính chi phí cho một request

---

### Câu 3 — Kích thước image (CP2)

Build cả hai phiên bản và ghi lại số đo thật:

```bash
docker build -f <Dockerfile-1-stage> -t agent:single .
docker build -t agent:multi .
docker images | grep agent
```

| Bản | Dung lượng |
|-----|-----------|
| 1 stage (bản đầu) | ... MB |
| Multi-stage | ... MB |

Giải thích: phần dung lượng chênh lệch đó là những gì?

> Tôi chưa cài được Docker nên chưa thể đo chính xác dung lượng của hai image. Bản multi-stage dự kiến nhỏ hơn vì image chạy thật chỉ giữ Python, thư viện cần thiết và mã nguồn. Công cụ cài đặt, cache và file tạm chỉ dùng lúc build được giữ ở stage `builder`, không được đưa sang image chạy thật.

---

### Câu 4 — Thứ tự lệnh trong Dockerfile (CP2)

Sửa một ký tự trong `app/main.py` rồi build lại. Với Dockerfile của bạn, những
layer nào được dùng lại từ cache, layer nào phải chạy lại? Nếu bạn đặt
`COPY . .` lên trước `RUN pip install` thì kết quả khác thế nào?

> Khi chỉ sửa một ký tự trong app/main.py, các layer trước bước COPY app ./app vẫn được dùng lại từ cache, gồm base image, WORKDIR, sao chép requirements.txt và cài thư viện bằng pip. Bước COPY app ./app phải chạy lại vì mã nguồn đã thay đổi; các layer nằm sau nó cũng phải chạy lại.
>
> Nếu đặt COPY . . trước RUN pip install, mỗi lần sửa bất kỳ file nào trong dự án, layer COPY sẽ thay đổi nên bước pip install phía sau cũng phải chạy lại. Việc này làm thời gian build lâu hơn dù requirements.txt không thay đổi

---

### Câu 5 — Vì sao không chạy bằng root (CP2)

Container mặc định chạy bằng root. Mô tả chuỗi sự kiện dẫn từ "một lỗ hổng
trong code Python của bạn" tới "kẻ tấn công có quyền cao trên máy host", và
lệnh `USER` cắt đứt chuỗi đó ở chỗ nào.

> Kẻ tấn công có thể lợi dụng lỗ hổng trong code Python để chạy lệnh bên trong container. Nếu ứng dụng chạy bằng `root`, các lệnh đó cũng có quyền root. Khi container còn có lỗi cấu hình hoặc lỗ hổng cho phép thoát ra ngoài, kẻ tấn công có thể chiếm quyền cao trên máy host. Lệnh `USER appuser` làm ứng dụng chạy bằng tài khoản thường, nên nếu code bị khai thác thì quyền của kẻ tấn công vẫn bị giới hạn. Lệnh này không sửa lỗ hổng Python nhưng làm giảm thiệt hại.

---

### Câu 6 — Cửa sổ trượt (CP3)

Rate limit của bạn dùng sliding window 60 giây. Nếu thay bằng cách đếm theo
phút đồng hồ (reset lúc giây 00), một người dùng có thể gửi tối đa bao nhiêu
request trong 2 giây liên tiếp khi hạn mức là 10/phút? Giải thích cách đạt được
con số đó.

> Người dùng có thể gửi tối đa 20 request trong 2 giây: gửi 10 request ngay trước giây 00, ví dụ lúc `10:00:59`, rồi gửi thêm 10 request ngay sau khi bộ đếm sang phút mới và được reset, ví dụ lúc `10:01:01`. Sliding window tránh được việc này vì tại `10:01:01`, nó vẫn tính cả các request nằm trong 60 giây gần nhất.

---

### Câu 7 — Rate limit và cost guard (CP3)

Hai cơ chế này khác nhau ở điểm nào? Cho một tình huống mà rate limit cho qua
nhưng cost guard phải chặn, và một tình huống ngược lại.

> Rate limit giới hạn số request trong một khoảng thời gian ngắn, còn cost guard giới hạn tổng số tiền một người dùng được tiêu trong tháng.
>
> Rate limit có thể cho qua khi người dùng gửi ít request, nhưng mỗi request dùng rất nhiều token khiến ngân sách tháng đã hết; lúc đó cost guard phải chặn. Ngược lại, người dùng có thể chưa tiêu hết ngân sách nhưng gửi quá 10 request trong 60 giây; cost guard vẫn cho phép nhưng rate limit phải chặn.

---

### Câu 8 — /health khác /ready (CP4)

Nếu gộp hai endpoint làm một và cho nó kiểm tra Redis, chuyện gì xảy ra với cụm
3 container khi Redis mất kết nối 30 giây? Trả lời theo đúng thứ tự sự kiện.

> Khi Redis mất kết nối, endpoint đã gộp sẽ trả lỗi. Hệ thống coi cả 3 container là không khỏe và lần lượt khởi động lại chúng. Tuy nhiên, khởi động lại không sửa được Redis nên các container tiếp tục báo lỗi và bị restart lặp lại. Kết quả là cả cụm không phục vụ được request dù bản thân ứng dụng vẫn còn chạy. Tách riêng `/health` giúp hệ thống biết process còn sống, còn `/ready` chỉ tạm ngừng đưa request vào container cho đến khi Redis hoạt động lại.

---

### Câu 9 — Stateless (CP4)

Chạy `docker compose up --scale agent=3` rồi gọi `/ask` nhiều lần với cùng một
`X-User-Id`. Quan sát `history_length` trong response. Nếu lịch sử được lưu
trong một dict Python thay vì Redis, bạn sẽ thấy con số đó thay đổi thế nào?

> Nếu lịch sử nằm trong một `dict` Python, mỗi container sẽ có một bản dữ liệu riêng. Các request có thể được chuyển tới ba container khác nhau nên `history_length` sẽ tăng không đều, có thể lần lượt thấy các giá trị như 0, 0, 2, 0, 2 thay vì tăng liên tục. Khi dùng Redis, cả ba container đọc chung một lịch sử nên `history_length` nhất quán dù request đi vào container nào.

---

### Câu 10 — Deploy thật (CP5)

Ghi lại **một** lỗi bạn gặp khi deploy lên cloud (build fail, health check
timeout, sai REDIS_URL, app không đọc `$PORT`...): thông báo lỗi là gì, bạn
tìm ra nguyên nhân bằng cách nào, và sửa ra sao?

> Internal Server Error -> Chưa tải được Docker, WSL2, chưa setup được Redis local -> pass
