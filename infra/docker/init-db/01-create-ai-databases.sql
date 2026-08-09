-- AI + Langfuse databases (runs once on fresh postgres volume)
CREATE DATABASE sync_ai;
CREATE DATABASE sync_ai_agent;
CREATE DATABASE langfuse;
\c sync_ai
CREATE EXTENSION IF NOT EXISTS vector;
\c sync_ai_agent
CREATE EXTENSION IF NOT EXISTS vector;
