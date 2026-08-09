"""Realtime Voice Gateway + STT/TTS stubs.

Phương án C1 (khuyến nghị giai đoạn đầu): cầu nối client <-> OpenAI Realtime API.
- LLM nhận/audio trực tiếp (VAD + barge-in tích hợp).
- Khi model phát function_call -> resolve qua LangGraph "tool brain" (gọi .NET),
  trả function_result lại cho model. Vòng audio KHÔNG bị chặn bởi tool .NET.

Phương án C2 (tự chủ, giảm cost): STT streaming (Whisper) -> graph -> TTS streaming
(LiveKit Agents/Pipecat). Giữ nguyên graph/tool layer -> đổi backend không viết lại logic.
"""
from __future__ import annotations

from typing import Any


# --- STT / TTS stubs ---------------------------------------------------------
async def transcribe(audio: bytes) -> tuple[str, str]:
    """STT -> (text, locale). Thực tế: PhoWhisper/Whisper large-v3, auto vi/en."""
    # TODO: gọi STT engine. Trả stub để scaffolding chạy được.
    return ("(transcript stub)", "vi")


async def synthesize(text: str, *, locale: str, persona: str) -> str:
    """TTS -> URL audio (MinIO). Giọng theo persona/locale (VN voice)."""
    # TODO: gọi TTS engine, upload MinIO, trả presigned URL.
    return "minio://sync-tts/stub.mp3"


# --- Realtime session bridge -------------------------------------------------
class RealtimeVoiceSession:
    """Cầu nối WS client <-> OpenAI Realtime; dùng graph làm tool brain.

    Vòng đời:
      client audio --> OpenAI Realtime --> (transcript + audio out) --> client
                       └─ function_call --> graph/tools (.NET) --> function_result
    """

    def __init__(self, graph: Any | None) -> None:
        self.graph = graph

    async def run(self, ws: Any) -> None:
        """Pump 2 chiều. Stub: minh hoạ vòng lặp & nơi cắm Realtime API."""
        try:
            # TODO: mở kết nối tới OpenAI Realtime (websockets), cấu hình:
            #   - model = settings.openai_realtime_model
            #   - turn_detection = server_vad (barge-in)
            #   - tools = schema function-calls (map tới app/tools/dotnet.py)
            while True:
                msg = await ws.receive_bytes()
                # forward audio -> realtime model; nhận audio out -> ws.send_bytes(...)
                # khi có function_call -> await self._resolve_tool(call)
                await ws.send_bytes(msg)  # echo stub
        except Exception:
            await ws.close()

    async def _resolve_tool(self, call: dict[str, Any]) -> dict[str, Any]:
        """Map function_call tên -> tool .NET tương ứng, qua graph để đồng nhất guardrail."""
        # TODO: dispatch theo call["name"] tới app.tools.dotnet.*
        return {"ok": True}
