from fastapi import APIRouter

from app.api import admin, workout

api_router = APIRouter()
api_router.include_router(workout.router)
api_router.include_router(admin.router)
