-- IAM dev seed (PostgreSQL) — idempotent
-- Database: sync_iam @ localhost:5434
-- Password for all accounts below: Sync@12345
--
-- Run:
--   docker exec -i sync-postgres psql -U postgres -d sync_iam -f - < scripts/seed-iam-dev.sql
-- Or paste in pgAdmin / DBeaver connected to sync_iam

\set ON_ERROR_STOP on

-- Skip entire script if marker user already exists
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM iam.users
        WHERE email = 'dev.seed@sync.local' AND deleted_at IS NULL
    ) THEN
        RAISE NOTICE 'IAM dev seed skipped: dev.seed@sync.local already exists.';
        RETURN;
    END IF;

    INSERT INTO iam.users (
        id,
        email,
        password_hash,
        full_name,
        role,
        status,
        subscription_tier,
        email_verified,
        email_verification_token,
        phone_verified,
        preferred_language,
        time_zone,
        created_at
    ) VALUES
    (
        gen_random_uuid(),
        'dev.seed@sync.local',
        '$2a$12$chQmXeilAphNMMVhjeMD.uLZ7oSCrQxEc8nRCq36Jg8.B8bpBCzCa',
        'Sync Dev',
        'User',
        'Active',
        'Free',
        true,
        NULL,
        false,
        'vi',
        'Asia/Ho_Chi_Minh',
        now()
    ),
    (
        gen_random_uuid(),
        'demo@sync.local',
        '$2a$12$chQmXeilAphNMMVhjeMD.uLZ7oSCrQxEc8nRCq36Jg8.B8bpBCzCa',
        'Demo User',
        'User',
        'Active',
        'Free',
        true,
        NULL,
        false,
        'vi',
        'Asia/Ho_Chi_Minh',
        now()
    );

    RAISE NOTICE 'IAM dev seed completed.';
    RAISE NOTICE '  dev.seed@sync.local / Sync@12345';
    RAISE NOTICE '  demo@sync.local     / Sync@12345';
END $$;
