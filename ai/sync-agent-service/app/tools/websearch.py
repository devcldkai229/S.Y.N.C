"""Web search via Tavily — chỉ dùng cho Coach khi cần xác minh thông tin chính xác cao.

Cần biến môi trường: TAVILY_API_KEY
Fallback: nếu không cấu hình key thì trả lỗi rõ ràng (không crash turn).
"""
from __future__ import annotations

import httpx

from app.config import get_settings

_TAVILY_URL = "https://api.tavily.com/search"
_TIMEOUT = httpx.Timeout(15.0, connect=5.0)


async def web_search(query: str, *, max_results: int = 5) -> dict:
    """Tìm kiếm web qua Tavily. Trả về danh sách kết quả với title + url + snippet."""
    s = get_settings()
    if not s.tavily_api_key:
        return {"error": "TAVILY_API_KEY chưa được cấu hình. Không thể tìm kiếm web.", "results": []}

    payload = {
        "api_key": s.tavily_api_key,
        "query": query,
        "max_results": min(max_results, 8),
        "search_depth": "basic",
        "include_answer": True,
        "include_raw_content": False,
    }
    try:
        async with httpx.AsyncClient(timeout=_TIMEOUT) as client:
            r = await client.post(_TAVILY_URL, json=payload)
            r.raise_for_status()
            data = r.json()
    except Exception as exc:
        return {"error": f"Tìm kiếm thất bại: {exc}", "results": []}

    results = [
        {
            "title": item.get("title", ""),
            "url": item.get("url", ""),
            "snippet": item.get("content", "")[:400],
        }
        for item in data.get("results", [])
    ]
    return {
        "query": query,
        "answer": data.get("answer", ""),
        "results": results,
    }
