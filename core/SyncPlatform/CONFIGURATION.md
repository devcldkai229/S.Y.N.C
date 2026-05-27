# Sync Platform — Configuration

## Mô hình

| File | Trên Git | Mục đích |
|------|----------|----------|
| `*.json.example` | **Có** | Template cấu trúc, secret rỗng |
| `appsettings.json` | **Không** (gitignore) | Cấu hình local / mặc định |
| `appsettings.Development.json` | **Không** (gitignore) | Override khi `ASPNETCORE_ENVIRONMENT=Development` |
| `configs/appsettings.Shared*.json` | **Không** (gitignore) | JWT + logging dùng chung |

Mỗi dev giữ bản `appsettings*.json` riêng trên máy — **không push** lên remote, tránh xung đột secret giữa các dev.

## Setup sau clone

Từ **root repo**:

```powershell
.\core\SyncPlatform\scripts\setup-appsettings.ps1
```

Script copy `*.json.example` → `*.json` (bỏ qua file đã tồn tại). Dùng `-Force` để ghi đè.

Sau đó điền secret trong:

1. `configs/appsettings.Shared.Development.json` → `Jwt:SecretKey` (≥ 32 ký tự)
2. Mỗi service `appsettings.Development.json` → connection strings, PayOS, Google, SMTP, MinIO, …

## Production

Dùng biến môi trường (`Jwt__SecretKey`, `ConnectionStrings__IamDatabase`, …) hoặc secret store.

## Chạy tất cả service

```powershell
cd core/SyncPlatform
.\scripts\setup-appsettings.ps1
.\scripts\run-all.ps1 -Infra   # lần đầu: Docker Postgres/Mongo/MinIO
.\scripts\run-all.ps1
```

Yêu cầu: **.NET 10 SDK**, Docker (Postgres `:5434`, Mongo `:27017`), `Jwt:SecretKey` trong `configs/appsettings.Shared.Development.json`.

`run-all.ps1` build toàn bộ service trước khi mở cửa sổ — lỗi build hiện ngay terminal chính (không chỉ timeout health check).

## IAM database (lần đầu)

```powershell
cd core/SyncPlatform/src/Services/Iam/Iam.API
dotnet ef database update --project ..\Iam.Infrastructure\Iam.Infrastructure.csproj
```

Khi chạy IAM ở **Development**, seed dev tự chạy **một lần** (bỏ qua nếu đã có user `dev.seed@sync.local`):

| Email | Password | Ghi chú |
|-------|----------|---------|
| `dev.seed@sync.local` | `Sync@12345` | Email đã verify — login ngay |
| `demo@sync.local` | `Sync@12345` | Tài khoản demo thứ hai |

Tắt seed: `DevSeed:Enabled: false` trong `Iam.API/appsettings.Development.json`.
