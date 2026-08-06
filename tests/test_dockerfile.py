"""Dockerfile linting with hadolint.

Mirrors the hadolint pre-commit hook (`.pre-commit-config.yaml`) so the
Dockerfile is verified in the pytest suite as well — and in CI without
needing Docker. Tests skip when hadolint is not installed.
"""

from __future__ import annotations

import subprocess

import yaml
from conftest import PROJECT_ROOT

HADOLINT_CONFIG = PROJECT_ROOT / ".hadolint.yaml"


class TestHadolintConfig:
    def test_config_exists(self) -> None:
        assert HADOLINT_CONFIG.exists(), ".hadolint.yaml is required by hadolint"

    def test_dl3008_ignored(self) -> None:
        """DL3008 (pin apt versions) is intentionally ignored — documented in
        the config and relied on by the Dockerfile's --no-install-recommends."""
        data = yaml.safe_load(HADOLINT_CONFIG.read_text())
        assert "DL3008" in data.get("ignored", [])


class TestDockerfileHadolint:
    def test_dockerfile_passes_hadolint(self, hadolint: str) -> None:
        """Dockerfile must pass hadolint with the project's .hadolint.yaml."""
        result = subprocess.run(
            [hadolint, "Dockerfile"],
            capture_output=True,
            text=True,
            cwd=PROJECT_ROOT,
            check=False,
        )
        assert result.returncode == 0, (
            "hadolint reported issues:\n"
            + (result.stdout + result.stderr).strip()
        )
