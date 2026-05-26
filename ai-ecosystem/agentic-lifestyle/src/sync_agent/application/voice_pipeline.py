import asyncio

from collections.abc import Awaitable, Callable

from typing import Any



import structlog



from sync_agent.application.agent_runner import AgentRunner

from sync_agent.application.text_chunking import build_phase1_reply, iter_speech_segments

from sync_agent.core.config import Settings

from sync_agent.core.exceptions import AudioBufferError, LLMProviderError, SpeechToTextError, TextToSpeechError

from sync_agent.domain.voice.protocol import ServerMessageType, ServerEnvelope

from sync_agent.domain.voice.session import VoiceSession

from sync_agent.infrastructure.stt.base import SpeechToTextPort

from sync_agent.infrastructure.tts.base import TextToSpeechPort



logger = structlog.get_logger(__name__)



SendJson = Callable[[dict[str, Any]], Awaitable[None]]

SendBytes = Callable[[bytes], Awaitable[None]]





class VoicePipeline:

    """

    End-to-end utterance processing:

    PCM buffer → Groq STT → LangGraph (dual output) → concurrent TTS + RabbitMQ tools.

    """



    def __init__(

        self,

        *,

        stt: SpeechToTextPort,

        tts: TextToSpeechPort,

        settings: Settings,

        agent_runner: AgentRunner | None = None,

    ) -> None:

        self._stt = stt

        self._tts = tts

        self._settings = settings

        self._agent = agent_runner



    async def process_utterance(

        self,

        session: VoiceSession,

        *,

        send_json: SendJson,

        send_bytes: SendBytes,

    ) -> None:

        sid = session.session_id or session.connection_id

        buffer = session.ensure_buffer()



        if buffer.is_empty:

            await send_json(

                ServerEnvelope(

                    type=ServerMessageType.ERROR,

                    session_id=sid,

                    payload={"code": "empty_audio", "message": "No audio received"},

                ).to_json()

            )

            return



        await send_json(

            ServerEnvelope(

                type=ServerMessageType.PIPELINE_START,

                session_id=sid,

                payload={"audio_bytes": buffer.byte_count, "duration_sec": buffer.duration_seconds()},

            ).to_json()

        )



        try:

            wav = buffer.to_wav_bytes()

            buffer.clear()



            transcription = await self._stt.transcribe_wav(

                wav,

                language=self._settings.groq_stt_language,

            )



            await send_json(

                ServerEnvelope(

                    type=ServerMessageType.STT_FINAL,

                    session_id=sid,

                    payload={

                        "text": transcription.text,

                        "language": transcription.language,

                        "duration_sec": transcription.duration_sec,

                    },

                ).to_json()

            )



            if self._agent and session.user_id:

                await self._run_agent_turn(

                    session,

                    transcript=transcription.text,

                    send_json=send_json,

                    send_bytes=send_bytes,

                )

            else:

                await self._run_phase1_fallback(

                    transcription.text,

                    session_id=sid,

                    send_json=send_json,

                    send_bytes=send_bytes,

                )



        except AudioBufferError as exc:

            await send_json(

                ServerEnvelope(

                    type=ServerMessageType.ERROR,

                    session_id=sid,

                    payload={"code": "audio_buffer", "message": str(exc)},

                ).to_json()

            )

        except SpeechToTextError as exc:

            await send_json(

                ServerEnvelope(

                    type=ServerMessageType.ERROR,

                    session_id=sid,

                    payload={"code": "stt_failed", "message": str(exc)},

                ).to_json()

            )

        except (TextToSpeechError, LLMProviderError) as exc:

            await send_json(

                ServerEnvelope(

                    type=ServerMessageType.ERROR,

                    session_id=sid,

                    payload={"code": "agent_failed", "message": str(exc)},

                ).to_json()

            )

        finally:

            session.mark_idle()

            await send_json(

                ServerEnvelope(

                    type=ServerMessageType.PIPELINE_END,

                    session_id=sid,

                ).to_json()

            )



    async def _run_phase1_fallback(

        self,

        transcript: str,

        *,

        session_id: str,

        send_json: SendJson,

        send_bytes: SendBytes,

    ) -> None:

        assistant_text = build_phase1_reply(transcript)

        await send_json(

            ServerEnvelope(

                type=ServerMessageType.ASSISTANT_TEXT,

                session_id=session_id,

                payload={"text": assistant_text, "mode": "phase1_fallback"},

            ).to_json()

        )

        await self._stream_tts(

            assistant_text,

            session_id=session_id,

            send_json=send_json,

            send_bytes=send_bytes,

        )



    async def _run_agent_turn(

        self,

        session: VoiceSession,

        *,

        transcript: str,

        send_json: SendJson,

        send_bytes: SendBytes,

    ) -> None:

        sid = session.session_id or session.connection_id

        tts_task: asyncio.Task[None] | None = None

        spoken_holder: list[str] = []



        async def on_spoken_ready(text: str) -> None:

            spoken_holder.append(text)

            await send_json(

                ServerEnvelope(

                    type=ServerMessageType.ASSISTANT_TEXT,

                    session_id=sid,

                    payload={"text": text, "mode": "agent"},

                ).to_json()

            )

            nonlocal tts_task

            tts_task = asyncio.create_task(

                self._stream_tts(

                    text,

                    session_id=sid,

                    send_json=send_json,

                    send_bytes=send_bytes,

                )

            )



        assert self._agent is not None

        result = await self._agent.run_turn_streaming(

            user_message=transcript,

            user_id=session.user_id,

            session_id=session.session_id,

            bearer_token=session.bearer_token,

            on_spoken_ready=on_spoken_ready,

        )



        tool_results = result.get("tool_execution_results") or []

        if tool_results:

            await send_json(

                ServerEnvelope(

                    type=ServerMessageType.TOOL_PUBLISHED,

                    session_id=sid,

                    payload={"results": tool_results},

                ).to_json()

            )



        if tts_task is not None:

            await tts_task

        elif not spoken_holder:

            fallback = result.get("spoken_response") or build_phase1_reply(transcript)

            await on_spoken_ready(fallback)



    async def _stream_tts(

        self,

        text: str,

        *,

        session_id: str,

        send_json: SendJson,

        send_bytes: SendBytes,

    ) -> None:

        segments = iter_speech_segments(text)

        if not segments:

            return



        await send_json(

            ServerEnvelope(

                type=ServerMessageType.TTS_START,

                session_id=session_id,

                payload={

                    "format": self._settings.tts_response_format,

                    "voice": self._settings.tts_voice,

                    "segment_count": len(segments),

                },

            ).to_json()

        )



        try:

            for index, segment in enumerate(segments):

                logger.debug("tts.segment", index=index, chars=len(segment))

                async for chunk in self._tts.stream_speech(segment):

                    await send_bytes(chunk)

        finally:

            await send_json(

                ServerEnvelope(

                    type=ServerMessageType.TTS_END,

                    session_id=session_id,

                ).to_json()

            )


