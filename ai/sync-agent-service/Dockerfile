# SYNC AI Agent Service — optimized multi-stage image
# builder: has build toolchain + venv; runtime: slim, no compilers, non-root.
FROM python:3.11-slim AS builder
ENV PYTHONDONTWRITEBYTECODE=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PATH="/opt/venv/bin:$PATH"
WORKDIR /app
RUN apt-get update \
    && apt-get install -y --no-install-recommends build-essential \
    && rm -rf /var/lib/apt/lists/*
RUN python -m venv /opt/venv
# hatchling packages=["app"] -> the package source must exist before install
COPY pyproject.toml ./
COPY app ./app
COPY scripts ./scripts
RUN pip install --upgrade pip && pip install .

FROM python:3.11-slim AS runtime
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PATH="/opt/venv/bin:$PATH"
WORKDIR /app
RUN useradd --create-home --uid 1001 appuser
COPY --from=builder /opt/venv /opt/venv
COPY app ./app
COPY scripts ./scripts
USER appuser
EXPOSE 8088
HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
    CMD python -c "import urllib.request,sys; sys.exit(0 if urllib.request.urlopen('http://127.0.0.1:8088/healthz').status==200 else 1)" || exit 1
CMD ["uvicorn", "app.api.main:app", "--host", "0.0.0.0", "--port", "8088", "--workers", "2"]
