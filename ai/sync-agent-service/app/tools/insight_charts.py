"""Chart display_payload builders for Insight Agent (client renders via fl_chart)."""
from __future__ import annotations

from typing import Any, Iterable, Sequence


def chart_payload(
    *,
    chart_type: str,
    title: str,
    x_labels: Sequence[str],
    series: Sequence[dict[str, Any]],
    unit: str = "",
    granularity: str = "day",
    subtitle: str = "",
    annotations: list[dict[str, Any]] | None = None,
    summary: str = "",
) -> dict[str, Any]:
    return {
        "type": "chart",
        "chartType": chart_type,
        "title": title,
        "subtitle": subtitle or None,
        "unit": unit or None,
        "granularity": granularity,
        "xLabels": list(x_labels),
        "series": [dict(s) for s in series],
        "annotations": annotations or [],
        "summary": summary or None,
    }


def insight_dashboard(
    *,
    charts: Sequence[dict[str, Any]],
    verdict: str = "",
    confidence: str = "",
    factors: Sequence[str] | None = None,
    period_label: str = "",
) -> dict[str, Any]:
    return {
        "type": "insight_dashboard",
        "charts": list(charts),
        "verdict": verdict or None,
        "confidence": confidence or None,
        "factors": list(factors or []),
        "periodLabel": period_label or None,
    }


def premium_upsell_payload(*, feature: str = "AI Insights & biểu đồ") -> dict[str, Any]:
    return {
        "type": "premium_upsell",
        "feature": feature,
        "title": "Nâng Premium để mở biểu đồ & dự đoán",
        "body": (
            "Gói Premium mở thống kê đa kỳ, biểu đồ dinh dưỡng/tập luyện, "
            "nhận định mức ăn có ổn không và ETA tới mục tiêu."
        ),
        "cta": "Nâng cấp Premium",
    }


def series(name: str, data: Iterable[float | int | None], *, style: str | None = None) -> dict[str, Any]:
    out: dict[str, Any] = {
        "name": name,
        "data": [None if v is None else float(v) for v in data],
    }
    if style:
        out["style"] = style
    return out


def target_line(value: float, *, label: str = "Mục tiêu") -> dict[str, Any]:
    return {"type": "targetLine", "value": float(value), "label": label}


def projection_annotation(name: str, data: Sequence[float | None]) -> dict[str, Any]:
    return {
        "type": "projection",
        "name": name,
        "data": [None if v is None else float(v) for v in data],
    }


def band_annotation(label: str, min_v: float, max_v: float) -> dict[str, Any]:
    return {"type": "band", "label": label, "min": float(min_v), "max": float(max_v)}
