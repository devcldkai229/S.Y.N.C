"""Workout AI endpoints consumed by the Flutter create-roadmap flow."""
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.auth import CurrentUser, get_current_user, get_raw_token
from app.core.envelope import ApiResponse, fail, ok
from app.core.rate_limit import check_usage_limit, log_usage
from app.intelligence.pipeline import generate_session_exercises, swap_exercise
from app.models.database import get_db
from app.models.schemas import GenerateSessionRequest, SwapExerciseRequest

router = APIRouter(prefix="/api/v1/ai/workout", tags=["AI Workout"])


@router.post("/generate-session-exercises", response_model=ApiResponse)
async def generate(
    body: GenerateSessionRequest,
    user: CurrentUser = Depends(get_current_user),
    token: str = Depends(get_raw_token),
    db: AsyncSession = Depends(get_db),
) -> ApiResponse:
    await check_usage_limit(user.id, db)
    result, tokens = await generate_session_exercises(
        token,
        db,
        goal=body.goal,
        session_title=body.sessionTitle,
        target_muscle=body.targetMuscleGroup,
        count=body.desiredExerciseCount,
        excluded=set(body.excludeExerciseCodes),
    )
    await log_usage(user.id, "generate_session_exercises", tokens, db)
    if not result.exercises:
        return fail("Chưa có dữ liệu bài tập. Hãy yêu cầu admin chạy reindex.")
    return ok(result.model_dump(), "Đã tạo bài tập bằng AI")


@router.post("/swap-exercise", response_model=ApiResponse)
async def swap(
    body: SwapExerciseRequest,
    user: CurrentUser = Depends(get_current_user),
    token: str = Depends(get_raw_token),
    db: AsyncSession = Depends(get_db),
) -> ApiResponse:
    await check_usage_limit(user.id, db)
    result, tokens = await swap_exercise(
        token,
        db,
        current_code=body.currentExerciseCode,
        goal=body.goal,
        session_title=body.sessionTitle,
        excluded=set(body.excludeExerciseCodes),
    )
    await log_usage(user.id, "swap_exercise", tokens, db)
    if result is None:
        return fail("Không tìm được bài tập thay thế phù hợp.")
    return ok(result.model_dump(), "Đã gợi ý bài tập thay thế")
