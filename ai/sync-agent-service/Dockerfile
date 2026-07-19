# SYNC AI Agent Service — production image
FROM python:3.11-slim AS base

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /app

# System deps (asyncpg/pgvector cần build tooling tối thiểu)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential curl \
    && rm -rf /var/lib/apt/lists/*

# Cài dependencies trước (layer cache)
COPY pyproject.toml ./
RUN pip install --upgrade pip && pip install .

# Copy source
COPY app ./app
COPY scripts ./scripts

EXPOSE 8088

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
    CMD curl -fsS http://localhost:8088/healthz || exit 1

CMD ["uvicorn", "app.api.main:app", "--host", "0.0.0.0", "--port", "8088", "--workers", "2"]
