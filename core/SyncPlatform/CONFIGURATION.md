# Sync Platform — Configuration

## Mô hình

| File | Trên Git | Mục đích |
|------|----------|----------|
| `*.example.json` | **Có** | Template cấu trúc, secret rỗng |
| `appsettings.json` | **Không** (gitignore) | Cấu hình local / mặc định |
| `appsettings.Development.json` | **Không** (gitignore) | Override khi `ASPNETCORE_ENVIRONMENT=Development` |
| `configs/appsettings.Shared*.json` | **Không** (gitignore) | JWT + logging dùng chung |

Mỗi dev giữ bản `appsettings*.json` riêng trên máy — **không push** lên remote, tránh xung đột secret giữa các dev.

## Setup sau clone

Từ **root repo**:

```powershell
.\core\SyncPlatform\scripts\setup-appsettings.ps1
```

Script copy `*.example.json` → `*.json` (bỏ qua file đã tồn tại). Dùng `-Force` để ghi đè.

Sau đó điền secret trong:

1. `configs/appsettings.Shared.Development.json` → `Jwt:SecretKey` (≥ 32 ký tự)
2. Mỗi service `appsettings.Development.json` → connection strings, PayOS, Google, SMTP, MinIO, …

## Production

Dùng biến môi trường (`Jwt__SecretKey`, `ConnectionStrings__IamDatabase`, …) hoặc secret store.

## Chạy tất cả service

```powershell
cd core/SyncPlatform
.\scripts\run-all.ps1 -Infra   # lần đầu: Docker Postgres/Mongo/MinIO
.\scripts\run-all.ps1
```

`run-all.ps1` kiểm tra `Jwt:SecretKey` trong `configs/appsettings.Shared.Development.json`.
