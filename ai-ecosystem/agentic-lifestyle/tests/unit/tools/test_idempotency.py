from sync_agent.application.tools.idempotency import build_idempotency_key


def test_idempotency_key_deterministic() -> None:
    a = build_idempotency_key("user-1", "RescheduleWorkout", "2026-05-22T10:00:00+00:00")
    b = build_idempotency_key("user-1", "RescheduleWorkout", "2026-05-22T10:00:00+00:00")
    assert a == b
    assert len(a) == 64


def test_idempotency_key_differs_by_action() -> None:
    ts = "2026-05-22T10:00:00+00:00"
    a = build_idempotency_key("user-1", "RescheduleWorkout", ts)
    b = build_idempotency_key("user-1", "CancelWorkout", ts)
    assert a != b
