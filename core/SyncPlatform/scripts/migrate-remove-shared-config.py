"""One-off: merge shared Jwt/AllowedHosts/Logging into per-service appsettings; sync .example files."""
from __future__ import annotations

import json
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]

JWT_BASE: dict[str, Any] = {
    "Issuer": "sync-lifestyle-iam",
    "Audience": "sync-lifestyle-clients",
    "SecretKey": "",
    "AccessTokenExpiryMinutes": 15,
    "RefreshTokenExpiryDays": 7,
}

JWT_DEV: dict[str, Any] = {
    "Issuer": "sync-lifestyle-iam-dev",
    "Audience": "sync-lifestyle-clients-dev",
    "SecretKey": "uANeK_nCAd:N$p2_<&C5?V|#5HDX4vMfIe1)lOf^{_{",
    "AccessTokenExpiryMinutes": 60,
    "RefreshTokenExpiryDays": 30,
}

LOGGING_BASE: dict[str, Any] = {
    "LogLevel": {
        "Default": "Warning",
        "Microsoft.AspNetCore": "Warning",
    }
}

LOGGING_DEV: dict[str, Any] = {
    "LogLevel": {
        "Default": "Debug",
        "Microsoft.AspNetCore": "Information",
    }
}

# Per-service Development overrides (merged on top of JWT_DEV + LOGGING_DEV)
DEV_OVERRIDES: dict[str, dict[str, Any]] = {
    "Gateway": {
        "Logging": {
            "LogLevel": {
                "Default": "Debug",
                "Microsoft.AspNetCore": "Information",
                "Yarp": "Warning",
            }
        },
    },
    "Iam.API": {
        "Logging": {
            "LogLevel": {
                "Default": "Debug",
                "Microsoft.AspNetCore": "Information",
                "Microsoft.EntityFrameworkCore.Database.Command": "Warning",
            }
        },
    },
    "Social.API": {
        "Logging": {
            "LogLevel": {
                "Default": "Information",
                "Microsoft.AspNetCore": "Information",
                "Microsoft.AspNetCore.Hosting.Diagnostics": "Warning",
                "Microsoft.Extensions.Http": "Warning",
            }
        },
    },
    "Order.API": {
        "Logging": {
            "LogLevel": {
                "Default": "Debug",
                "Microsoft.AspNetCore": "Information",
                "Microsoft.EntityFrameworkCore.Database.Command": "Information",
            }
        },
    },
    "Payment.API": {
        "Logging": {
            "LogLevel": {
                "Default": "Debug",
                "Microsoft.AspNetCore": "Information",
                "Microsoft.EntityFrameworkCore.Database.Command": "Information",
            }
        },
    },
    "Marketplace.API": {
        "Logging": {
            "LogLevel": {
                "Default": "Information",
                "Microsoft.AspNetCore": "Warning",
            }
        },
    },
    "Nutrition.API": {
        "Logging": {
            "LogLevel": {
                "Default": "Information",
                "Microsoft.AspNetCore": "Warning",
            }
        },
    },
    "Exercise.API": {},
    "Roadmap.API": {
        "Logging": {
            "LogLevel": {
                "Default": "Debug",
                "Microsoft.AspNetCore": "Information",
            }
        },
    },
    "Notification.API": {
        "Logging": {
            "LogLevel": {
                "Default": "Debug",
                "Microsoft.AspNetCore": "Information",
            }
        },
    },
}

SERVICES: list[tuple[str, Path]] = [
    ("Gateway", ROOT / "src" / "Gateway"),
    ("Iam.API", ROOT / "src" / "Services" / "Iam" / "Iam.API"),
    ("Social.API", ROOT / "src" / "Services" / "Social" / "Social.API"),
    ("Order.API", ROOT / "src" / "Services" / "Order" / "Order.API"),
    ("Payment.API", ROOT / "src" / "Services" / "Payment" / "Payment.API"),
    ("Marketplace.API", ROOT / "src" / "Services" / "Marketplace" / "Marketplace.API"),
    ("Nutrition.API", ROOT / "src" / "Services" / "Nutrition" / "Nutrition.API"),
    ("Exercise.API", ROOT / "src" / "Services" / "Exercise" / "Exercise.API"),
    ("Roadmap.API", ROOT / "src" / "Services" / "Roadmap" / "Roadmap.API"),
    ("Notification.API", ROOT / "src" / "Services" / "Notification" / "Notification.API"),
]


