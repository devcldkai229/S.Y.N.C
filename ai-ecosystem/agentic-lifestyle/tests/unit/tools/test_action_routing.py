from sync_agent.application.tools.routing import resolve_routing_key


def test_workout_reschedule_routing() -> None:
    assert resolve_routing_key("RescheduleWorkout") == "workout.reschedule"
    assert resolve_routing_key("Reschedule") == "workout.reschedule"


def test_unknown_action_defaults() -> None:
    assert resolve_routing_key("CustomAction") == "agent.command"
