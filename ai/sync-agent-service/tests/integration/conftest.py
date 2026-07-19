"""Pytest fixtures for integration contract tests.

Run with local .NET stack up:
  set RUN_INTEGRATION=1
  pytest tests/integration/test_tool_contracts.py -v
"""
from __future__ import annotations

import pytest

from app.tools.catalog import TOOL_REGISTRY
from tests.integration.integration_harness import (
    build_tool_impls,
    integration_requested,
    make_context,
    patch_safe_tool_call,
    resolve_demo_user_id,
    restore_safe_tool_call,
    services_reachable,
)


@pytest.fixture
async def demo_impls():
    if not integration_requested():
        pytest.skip("Set RUN_INTEGRATION=1 to run integration contract tests")
    if not await services_reachable():
        pytest.skip(".NET services not reachable (start IAM/Roadmap/Nutrition/Payment)")

    patch_safe_tool_call()
    try:
        demo_id, _ = resolve_demo_user_id()
        ctx = make_context(demo_id)
        impls = build_tool_impls(ctx, sorted(TOOL_REGISTRY.keys()))
        yield impls
    finally:
        restore_safe_tool_call()
