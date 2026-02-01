# 🎾 Pickleball Club Management - Vợt Thủ Phố Núi

**Sinh viên**: Nguyễn Đức Anh
**MSSV**: 1771020050
**Lớp**: CNTT 17-08

Hệ thống quản lý CLB Pickleball hoàn chỉnh với Backend (ASP.NET Core 8 Web API), Frontend (Flutter Mobile/Web), và Database (PostgreSQL).

---

## 📁 Cấu trúc dự án

```
bai_kiem_tra_nang_cao/
├── Backend/              # ASP.NET Core Web API 8.0
│   ├── Controllers/      # 10 API Controllers (incl. AdminController)
│   ├── Models/           # Entity Models (prefix 734_)
│   ├── Data/             # ApplicationDbContext (PostgreSQL) + Seeder
│   ├── DTOs/             # Data Transfer Objects
│   ├── Hubs/             # SignalR Hub cho Real-time features
│   ├── Services/         # Background Services
│   └── Program.cs        # Config CORS, JWT, Swagger, DI
└── Frontend/             # Flutter Mobile App
    ├── lib/
    │   ├── models/       # Dart models
    │   ├── providers/    # State management (Provider)
    │   ├── screens/      # Màn hình chính (Admin, Booking, Wallet...)
    │   ├── services/     # API Service (Dio) + SignalR Service
    │   └── widgets/      # Reusable widgets & Charts
    └── pubspec.yaml
```

---

## 🛠️ Tech Stack

### Backend
- **Framework**: ASP.NET Core 8 Web API
- **Database**: PostgreSQL (Entity Framework Core Code First)
- **Authentication**: JWT Bearer Tokens
- **Real-time**: SignalR (WebSockets)
- **API Documentation**: Swagger/OpenAPI

### Frontend
- **Framework**: Flutter 3.x (Hỗ trợ Mobile & Web)
- **State Management**: Provider
- **Networking**: Dio (HTTP Client)
- **Real-time**: SignalR Client
- **Charts**: FL Chart (Admin Dashboard)
- **Storage**: Flutter Secure Storage

---

## 🚀 Hướng dẫn cài đặt & Chạy

### 1️⃣ Database (PostgreSQL)
Đảm bảo PostgreSQL đã được cài đặt và đang chạy. Kiểm tra file `Backend/appsettings.json` để cấu hình Connection String nếu cần (mặc định user `postgres`, pass `123456`).

Khi chạy Backend lần đầu, hệ thống sẽ tự động:
1. Tạo Database `Pcm734Database` (nếu chưa có).
2. Tạo các bảng.
3. Seed dữ liệu mẫu (Users, Members, Courts, Tournaments, Wallet Transactions...).

### 2️⃣ Backend API

```cmd
cd d:\Mobile\bai_kiem_tra_nang_cao\Backend

# Restore packages
dotnet restore

# Chạy API (khuyên dùng Development mode để debug)
$env:ASPNETCORE_ENVIRONMENT='Development'
dotnet run
```

✅ API URL: `http://localhost:5000`  
✅ Swagger UI: `http://localhost:5000/swagger`

### 3️⃣ Frontend Flutter

**Cấu hình API URL**:
File `Frontend/lib/services/api_service.dart`:
```dart
static const String baseUrl = 'http://localhost:5000/api';
```

**Chạy App**:

```cmd
cd d:\Mobile\bai_kiem_tra_nang_cao\Frontend

# Lấy dependencies
flutter pub get

# Chạy trên Chrome (Web)
flutter run -d chrome

# Hoặc chạy trên Windows Desktop
flutter run -d windows
```

---

## 👤 Tài khoản Demo

Hệ thống đã có sẵn dữ liệu mẫu. Sử dụng các tài khoản sau để đăng nhập:

| Email | Password | Role | Quyền hạn nổi bật |
|-------|----------|------|-------------------|
| `admin@pcm.com` | `Admin@123` | **Admin** | Truy cập **Admin Dashboard**, quản lý toàn bộ hệ thống |
| `treasurer@pcm.com` | `Treasurer@123` | **Treasurer** | Duyệt nạp tiền, xem **Revenue Chart** |
| `referee@pcm.com` | `Referee@123` | **Referee** | Cập nhật kết quả trận đấu |
| `member1@pcm.com` | `Member@123` | **Member** | Đặt sân, tham gia giải đấu, xem ví cá nhân |

*(Có tổng cộng 17 tài khoản Member từ `member1@pcm.com` đến `member17@pcm.com`)*

---

## 📱 Tính năng Chính

### 💼 Admin Dashboard (MỚI)
- **Tổng quan tài chính**: Xem tổng quỹ CLB, doanh thu tháng này.
- **Biểu đồ doanh thu**: Chart trực quan theo dõi thu/chi 12 tháng gần nhất.
- **Xét duyệt nạp tiền**: Approve/Reject các yêu cầu nạp tiền từ thành viên.
- **Thống kê**: Số lượng thành viên theo hạng (Tier), số booking, giải đấu đang mở.

### 🏆 Giải đấu & Booking
- **Đặt sân**: Lịch trực quan, chọn giờ trống, thanh toán bằng ví.
- **Recurring Booking**: Đặt sân cố định hàng tuần (chỉ dành cho VIP/Diamond).
- **Giải đấu**:
  - Tự động tạo lịch thi đấu (Round Robin / Knockout).
  - Cập nhật tỉ số Real-time.
  - Bảng xếp hạng DUPR.

### 💰 Quản lý Ví (Wallet)
- **Nạp tiền**: Upload ảnh bằng chứng chuyển khoản.
- **Lịch sử**: Xem chi tiết từng giao dịch (Deposit, Payment, Reward, Refund).
- **Hạng thành viên (Tier)**: Tích điểm để lên hạng (Standard -> Silver -> Gold -> Diamond) để nhận ưu đãi giảm giá sân.

### 🔔 Real-time & Tiện ích
- **Thông báo**: Nhận thông báo ngay lập tức khi booking được confirm, nạp tiền thành công, hoặc có lịch thi đấu mới.
- **Auto Cancel**: Booking chưa thanh toán sẽ tự hủy sau 15 phút.
- **Auto Remind**: Gửi email/notification nhắc lịch trước 24h.

---

## 🔧 Xử lý lỗi thường gặp

1. **Lỗi 500 Internal Server Error (Admin Dashboard)**:
   - Nguyên nhân: Lỗi tính toán `Math.Abs` hoặc `Sum` của Entity Framework với Postgres.
   - Fix: Đã được xử lý bằng cách chuyển logic tính toán về Client Evaluation (In-Memory).

2. **Lỗi Connection Refused**:
   - Kiểm tra Backend có đang chạy không (`dotnet run`).
   - Đảm bảo Flutter dùng đúng URL `http://localhost:5000`.

3. **Lỗi CORS**:
   - Backend đã được cấu hình cho phép mọi Origin (bao gồm localhost của Chrome).

---

## 🎓 Sinh viên thực hiện
**MSSV**: xxxxx734  
**Họ tên**: Đỗ Văn Tuyên  
**Lớp**: CNTT 17-08  
**Năm**: 2026

