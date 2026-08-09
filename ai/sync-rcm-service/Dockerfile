# SYNC RCM Service — optimized multi-stage image
FROM python:3.12-slim AS builder
ENV PYTHONDONTWRITEBYTECODE=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PATH="/opt/venv/bin:$PATH"
WORKDIR /app
RUN python -m venv /opt/venv
COPY requirements.txt ./
RUN pip install --upgrade pip && pip install --no-cache-dir -r requirements.txt

FROM python:3.12-slim AS runtime
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PATH="/opt/venv/bin:$PATH"
WORKDIR /app
RUN useradd --create-home --uid 1001 appuser
COPY --from=builder /opt/venv /opt/venv
COPY app ./app
COPY scripts ./scripts
USER appuser
EXPOSE 8000
# start-period: init_db retries when Postgres DNS not ready yet
HEALTHCHECK --interval=30s --timeout=5s --start-period=120s --retries=5 \
    CMD python -c "import urllib.request,sys; sys.exit(0 if urllib.request.urlopen('http://127.0.0.1:8000/health').status==200 else 1)" || exit 1
# Inline sh avoids Windows CRLF breaking docker-entrypoint.sh
CMD ["sh", "-c", "python -m scripts.init_db && exec uvicorn app.main:app --host 0.0.0.0 --port 8000"]

