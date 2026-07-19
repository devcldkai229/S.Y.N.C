"""Eval offline: persona + motivation phải tạo prompt khác biệt rõ; cache key tách style."""
from __future__ import annotations

from app.models.semantic_cache import SemanticCache, style_scope
from app.prompts.agents import (
    AGENT_PROMPTS_VERSION,
    MOTIVATION_STYLE_VI,
    PERSONA_VOICE_VI,
    SAFETY_RULES_VI,
    build_agent_system_prompt,
)

PERSONAS = ("StrictCoach", "FriendlyBuddy", "CalmMentor", "EnergeticTrainer")
MOTIVATIONS = (
    "Supportive",
    "Aggressive",
    "DisciplineFocused",
    "Friendly",
    "Competitive",
    "Minimal",
)


def test_prompts_version_bumped():
    assert AGENT_PROMPTS_VERSION.startswith("agents-v1.5")


def test_safety_no_longer_forces_short_or_cheerleader_tone():
    assert "Trả lời NGẮN GỌN" not in SAFETY_RULES_VI
    assert "luôn ĐỘNG VIÊN cố gắng tập" not in SAFETY_RULES_VI
    assert "tool" in SAFETY_RULES_VI.lower() or "TOOL" in SAFETY_RULES_VI
    assert "markdown" in SAFETY_RULES_VI.lower()
    assert "BỊ BỆNH" in SAFETY_RULES_VI or "chấn thương" in SAFETY_RULES_VI.lower()


def test_persona_voice_packs_are_distinct_and_rich():
    assert set(PERSONA_VOICE_VI) == set(PERSONAS)
    texts = [PERSONA_VOICE_VI[p] for p in PERSONAS]
    assert len(set(texts)) == len(PERSONAS)
    for p in PERSONAS:
        pack = PERSONA_VOICE_VI[p]
        assert "Ví dụ:" in pack
        assert "DO:" in pack or "- DO:" in pack
        assert len(pack) > 200

    strict = PERSONA_VOICE_VI["StrictCoach"]
    assert "Làm ngay" in strict or "Không bàn cãi" in strict
    assert "emoji" in strict.lower()

    buddy = PERSONA_VOICE_VI["FriendlyBuddy"]
    assert "ê" in buddy.lower() or "nè" in buddy or "haha" in buddy.lower()

    mentor = PERSONA_VOICE_VI["CalmMentor"]
    assert "vì sao" in mentor.lower() or "Vì sao" in mentor

    energy = PERSONA_VOICE_VI["EnergeticTrainer"]
    assert "🔥" in energy or "💪" in energy
    assert "!" in energy


def test_motivation_modifiers_are_distinct():
    assert set(MOTIVATION_STYLE_VI) == set(MOTIVATIONS)
    texts = [MOTIVATION_STYLE_VI[m] for m in MOTIVATIONS]
    assert len(set(texts)) == len(MOTIVATIONS)

    minimal = MOTIVATION_STYLE_VI["Minimal"]
    assert "1–2 câu" in minimal or "1-2 câu" in minimal or "CỰC NGẮN" in minimal
    assert "Không emoji" in minimal or "không emoji" in minimal.lower()

    aggressive = MOTIVATION_STYLE_VI["Aggressive"]
    assert "Chỉ vậy thôi à" in aggressive or "thách thức" in aggressive.lower()


def test_build_prompt_embeds_persona_and_motivation_with_style_lock():
    prompt = build_agent_system_prompt(
        "coach",
        persona="StrictCoach",
        motivation="Aggressive",
        locale="vi",
    )
    assert "PHONG CÁCH & ĐỘNG VIÊN" in prompt
    assert "StrictCoach" in prompt
    assert "Aggressive" in prompt
    assert "STYLE LOCK" in prompt
    assert prompt.index("PHONG CÁCH & ĐỘNG VIÊN") < prompt.index("STYLE LOCK")
    assert "Không bàn cãi" in prompt or "Làm ngay" in prompt
    assert "Chỉ vậy thôi à" in prompt or "thách thức" in prompt.lower()


def test_same_question_four_personas_yield_very_different_prompts():
    prompts = {
        p: build_agent_system_prompt(
            "coach",
            persona=p,
            motivation="Supportive",
            locale="vi",
        )
        for p in PERSONAS
    }
    assert len(set(prompts.values())) == len(PERSONAS)
    # Characteristic markers must differ across packs inside full prompt
    assert "Không bàn cãi" in prompts["StrictCoach"] or "Làm ngay" in prompts["StrictCoach"]
    assert "🔥" in prompts["EnergeticTrainer"] or "💪" in prompts["EnergeticTrainer"]
    assert "vì sao" in prompts["CalmMentor"].lower() or "Vì sao" in prompts["CalmMentor"]
    assert "haha" in prompts["FriendlyBuddy"].lower() or "ê" in prompts["FriendlyBuddy"].lower()


def test_six_motivations_yield_different_prompts():
    prompts = {
        m: build_agent_system_prompt(
            "coach",
            persona="FriendlyBuddy",
            motivation=m,
            locale="vi",
        )
        for m in MOTIVATIONS
    }
    assert len(set(prompts.values())) == len(MOTIVATIONS)
    assert "CỰC NGẮN" in prompts["Minimal"] or "1–2 câu" in prompts["Minimal"]
    assert "vượt chính mình" in prompts["Competitive"].lower() or "Hôm qua" in prompts["Competitive"]
    assert "kỷ luật" in prompts["DisciplineFocused"].lower()


def test_minimal_overrides_noted_in_style_block():
    prompt = build_agent_system_prompt(
        "coach",
        persona="EnergeticTrainer",
        motivation="Minimal",
    )
    assert "Minimal luôn thắng" in prompt or "Motivation=Minimal" in prompt


def test_style_scope_and_cache_keys_differ_by_persona_motivation():
    q = "Hôm nay tôi lười tập quá"
    s1 = style_scope(persona="StrictCoach", motivation="Aggressive", locale="vi")
    s2 = style_scope(persona="CalmMentor", motivation="Supportive", locale="vi")
    s3 = style_scope(persona="StrictCoach", motivation="Minimal", locale="vi")
    assert s1 != s2 != s3
    assert "p=StrictCoach" in s1 and "m=Aggressive" in s1

    cache = SemanticCache(redis_client=None)
    k1 = cache.exact_key_for(q, persona="StrictCoach", motivation="Aggressive")
    k2 = cache.exact_key_for(q, persona="FriendlyBuddy", motivation="Aggressive")
    k3 = cache.exact_key_for(q, persona="StrictCoach", motivation="Minimal")
    assert k1 != k2
    assert k1 != k3
    assert k2 != k3


def test_base_system_prompt_passes_motivation_style():
    from app.graph.agents.base import system_prompt

    state = {
        "persona": "EnergeticTrainer",
        "motivation_style": "Competitive",
        "locale": "vi",
        "user_snapshot": None,
    }
    text = system_prompt(state, "coach")  # type: ignore[arg-type]
    assert "EnergeticTrainer" in text
    assert "Competitive" in text
    assert "STYLE LOCK" in text
