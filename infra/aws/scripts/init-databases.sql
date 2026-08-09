-- Chạy 1 lần sau khi RDS lên (idempotent) — qua SSM port-forward hoặc bastion:
--   bash infra/aws/scripts/init-db.sh -e prod
-- Password: Secrets Manager /sync/<env>/db/postgres-password
-- User: SSM /sync/<env>/db/pg-user
-- Postgres không có CREATE DATABASE IF NOT EXISTS → dùng \gexec.

SELECT format('CREATE DATABASE %I', db)
FROM unnest(ARRAY[
  'sync_iam',
  'sync_order',
  'sync_payment',
  'sync_smartpush',
  'sync_ai',
  'sync_ai_agent'
]) AS db
WHERE NOT EXISTS (SELECT 1 FROM pg_database WHERE datname = db)
\gexec

-- pgvector cho 2 DB AI (RDS PostgreSQL ≥15 có sẵn extension)
\connect sync_ai
CREATE EXTENSION IF NOT EXISTS vector;

\connect sync_ai_agent
CREATE EXTENSION IF NOT EXISTS vector;
