import uvicorn

from sync_agent.api.app import create_app
from sync_agent.core.config import get_settings

app = create_app()


def cli() -> None:
    settings = get_settings()
    uvicorn.run(
        "sync_agent.main:app",
        host=settings.host,
        port=settings.port,
        reload=settings.debug,
        log_level="debug" if settings.debug else "info",
    )


if __name__ == "__main__":
    cli()
