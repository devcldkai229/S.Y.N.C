"""
Robust RabbitMQ publisher for agent tool commands.

Declares a durable topic exchange and binds the workout_commands queue per .cursorrules.
"""

from __future__ import annotations

import asyncio
import json

import structlog
from aio_pika import DeliveryMode, ExchangeType, Message, connect_robust
from aio_pika.abc import AbstractChannel, AbstractExchange, AbstractRobustConnection

from sync_agent.core.config import Settings
from sync_agent.core.exceptions import RabbitMQPublishError
from sync_agent.domain.schemas.messaging.agent_command import AgentCommandMessage

logger = structlog.get_logger(__name__)


class RabbitMQCommandPublisher:
    def __init__(self, *, settings: Settings) -> None:
        self._settings = settings
        self._connection: AbstractRobustConnection | None = None
        self._channel: AbstractChannel | None = None
        self._exchange: AbstractExchange | None = None
        self._connect_lock = asyncio.Lock()

    async def _ensure_connected(self) -> AbstractExchange:
        if self._exchange is not None:
            return self._exchange

        async with self._connect_lock:
            if self._exchange is not None:
                return self._exchange

            url = self._settings.rabbitmq_url.strip()
            if not url:
                raise RabbitMQPublishError("SYNC_RABBITMQ_URL is not configured")

            try:
                self._connection = await connect_robust(url)
                self._channel = await self._connection.channel()
                await self._channel.set_qos(prefetch_count=self._settings.rabbitmq_prefetch_count)

                exchange = await self._channel.declare_exchange(
                    self._settings.rabbitmq_exchange,
                    ExchangeType.TOPIC,
                    durable=True,
                )

                queue = await self._channel.declare_queue(
                    self._settings.rabbitmq_workout_queue,
                    durable=True,
                )
                await queue.bind(exchange, routing_key="workout.#")
                await queue.bind(exchange, routing_key="nutrition.#")
                await queue.bind(exchange, routing_key="agent.#")

                self._exchange = exchange
                logger.info(
                    "rabbitmq.connected",
                    exchange=self._settings.rabbitmq_exchange,
                    queue=self._settings.rabbitmq_workout_queue,
                )
                return exchange
            except Exception as exc:
                raise RabbitMQPublishError(f"RabbitMQ connection failed: {exc}") from exc

    async def publish(self, message: AgentCommandMessage, *, routing_key: str) -> None:
        exchange = await self._ensure_connected()
        body = message.model_dump(mode="json", by_alias=True)
        payload = json.dumps(body, ensure_ascii=False).encode("utf-8")

        last_error: Exception | None = None
        attempts = max(1, self._settings.rabbitmq_publish_retries)

        for attempt in range(1, attempts + 1):
            try:
                await exchange.publish(
                    Message(
                        body=payload,
                        delivery_mode=DeliveryMode.PERSISTENT,
                        content_type="application/json",
                        headers={
                            "x-idempotency-key": message.idempotency_key,
                            "x-action": message.action,
                            "x-user-id": message.user_id,
                        },
                    ),
                    routing_key=routing_key,
                )
                logger.info(
                    "rabbitmq.published",
                    action=message.action,
                    routing_key=routing_key,
                    idempotency_key=message.idempotency_key[:12],
                    attempt=attempt,
                )
                return
            except Exception as exc:
                last_error = exc
                logger.warning(
                    "rabbitmq.publish.retry",
                    attempt=attempt,
                    action=message.action,
                    error=str(exc),
                )
                self._exchange = None
                self._channel = None
                if self._connection and not self._connection.is_closed:
                    await self._connection.close()
                self._connection = None
                if attempt < attempts:
                    await asyncio.sleep(self._settings.rabbitmq_retry_backoff_sec * attempt)

        raise RabbitMQPublishError(
            f"Failed to publish action={message.action} after {attempts} attempts: {last_error}"
        )

    async def aclose(self) -> None:
        if self._connection and not self._connection.is_closed:
            await self._connection.close()
        self._connection = None
        self._channel = None
        self._exchange = None
