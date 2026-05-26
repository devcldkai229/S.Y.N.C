from sync_agent.domain.schemas.rag.exercise_rag import ExerciseRagHit, ExerciseRagSearchResult
from sync_agent.infrastructure.rag.exercise_catalog_search import _parse_string_list


def test_parse_string_list_json_array() -> None:
    assert _parse_string_list('["a", "b"]') == ["a", "b"]


def test_to_prompt_context() -> None:
    result = ExerciseRagSearchResult(
        query="squat đau lưng",
        hits=[
            ExerciseRagHit(
                exercise_code="SQ001",
                name_vi="Squat",
                ai_coaching_cues=["Giữ lưng trung lập"],
                common_mistakes=["Gập lưng"],
            )
        ],
    )
    text = result.to_prompt_context()
    assert "Squat" in text
    assert "Gập lưng" in text
