"""Tests for the no-internet runtime mode.

No-internet works by merging a temporary compose override
(``network_mode: none``) at runtime. These tests drive the real run.sh and
win-run.ps1 code paths against a mock ``docker`` executable and verify the
generated override's compose-merge semantics.

The pwsh-based tests skip when PowerShell is unavailable; the mock docker is
a bash script, so those also skip on native Windows.
"""

from __future__ import annotations

import sys
from pathlib import Path

import pytest
import yaml
from conftest import (
    docker_args,
    make_project,
    mock_env,
    override_files,
    run_bash,
    run_pwsh,
)

BASE_COMPOSE = """\
services:
  sandbox:
    image: test
    volumes:
      - ./persist:/persist
"""


def _deep_merge(base: dict, override: dict) -> dict:
    """Approximate docker-compose's deep map merge (maps merge recursively,
    scalars overwrite) so the override's effect can be verified without
    Docker."""
    merged = dict(base)
    for key, value in override.items():
        if isinstance(value, dict) and isinstance(merged.get(key), dict):
            merged[key] = _deep_merge(merged[key], value)
        else:
            merged[key] = value
    return merged

CONFIG_TEMPLATE = """\
options:
  auto_cd_mount: false
  automount_cwd: false
  no_internet: {enabled}
"""


def _config(enabled: bool) -> str:
    return CONFIG_TEMPLATE.format(enabled="true" if enabled else "false")


def _find_no_internet_override(state: Path) -> Path:
    matches = [
        f for f in override_files(state) if "network_mode" in f.read_text()
    ]
    assert len(matches) == 1, (
        f"expected exactly one no-internet override, "
        f"found {[f.name for f in matches]}"
    )
    return matches[0]


class TestRunShNoInternet:
    """run.sh generates the override and passes it to `docker compose`."""

    @staticmethod
    def _run(
        tmp_path: Path, state: Path, enabled: bool, flag: str | None = None
    ) -> None:
        project = make_project(
            tmp_path, ["run.sh", "_config_check.sh"], _config(enabled), BASE_COMPOSE
        )
        cmd = "bash scripts/run.sh" + (f" {flag}" if flag else "")
        result = run_bash(cmd, project, mock_env(state))
        assert result.returncode == 0, result.stderr

    def test_config_enabled_passes_override(self, tmp_path, mock_docker) -> None:
        self._run(tmp_path, mock_docker, enabled=True)
        args = docker_args(mock_docker)
        assert "compose" in args and "run" in args
        override = _find_no_internet_override(mock_docker)
        assert yaml.safe_load(override.read_text()) == {
            "services": {"sandbox": {"network_mode": "none"}}
        }

    def test_flag_enables_despite_config_off(self, tmp_path, mock_docker) -> None:
        self._run(tmp_path, mock_docker, enabled=False, flag="-n")
        assert "network_mode" in _find_no_internet_override(mock_docker).read_text()

    def test_long_flag(self, tmp_path, mock_docker) -> None:
        self._run(tmp_path, mock_docker, enabled=False, flag="--no-internet")
        _find_no_internet_override(mock_docker)

    def test_disabled_no_override(self, tmp_path, mock_docker) -> None:
        self._run(tmp_path, mock_docker, enabled=False)
        assert not any(
            "network_mode" in f.read_text() for f in override_files(mock_docker)
        )

    def test_override_file_cleaned_up(self, tmp_path, mock_docker) -> None:
        """The temp override must not be left behind after the run exits."""
        self._run(tmp_path, mock_docker, enabled=True)
        for arg in docker_args(mock_docker):
            if arg.startswith("/tmp/"):
                assert not Path(arg).exists(), f"leftover temp file: {arg}"

    def test_override_merge_semantics(self, tmp_path, mock_docker) -> None:
        """Merging the generated override into the compose file disables the
        sandbox network without clobbering its other keys."""
        self._run(tmp_path, mock_docker, enabled=True)
        base = yaml.safe_load(BASE_COMPOSE)
        override = yaml.safe_load(_find_no_internet_override(mock_docker).read_text())
        merged = _deep_merge(base, override)
        assert merged["services"]["sandbox"]["network_mode"] == "none"
        assert merged["services"]["sandbox"]["image"] == "test"
        assert merged["services"]["sandbox"]["volumes"] == ["./persist:/persist"]


@pytest.mark.skipif(
    sys.platform.startswith("win"), reason="mock docker is a bash script"
)
class TestWinRunNoInternet:
    """win-run.ps1 generates the override and passes it to `docker compose`."""

    @staticmethod
    def _run(
        tmp_path: Path, state: Path, enabled: bool, flag: str | None = None
    ) -> None:
        project = make_project(
            tmp_path,
            ["win-run.ps1", "win-cd-mount.ps1", "_config_check.ps1"],
            _config(enabled),
            BASE_COMPOSE,
        )
        args = ["-File", "scripts/win-run.ps1"]
        if flag:
            args.append(flag)
        result = run_pwsh(args, project, mock_env(state))
        assert result.returncode == 0, result.stderr

    def test_config_enabled_passes_override(self, pwsh, tmp_path, mock_docker) -> None:
        self._run(tmp_path, mock_docker, enabled=True)
        args = docker_args(mock_docker)
        assert "compose" in args and "run" in args
        override = _find_no_internet_override(mock_docker)
        assert yaml.safe_load(override.read_text()) == {
            "services": {"sandbox": {"network_mode": "none"}}
        }

    def test_flag_enables_despite_config_off(self, pwsh, tmp_path, mock_docker) -> None:
        self._run(tmp_path, mock_docker, enabled=False, flag="-n")
        assert "network_mode" in _find_no_internet_override(mock_docker).read_text()

    def test_disabled_no_override(self, pwsh, tmp_path, mock_docker) -> None:
        self._run(tmp_path, mock_docker, enabled=False)
        assert not any(
            "network_mode" in f.read_text() for f in override_files(mock_docker)
        )

    def test_override_file_cleaned_up(self, pwsh, tmp_path, mock_docker) -> None:
        self._run(tmp_path, mock_docker, enabled=True)
        for arg in docker_args(mock_docker):
            if arg.endswith(".yml") and "no-internet" in arg:
                assert not Path(arg).exists(), f"leftover temp file: {arg}"
