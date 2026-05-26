"""Map LLM tool action names to RabbitMQ routing keys / queues."""

from __future__ import annotations

# Topic routing keys bound to workout_commands queue (see infra declare).
_ACTION_ROUTING: dict[str, str] = {
    "RescheduleWorkout": "workout.reschedule",
    "Reschedule": "workout.reschedule",
    "CancelWorkout": "workout.cancel",
    "SkipWorkout": "workout.skip",
    "UpdateSessionStatus": "workout.session.update",
    "LogNutrition": "nutrition.log",
    "CreateMealPlan": "nutrition.meal_plan",
}

_DEFAULT_ROUTING_KEY = "agent.command"


def resolve_routing_key(action: str) -> str:
    normalized = action.strip()
    if not normalized:
        return _DEFAULT_ROUTING_KEY
    return _ACTION_ROUTING.get(normalized, _DEFAULT_ROUTING_KEY)
