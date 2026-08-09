"""Event consumer — proactive AI interventions.

Backend chọn theo config:
- AI_SQS_QUEUE_URL set  → SQS long-poll (boto3) — dùng trên AWS.
- ngược lại             → RabbitMQ (AMQP_URL) hoặc stub — dùng local/dev.
"""
from __future__ import annotations

import asyncio
import json
from typing import Any

from app.integrations import signalr
from app.logging_setup import get_logger
from app.tools.context import ToolRunContext
from app.tools.local import detect_burnout

_log = get_logger("ai.events")

SUBSCRIBED_EVENTS = (
    "OrderPlacedEvent",
    "OrderCompletedEvent",
    "OrderStatusChangedEvent",
    "WorkoutCompletedEvent",
    "WorkoutSkippedEvent",
    "MealLoggedEvent",
)


async def handle_event(event_type: str, payload: dict[str, Any]) -> None:
    user_id = str(payload.get("UserId") or payload.get("userId") or "")
    if not user_id:
        return

    ctx = ToolRunContext(user_id=user_id, state={})

    if event_type == "WorkoutSkippedEvent":
        await signalr.push_proactive_message(
            user_id,
            title="SYNC AI",
            body="Bạn bỏ lỡ buổi tập hôm nay — mai mình điều chỉnh nhẹ nhàng nhé?",
            deep_link="sync://roadmap/today",
        )
    elif event_type == "OrderCompletedEvent":
        await signalr.push_proactive_message(
            user_id,
            title="Đơn hàng đã giao",
            body="Nhớ log bữa ăn để theo dõi macro chính xác nhé!",
            deep_link="sync://nutrition/log",
        )
    elif event_type == "MealLoggedEvent":
        burnout = await detect_burnout(ctx)
        if float(burnout.get("burnoutRiskScore") or 0) > 0.65:
            await signalr.push_proactive_message(
                user_id,
                title="Nghỉ ngơi nhé",
                body="Mình thấy bạn hơi căng — cân nhắc giảm cường độ tập.",
                deep_link="sync://coach",
            )
    elif event_type in ("OrderPlacedEvent", "OrderStatusChangedEvent"):
        _log.info("event_ignored_light", extra={"type": event_type, "user_id": user_id})


def _parse_event(raw_body: str, fallback_type: str | None = None) -> tuple[str, dict[str, Any]]:
    body = json.loads(raw_body)
    event_type = body.get("eventType") or body.get("EventType") or fallback_type
    return event_type, body


async def _on_message(message: Any) -> None:
    try:
        event_type, body = _parse_event(message.body.decode(), message.routing_key)
        await handle_event(event_type, body)
        await message.ack()
    except Exception:
        _log.exception("event_handler_error")
        await message.reject(requeue=False)


async def _run_sqs_consumer(queue_url: str) -> None:
    """Long-poll SQS. Message lỗi không bị xóa → SQS redrive sang DLQ."""
    import boto3

    from app.config import get_settings

    settings = get_settings()
    client = boto3.client("sqs", region_name=settings.aws_region)
    _log.info("sqs_consumer_started", extra={"queue_url": queue_url})

    while True:
        try:
            resp = await asyncio.to_thread(
                client.receive_message,
                QueueUrl=queue_url,
                MaxNumberOfMessages=settings.sqs_max_messages,
                WaitTimeSeconds=settings.sqs_wait_time_seconds,
            )
        except Exception:
            _log.exception("sqs_receive_error")
            await asyncio.sleep(5)
            continue

        for msg in resp.get("Messages", []):
            try:
                event_type, payload = _parse_event(msg["Body"])
                await handle_event(event_type, payload)
                await asyncio.to_thread(
                    client.delete_message,
                    QueueUrl=queue_url,
                    ReceiptHandle=msg["ReceiptHandle"],
                )
            except Exception:
                # Không xóa → sau maxReceiveCount lần, SQS chuyển message sang DLQ.
                _log.exception("event_handler_error")


async def _run_rabbitmq_consumer(amqp_url: str) -> None:
    try:
        import aio_pika

        connection = await aio_pika.connect_robust(amqp_url)
        channel = await connection.channel()
        queue = await channel.declare_queue("sync.ai.interventions", durable=True)
        await queue.consume(_on_message)
        _log.info("rabbitmq_consumer_started", extra={"queue": "sync.ai.interventions"})
        await asyncio.Future()
    except Exception:
        _log.warning("rabbitmq_unavailable_stub_mode")
        while True:
            await asyncio.sleep(3600)


async def run_consumer(amqp_url: str | None = None) -> None:
    """Chọn backend: SQS (AWS) nếu có AI_SQS_QUEUE_URL, ngược lại RabbitMQ/stub."""
    from app.config import get_settings

    settings = get_settings()
    if settings.ai_sqs_queue_url:
        await _run_sqs_consumer(settings.ai_sqs_queue_url)
    else:
        await _run_rabbitmq_consumer(amqp_url or settings.amqp_url)


if __name__ == "__main__":
    asyncio.run(run_consumer())