def deep_merge(base: dict[str, Any], override: dict[str, Any]) -> dict[str, Any]:
    out = dict(base)
    for k, v in override.items():
        if k in out and isinstance(out[k], dict) and isinstance(v, dict):
            out[k] = deep_merge(out[k], v)
        else:
            out[k] = v
    return out


def load_json(path: Path) -> dict[str, Any]:
    if not path.is_file():
        return {}
    return json.loads(path.read_text(encoding="utf-8-sig"))


def write_json(path: Path, data: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    text = json.dumps(data, indent=2, ensure_ascii=False) + "\n"
    path.write_text(text, encoding="utf-8")
    print(f"  wrote {path.relative_to(ROOT)}")


def strip_meta_keys(data: dict[str, Any]) -> dict[str, Any]:
    return {k: v for k, v in data.items() if not k.startswith("_")}


def apply_base(service: str, existing: dict[str, Any], is_example: bool) -> dict[str, Any]:
    data = dict(existing)
    if "_comment" in data and "_readme" not in data:
        data["_readme"] = data.pop("_comment")
    data.pop("_comment", None)

    if "$schema" not in data:
        data = {"$schema": "https://json.schemastore.org/appsettings.json", **data}

    if is_example and "_readme" not in data:
        data["_readme"] = "Copy to appsettings.json (gitignored) via setup-appsettings.ps1."

    # Standard base keys (don't overwrite service-specific Logging keys entirely)
    data["AllowedHosts"] = "*"
    if "Logging" not in data:
        data["Logging"] = dict(LOGGING_BASE)
    else:
        data["Logging"] = deep_merge(LOGGING_BASE, data["Logging"])
    data["Jwt"] = dict(JWT_BASE)

    # Gateway-specific base logging
    if service == "Gateway":
        data["Logging"] = deep_merge(
            data["Logging"],
            {"LogLevel": {"Yarp": "Warning"}},
        )

    # IAM keeps EF warning in base
    if service == "Iam.API":
        data["Logging"] = deep_merge(
            data["Logging"],
            {"LogLevel": {"Microsoft.EntityFrameworkCore.Database.Command": "Warning"}},
        )

    return data


def apply_dev(service: str, existing: dict[str, Any]) -> dict[str, Any]:
    base_dev = {
        "$schema": "https://json.schemastore.org/appsettings.json",
        "Logging": dict(LOGGING_DEV),
        "Jwt": dict(JWT_DEV),
    }
    overrides = DEV_OVERRIDES.get(service, {})
    merged = deep_merge(base_dev, strip_meta_keys(existing))
    merged = deep_merge(merged, overrides)
    merged["Jwt"] = dict(JWT_DEV)
    if "Logging" in overrides:
        merged["Logging"] = deep_merge(dict(LOGGING_DEV), overrides["Logging"])
    return merged


def process_pair(service: str, dir_path: Path) -> None:
    print(f"\n[{service}]")
    base_path = dir_path / "appsettings.json"
    dev_path = dir_path / "appsettings.Development.json"
    example_base = dir_path / "appsettings.json.example"
    example_dev = dir_path / "appsettings.Development.json.example"

    # Source: prefer local json, else example, else empty
    existing_base = load_json(base_path) or load_json(example_base)
    existing_dev = load_json(dev_path) or load_json(example_dev)

    # Notification: no base file — seed from dev
    if service == "Notification.API" and not existing_base:
        existing_base = dict(existing_dev)

    new_base = apply_base(service, existing_base, is_example=False)
    new_dev = apply_dev(service, existing_dev)

    write_json(base_path, new_base)
    write_json(dev_path, new_dev)

    example_base_data = apply_base(service, strip_meta_keys(new_base), is_example=True)
    # Examples use empty Jwt secret
    example_base_data["Jwt"] = dict(JWT_BASE)
    write_json(example_base, example_base_data)

    example_dev_data = apply_dev(service, strip_meta_keys(new_dev))
    example_dev_data["Jwt"] = dict(JWT_DEV)
    if "_readme" not in example_dev_data:
        example_dev_data = {
            "$schema": example_dev_data.pop("$schema", "https://json.schemastore.org/appsettings.json"),
            "_readme": "Copy to appsettings.Development.json (gitignored) via setup-appsettings.ps1.",
            **example_dev_data,
        }
    write_json(example_dev, example_dev_data)


def main() -> None:
    for service, path in SERVICES:
        process_pair(service, path)
    print("\nDone.")


if __name__ == "__main__":
    main()
