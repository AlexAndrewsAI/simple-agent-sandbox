"""Shared fixtures and helpers for the test suite.

Helpers are importable as ``from conftest import ...`` because pytest
inserts the tests directory on sys.path.
"""

from __future__ import annotations

import os
import shutil
import subprocess
from pathlib import Path

import pytest

PROJECT_ROOT = Path(__file__).resolve().parent.parent
SCRIPTS_DIR = PROJECT_ROOT / "scripts"

# Mock docker: responds to `compose version` (which run.sh probes), records
# the real run argv, and snapshots every `-f <file>` so tests can inspect
# generated compose overrides even after the script cleans them up.
MOCK_DOCKER = """\
#!/bin/bash
base="${MOCK_DOCKER_DIR:?MOCK_DOCKER_DIR not set}"
if [ "$1" = "compose" ] && [ "$2" = "version" ]; then
  echo "Docker Compose version v2.24.0"
  exit 0
fi
echo "$@" > "$base/args.txt"
i=0
prev=""
for a in "$@"; do
  if [ "$prev" = "-f" ]; then
    cp "$a" "$base/override-$i.yml" 2>/dev/null || true
    i=$((i+1))
  fi
  prev="$a"
done
exit 0
"""


def make_project(tmp_path: Path, scripts: list[str], config: str, compose: str) -> Path:
    """Build an isolated project tree in tmp_path with scripts + configs."""
    scripts_dir = tmp_path / "scripts"
    scripts_dir.mkdir()
    for name in scripts:
        shutil.copy(SCRIPTS_DIR / name, scripts_dir / name)
    (tmp_path / "config.yml").write_text(config)
    (tmp_path / "docker-compose.yml").write_text(compose)
    return tmp_path


def run_bash(cmd: str, cwd: Path, env_extra: dict[str, str] | None = None) -> subprocess.CompletedProcess:
    env = {**os.environ, **(env_extra or {})}
    return subprocess.run(
        ["bash", "-c", cmd],
        capture_output=True,
        text=True,
        cwd=cwd,
        env=env,
        stdin=subprocess.DEVNULL,
        check=False,
    )


def run_pwsh(
    args: list[str], cwd: Path, env_extra: dict[str, str] | None = None
) -> subprocess.CompletedProcess:
    env = {**os.environ, **(env_extra or {})}
    return subprocess.run(
        ["pwsh", "-NoProfile", *args],
        capture_output=True,
        text=True,
        cwd=cwd,
        env=env,
        stdin=subprocess.DEVNULL,
        check=False,
    )


def docker_args(state: Path) -> list[str]:
    """The argv the mock docker was last invoked with."""
    return (state / "args.txt").read_text().split()


def override_files(state: Path) -> list[Path]:
    """Snapshots of every `-f <file>` the mock docker received."""
    return sorted(state.glob("override-*.yml"))


def mock_env(state: Path) -> dict[str, str]:
    """Env for running scripts that need the mock docker on PATH."""
    return {
        "PATH": f"{state / 'bin'}:{os.environ.get('PATH', '')}",
        "MOCK_DOCKER_DIR": str(state),
    }


@pytest.fixture
def mock_docker(tmp_path: Path) -> Path:
    """Return a state dir containing a mock `docker` binary on PATH."""
    state = tmp_path / "state"
    (state / "bin").mkdir(parents=True)
    docker = state / "bin" / "docker"
    docker.write_text(MOCK_DOCKER)
    docker.chmod(0o755)
    return state


@pytest.fixture(scope="session")
def pwsh() -> str:
    """Path to PowerShell; skips the whole session when unavailable."""
    path = shutil.which("pwsh")
    if path is None:
        pytest.skip("pwsh not available on this platform")
    return path


@pytest.fixture(scope="session")
def hadolint() -> str:
    """Path to hadolint; skips the whole session when unavailable."""
    path = shutil.which("hadolint")
    if path is None:
        pytest.skip("hadolint not installed")
    return path
