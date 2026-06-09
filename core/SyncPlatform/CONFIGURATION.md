# Sync Platform — Configuration

## Mô hình (an toàn khi `git push`)

| Loại file | Trên Git | Bạn điền secret |
|-----------|----------|-----------------|
| `appsettings.json` | Có — **giá trị rỗng** `""` | Sau pull, hoặc dùng `.local.json` |
| `appsettings.Development.json` | Có — **giá trị rỗng** | Sau pull, hoặc dùng `.local.json` |
| `appsettings.*.local.json` | **Không** (gitignore) | Khuyên dùng cho secret thật |
| `.env` | **Không** (gitignore) | UI / tooling |

**Không cần** đổi tên `*.example.json` — pull xong chỉ việc điền giá trị (hoặc tạo file `.local.json`).

## Setup một lần sau clone

Từ **root repo**:

```powershell
.\scripts\install-git-hooks.ps1
```

Hook `pre-commit` sẽ **chặn commit** nếu `appsettings*.json` có password / API key / connection string không rỗng.

Bạn vẫn có thể `git add .` và `git push` bình thường khi chỉ commit code + file config **để trống secret**.

## Điền secret để chạy local

1. `configs/appsettings.Shared.Development.json` → `Jwt:SecretKey` (≥ 32 ký tự).
2. Mỗi service `appsettings.Development.json` → connection strings, PayOS, Google, SMTP, …

**Khuyến nghị:** tạo `appsettings.Development.local.json` (gitignored) trong từng project:

```json
{
  "ConnectionStrings": {
    "IamDatabase": "Host=localhost;Port=5432;Database=sync_iam;Username=postgres;Password=YOUR_PASSWORD"
  },
  "Jwt": {
    "SecretKey": "your-dev-jwt-secret-at-least-32-characters-long"
  }
}
```

ASP.NET Core tự merge file `.local.json` sau `appsettings.Development.json`.

## Kiểm tra thủ công trước push

```powershell
.\core\SyncPlatform\scripts\validate-committed-appsettings.ps1
```

## Production

Dùng biến môi trường (`Jwt__SecretKey`, `ConnectionStrings__IamDatabase`, …) hoặc secret store — không đưa secret vào JSON trên Git.

## Chạy tất cả service

```powershell
cd core/SyncPlatform
.\scripts\run-all.ps1
```

`run-all.ps1` kiểm tra `Jwt:SecretKey` đã được cấu hình (từ file tracked hoặc `.local.json`).
