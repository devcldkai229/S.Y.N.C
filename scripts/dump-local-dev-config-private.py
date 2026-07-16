"""Generate docs/LOCAL_DEV_CONFIG.PRIVATE.md from local config (full secrets)."""
from __future__ import annotations

from datetime import datetime, timezone, timedelta
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "docs" / "LOCAL_DEV_CONFIG.PRIVATE.md"

SECTIONS: list[tuple[str, str, str]] = [
    ("UI Web — .env", "ui/web/.env", "env"),
    ("AI agent — .env", "ai/sync-agent-service/.env", "env"),
    ("Flutter — dart_defines.aws.json", "ui/app/dart_defines.aws.json", "json"),
    ("Docker compose — .env.example (no local .env)", "infra/docker/.env.example", "env"),
    ("Gateway — appsettings.json", "core/SyncPlatform/src/Gateway/appsettings.json", "json"),
    (
        "Gateway — appsettings.Development.json",
        "core/SyncPlatform/src/Gateway/appsettings.Development.json",
        "json",
    ),
    ("IAM — appsettings.json", "core/SyncPlatform/src/Services/Iam/Iam.API/appsettings.json", "json"),
    (
        "IAM — appsettings.Development.json",
        "core/SyncPlatform/src/Services/Iam/Iam.API/appsettings.Development.json",
        "json",
    ),
    ("Social — appsettings.json", "core/SyncPlatform/src/Services/Social/Social.API/appsettings.json", "json"),
    (
        "Social — appsettings.Development.json",
        "core/SyncPlatform/src/Services/Social/Social.API/appsettings.Development.json",
        "json",
    ),
    ("Order — appsettings.json", "core/SyncPlatform/src/Services/Order/Order.API/appsettings.json", "json"),
    (
        "Order — appsettings.Development.json",
        "core/SyncPlatform/src/Services/Order/Order.API/appsettings.Development.json",
        "json",
    ),
    ("Payment — appsettings.json", "core/SyncPlatform/src/Services/Payment/Payment.API/appsettings.json", "json"),
    (
        "Marketplace — appsettings.json",
        "core/SyncPlatform/src/Services/Marketplace/Marketplace.API/appsettings.json",
        "json",
    ),
    (
        "Marketplace — appsettings.Development.json",
        "core/SyncPlatform/src/Services/Marketplace/Marketplace.API/appsettings.Development.json",
        "json",
    ),
    (
        "Nutrition — appsettings.json",
        "core/SyncPlatform/src/Services/Nutrition/Nutrition.API/appsettings.json",
        "json",
    ),
    (
        "Nutrition — appsettings.Development.json",
        "core/SyncPlatform/src/Services/Nutrition/Nutrition.API/appsettings.Development.json",
        "json",
    ),
    (
        "Exercise — appsettings.json",
        "core/SyncPlatform/src/Services/Exercise/Exercise.API/appsettings.json",
        "json",
    ),
    (
        "Exercise — appsettings.Development.json",
        "core/SyncPlatform/src/Services/Exercise/Exercise.API/appsettings.Development.json",
        "json",
    ),
    ("Roadmap — appsettings.json", "core/SyncPlatform/src/Services/Roadmap/Roadmap.API/appsettings.json", "json"),
    (
        "Notification — appsettings.Development.json",
        "core/SyncPlatform/src/Services/Notification/Notification.API/appsettings.Development.json",
        "json",
    ),
]


def slug(title: str) -> str:
    out = []
    for ch in title.lower():
        if ch.isalnum() or ch in "- ":
            out.append("-" if ch == " " else ch)
    s = "".join(out)
    while "--" in s:
        s = s.replace("--", "-")
    return s.strip("-")


def main() -> None:
    now = datetime.now(timezone(timedelta(hours=7))).strftime("%Y-%m-%d %H:%M:%S %z")
    lines: list[str] = [
        "# LOCAL DEV CONFIG (PRIVATE — full secrets)",
        "",
        "> **INTERNAL ONLY.** Snapshot of local config (option B = keep full secrets).",
        "> - Do **NOT** commit this file. `/docs/*` is gitignored; also ignore `LOCAL_DEV_CONFIG.PRIVATE.md`.",
        "> - Share via private channel only (Drive / 1Password / sealed DM).",
        f"> - Generated: {now}",
        "",
        "## Cách dùng cho member",
        "",
        "1. Copy từng block xuống đúng path trong repo (xem **Path** mỗi section).",
        "2. Hoặc chạy `./core/SyncPlatform/scripts/setup-appsettings.ps1` rồi ghi đè bằng nội dung section.",
        "3. Web: `ui/web/.env` → restart `npm run dev`.",
        "4. AI: `ai/sync-agent-service/.env`.",
        "5. Flutter map: `ui/app/dart_defines.aws.json` + `./ui/app/scripts/run-chrome.ps1`.",
        "6. Backend: Shared JWT trong `configs/`, từng service `appsettings*.json`, rồi `./core/SyncPlatform/scripts/run-all.ps1`.",
        "",
        "## Mục lục",
        "",
    ]

    for i, (title, _, _) in enumerate(SECTIONS, 1):
        lines.append(f"{i}. [{title}](#{slug(title)})")
    lines.append("")

    for title, rel, lang in SECTIONS:
        path = ROOT / rel
        lines.extend(
            [
                "---",
                "",
                f"## {title}",
                "",
                f"**Path:** `{rel}`",
                "",
            ]
        )
        if not path.is_file():
            lines.append("_File missing on this machine._")
            lines.append("")
            continue
        content = path.read_text(encoding="utf-8", errors="replace").replace("\r\n", "\n").replace("\r", "\n")
        if not content.endswith("\n"):
            content += "\n"
        lines.append(f"```{lang}")
        lines.append(content.rstrip("\n"))
        lines.append("```")
        lines.append("")

    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text("\n".join(lines), encoding="utf-8")
    print(f"Wrote {OUT} ({OUT.stat().st_size} bytes)")


if __name__ == "__main__":
    main()
