"""Đẩy tin nhắn/kết quả async về client qua SignalR Hubs sẵn có của .NET.

Các service .NET đã expose Hub (NotificationHub, NutritionHub, TrackingHub).
Cách đơn giản & nhất quán nhất cho AI: gọi REST nội bộ tới Notification service
để nó phát realtime qua hub (AI không cần giữ kết nối hub trực tiếp).
Khi cần độ trễ thấp hơn, có thể dùng SignalR client (gửi qua hub endpoint).
"""
from __future__ import annotations

from typing import Any

from app.config import get_settings
from app.tools import dotnet


async def push_proactive_message(user_id: str, title: str, body: str,
                                 deep_link: str | None = None) -> dict[str, Any]:
    """Gửi 1 tin nhắn chủ động (AI intervention) -> Notification -> SignalR -> client."""
    payload = {
        "type": "AiIntervention",       # NotificationType.AiIntervention
        "channel": "InApp",             # NotificationChannel.InApp
        "priority": "Normal",
        "title": title,
        "body": body,
        "deepLink": deep_link,
        "allowAiGenerated": True,
    }
    return await dotnet.send_notification(user_id, payload)


async def push_async_result(user_id: str, kind: str, data: dict[str, Any]) -> dict[str, Any]:
    """Báo kết quả tác vụ nền (vd replan xong) về client."""
    get_settings()  # giữ chỗ cho cấu hình hub trực tiếp nếu cần
    return await push_proactive_message(
        user_id,
        title="SYNC AI",
        body=f"Đã hoàn tất: {kind}",
        deep_link=data.get("deepLink"),
    )
