import pytest

from sync_agent.core.config import Settings


@pytest.fixture
def settings() -> Settings:
    return Settings(
        groq_api_key="test-key",
        debug=True,
    )
