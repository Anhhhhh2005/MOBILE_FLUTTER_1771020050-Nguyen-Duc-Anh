# 🐘 Hướng dẫn sử dụng PostgreSQL

## ✅ Bạn đã có PostgreSQL - Tuyệt vời!

PostgreSQL là database tốt hơn SQLite cho production.

---

## 🔧 Cấu hình Connection String

Mở file `appsettings.json` và cập nhật thông tin PostgreSQL của bạn:

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Host=localhost;Port=5432;Database=pcm734database;Username=postgres;Password=YOUR_PASSWORD"
  }
}
```

**Thay đổi**:
- `Host`: Địa chỉ PostgreSQL server (mặc định: `localhost`)
- `Port`: Cổng PostgreSQL (mặc định: `5432`)
- `Database`: `pcm734database` (hoặc tên khác bạn muốn)
- `Username`: Username PostgreSQL của bạn (thường là `postgres`)
- `Password`: **Thay bằng password thật của bạn**

---

## 🚀 Tạo Database

### Bước 1: Update appsettings.json

Sửa password trong connection string thành password PostgreSQL của bạn.

### Bước 2: Chạy lệnh tạo database

**Trong CMD** (nơi `dotnet` command hoạt động):

```cmd
cd d:\Mobile\bai_kiem_tra_nang_cao\Backend

:: Restore packages (bao gồm Npgsql)
dotnet restore

:: Cài EF Core tools
dotnet tool install --global dotnet-ef

:: Restart CMD sau khi cài dotnet-ef!

:: Tạo migration
dotnet ef migrations add InitialCreate

:: Tạo database + seed data
dotnet ef database update

:: Chạy backend
dotnet run
```

---

## 🗄️ PostgreSQL sẽ tạo

Database: `pcm734database` với các bảng:

**Custom tables** (prefix 734):
- `734_Members`
- `734_WalletTransactions`
- `734_Courts`
- `734_Bookings`
- `734_Tournaments`
- `734_TournamentParticipants`
- `734_Matches`
- `734_News`
- `734_Notifications`

**Identity tables** (prefix Asp):
- `AspNetUsers`
- `AspNetRoles`
- `AspNetUserRoles`
- etc.

---

## 🔍 Kiểm tra Database

Bạn có thể dùng:

1. **pgAdmin** (thường đi kèm PostgreSQL)
2. **DBeaver** (free, đa platform)
3. **psql command line**:

```bash
psql -U postgres -d pcm734database

# Xem các bảng
\dt

# Xem data
SELECT * FROM "734_Members";

# Thoát
\q
```

---

## ⚠️ Lưu ý quan trọng

### PostgreSQL case-sensitive với table names

Trong PostgreSQL, table names có dấu ngoặc kép là **case-sensitive**:
- `"734_Members"` ≠ `"734_members"`

EF Core sẽ tự động handle điều này.

### Connection pooling

PostgreSQL có connection pooling tốt hơn SQL Server và SQLite.

---

## 🎯 Tài khoản test

Sau khi seed data, dùng các tài khoản sau:

| Email | Password | Role |
|-------|----------|------|
| admin@pcm.com | Admin@123 | Admin |
| treasurer@pcm.com | Treasurer@123 | Treasurer |
| referee@pcm.com | Referee@123 | Referee |
| member1@pcm.com | Member@123 | Member |

---

## 🔧 Troubleshooting

### Lỗi: "password authentication failed"
→ Kiểm tra lại password trong connection string

### Lỗi: "database does not exist"
→ Chạy `dotnet ef database update` để tạo database

### Lỗi: "could not connect to server"
→ Kiểm tra PostgreSQL service đang chạy:
```powershell
Get-Service postgresql*
```

### Tạo lại database từ đầu
```bash
# Xóa database cũ (trong psql)
DROP DATABASE pcm734database;

# Tạo lại
dotnet ef database update
```
