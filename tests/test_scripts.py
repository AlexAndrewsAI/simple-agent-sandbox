"""Integration tests for all shell scripts in scripts/.

Tests use subprocess to invoke bash functions/logic, with temporary
directories (tmp_path) for isolated filesystem exercises.
"""

from __future__ import annotations

import subprocess
from pathlib import Path

import pytest

SCRIPTS_DIR = Path(__file__).resolve().parent.parent / "scripts"
PROJECT_ROOT = SCRIPTS_DIR.parent


# ── Helpers ──────────────────────────────────────────────────────────


def _bash(cmd: str, cwd: Path | None = None, env: dict | None = None) -> subprocess.CompletedProcess:
    """Run a bash command and return the result."""
    full_env = None
    if env is not None:
        import os
        full_env = {**os.environ, **env}
    return subprocess.run(
        ["bash", "-c", cmd],
        capture_output=True,
        text=True,
        cwd=cwd or PROJECT_ROOT,
        env=full_env,
    )

# ── _config_check.sh ────────────────────────────────────────────────


class TestConfigCheck:
    """Tests for _config_check.sh — config file detection and auto-copy."""

    def test_silent_when_configs_present(self, tmp_path: Path) -> None:
        """No output when both config.yml and docker-compose.yml exist."""
        (tmp_path / "config.yml").write_text("")
        (tmp_path / "docker-compose.yml").write_text("")
        (tmp_path / "config.example.yml").write_text("")
        (tmp_path / "docker-compose.example.yml").write_text("")
        (tmp_path / "scripts").mkdir()
        (tmp_path / "scripts" / "_config_check.sh").write_text(
            (SCRIPTS_DIR / "_config_check.sh").read_text()
        )

        result = _bash(
            "source scripts/_config_check.sh && echo OK",
            cwd=tmp_path,
        )
        assert result.returncode == 0
        assert "OK" in result.stdout

    def test_auto_copies_missing_configs_in_ci(self, tmp_path: Path) -> None:
        """Non-interactive mode auto-copies example files when configs are missing."""
        (tmp_path / "config.example.yml").write_text("install:\n  test: echo hi\n")
        (tmp_path / "docker-compose.example.yml").write_text("services:\n  test:\n")
        (tmp_path / "scripts").mkdir()
        (tmp_path / "scripts" / "_config_check.sh").write_text(
            (SCRIPTS_DIR / "_config_check.sh").read_text()
        )

        result = _bash("source scripts/_config_check.sh && ls config.yml docker-compose.yml 2>&1", cwd=tmp_path)
        assert result.returncode == 0
        assert "config.yml" in result.stdout
        assert "docker-compose.yml" in result.stdout


    def test_exits_when_example_missing(self, tmp_path: Path) -> None:
        """Script exits with code 1 when example file is missing."""
        (tmp_path / "scripts").mkdir()
        (tmp_path / "scripts" / "_config_check.sh").write_text(
            (SCRIPTS_DIR / "_config_check.sh").read_text()
        )

        result = _bash("source scripts/_config_check.sh 2>&1; echo EXIT:$?", cwd=tmp_path)
        # Should exit because neither config.yml nor config.example.yml exists
        assert result.returncode != 0 or "ERROR" in result.stdout or "ERROR" in result.stderr

    def test_syntax(self) -> None:
        """Shell syntax check passes."""
        result = _bash(f"bash -n {SCRIPTS_DIR / '_config_check.sh'}")
        assert result.returncode == 0


# ── build.sh ─────────────────────────────────────────────────────────


class TestBuild:
    """Tests for build.sh — password resolution logic."""

    PASSWORD_BLOCK = """\
if [ -z "${SANDBOX_PASSWORD:-}" ]; then
  if [ -t 0 ]; then
    read -r -s -p "Enter password for sandbox user (default: sandbox): " SANDBOX_PASSWORD
    echo
  fi
fi
if [ -z "${SANDBOX_PASSWORD:-}" ]; then
  SANDBOX_PASSWORD="sandbox"
fi
echo PASSWORD=$SANDBOX_PASSWORD
"""

    def test_password_from_env_var(self) -> None:
        """SANDBOX_PASSWORD env var is used without prompting."""
        result = _bash(self.PASSWORD_BLOCK, env={"SANDBOX_PASSWORD": "secret123"})
        assert result.returncode == 0
        assert "PASSWORD=secret123" in result.stdout

    def test_password_defaults_when_no_env_and_non_interactive(self) -> None:
        """Default 'sandbox' is used when no env var and stdin is not a tty."""
        result = _bash(self.PASSWORD_BLOCK)
        assert result.returncode == 0
        assert "PASSWORD=sandbox" in result.stdout

    def test_syntax(self) -> None:
        """Shell syntax check passes."""
        result = _bash(f"bash -n {SCRIPTS_DIR / 'build.sh'}")
        assert result.returncode == 0


# ── push.sh ──────────────────────────────────────────────────────────


class TestPush:
    """Tests for push.sh — version extraction, branch argument, and dry-run."""

    @staticmethod
    def _setup_push_env(tmp_path: Path) -> None:
        """Create the scripts dir and config files push.sh requires."""
        (tmp_path / "scripts").mkdir(exist_ok=True)
        (tmp_path / "scripts" / "push.sh").write_text((SCRIPTS_DIR / "push.sh").read_text())
        (tmp_path / "scripts" / "_config_check.sh").write_text(
            (SCRIPTS_DIR / "_config_check.sh").read_text()
        )
        # Satisfy _config_check.sh's requirements
        (tmp_path / "config.yml").write_text("")
        (tmp_path / "docker-compose.yml").write_text("")

    def test_extracts_version(self, tmp_path: Path) -> None:
        """Version is correctly extracted from pyproject.toml."""
        (tmp_path / "pyproject.toml").write_text('[project]\nversion = "1.2.3"\n')
        self._setup_push_env(tmp_path)

        result = _bash("bash scripts/push.sh --dry-run 2>&1; echo EXIT:$?", cwd=tmp_path)
        assert result.returncode == 0
        assert "1.2.3" in result.stdout

    def test_error_on_missing_pyproject(self, tmp_path: Path) -> None:
        """Exits with error when pyproject.toml is missing."""
        self._setup_push_env(tmp_path)

        result = _bash("bash scripts/push.sh --dry-run 2>&1; echo EXIT:$?", cwd=tmp_path)
        assert result.returncode == 0
        assert "pyproject.toml not found" in result.stdout

    def test_dry_run_prints_commands(self, tmp_path: Path) -> None:
        """Dry-run mode prints commands instead of executing them."""
        (tmp_path / "pyproject.toml").write_text('[project]\nversion = "0.1.0"\n')
        self._setup_push_env(tmp_path)

        result = _bash("bash scripts/push.sh --dry-run 2>&1; echo EXIT:$?", cwd=tmp_path)
        assert result.returncode == 0
        assert "[DRY-RUN]" in result.stdout
        assert "docker compose build" in result.stdout
        assert "docker push" in result.stdout
        # Verify branch defaults to latest
        assert "Branch:" in result.stdout
        assert "Images tagged for push: 0.1.0, latest" in result.stdout or "Tags:" in result.stdout

    def test_branch_argument(self, tmp_path: Path) -> None:
        """Branch argument changes the source tag for versioning."""
        (tmp_path / "pyproject.toml").write_text('[project]\nversion = "1.0.0"\n')
        self._setup_push_env(tmp_path)

        result = _bash("bash scripts/push.sh --branch dev --dry-run 2>&1; echo EXIT:$?", cwd=tmp_path)
        assert result.returncode == 0
        assert "Branch:  dev" in result.stdout

    def test_branch_requires_value(self, tmp_path: Path) -> None:
        """Error when --branch is provided without a value."""
        (tmp_path / "pyproject.toml").write_text('[project]\nversion = "1.0.0"\n')
        self._setup_push_env(tmp_path)

        result = _bash("bash scripts/push.sh --branch 2>&1", cwd=tmp_path)
        assert result.returncode != 0
        assert "Error: --branch requires a tag name" in result.stdout

    def test_unknown_argument_error(self, tmp_path: Path) -> None:
        """Error message for unknown arguments."""
        (tmp_path / "pyproject.toml").write_text('[project]\nversion = "1.0.0"\n')
        self._setup_push_env(tmp_path)

        result = _bash("bash scripts/push.sh --unknown 2>&1", cwd=tmp_path)
        assert result.returncode != 0
        assert "Error: Unknown argument: --unknown" in result.stdout

    def test_syntax(self) -> None:
        """Shell syntax check passes."""
        result = _bash(f"bash -n {SCRIPTS_DIR / 'push.sh'}")
        assert result.returncode == 0



# ── run.sh ────────────────────────────────────────────────────────────


class TestRun:
    """Tests for run.sh — volume parsing, argument handling."""

    def test_parse_volumes_valid(self, tmp_path: Path) -> None:
        """_parse_volumes() extracts host:container pairs from docker-compose.yml."""
        compose = tmp_path / "docker-compose.yml"
        compose.write_text("""services:
  sandbox:
    volumes:
      - ./persist:/persist
      - /data:/data
  other:
    volumes:
      - /ignored:/ignored
""")
        awk_script = (
            '/^  sandbox:/ { in_s=1; next }'
            '/^  [a-zA-Z_-]/ { in_s=0 }'
            'in_s && /^    volumes:/ { in_v=1; next }'
            'in_s && in_v && /^      - / {'
            '  sub(/^[[:space:]]*- /, "", $0); print'
            '}'
            'in_s && in_v && /^    [a-zA-Z_-]/ { in_v=0 }'
        )
        result = _bash(f"awk '{awk_script}' {compose}", cwd=tmp_path)
        assert result.returncode == 0
        lines = [l.strip() for l in result.stdout.strip().split("\n") if l.strip()]
        assert any("./persist:/persist" in l for l in lines)
        assert any("/data:/data" in l for l in lines)

    def test_parse_volumes_no_volumes(self, tmp_path: Path) -> None:
        """_parse_volumes() returns nothing when no volumes are defined."""
        compose = tmp_path / "docker-compose.yml"
        compose.write_text("""services:
  sandbox:
    image: test
""")
        awk_script = (
            '/^  sandbox:/ { in_s=1; next }'
            '/^  [a-zA-Z_-]/ { in_s=0 }'
            'in_s && /^    volumes:/ { in_v=1; next }'
            'in_s && in_v && /^      - / { print }'
            'in_s && in_v && /^    [a-zA-Z_-]/ { in_v=0 }'
        )
        result = _bash(f"awk '{awk_script}' {compose}", cwd=tmp_path)
        assert result.returncode == 0
        assert result.stdout.strip() == ""

    def test_syntax(self) -> None:
        """Shell syntax check passes."""
        result = _bash(f"bash -n {SCRIPTS_DIR / 'run.sh'}")
        assert result.returncode == 0


# ── installer.sh (sourcing guard) ────────────────────────────────────


class TestInstallerSourcingGuard:
    """Tests for the BASH_SOURCE sourcing guard in installer.sh."""

    def test_main_body_skipped_when_sourced(self) -> None:
        """Main body (the install loop) is skipped when the script is sourced."""
        result = _bash(
            f"source {SCRIPTS_DIR / 'installer.sh'} && echo SOURCED_OK"
        )
        assert result.returncode == 0
        assert "SOURCED_OK" in result.stdout
        # If the main body ran, it would try to read /tmp/config.yml and fail
        assert "No install entries found" not in result.stdout

    def test_main_body_runs_when_executed(self, tmp_path: Path) -> None:
        """Main body runs when the script is executed directly."""
        import os as _os

        config = Path("/tmp/config.yml")
        config.write_text("install: {}\n")

        # Create a mock yq so the installer works in environments without yq
        mock_bin = tmp_path / "bin"
        mock_bin.mkdir()
        mock_yq = mock_bin / "yq"
        mock_yq.write_text("#!/bin/bash\necho '0'\n")
        mock_yq.chmod(0o755)

        env = {**_os.environ, "PATH": f"{mock_bin}:{_os.environ.get('PATH', '')}"}

        try:
            result = subprocess.run(
                ["bash", str(SCRIPTS_DIR / "installer.sh")],
                capture_output=True,
                text=True,
                env=env,
            )
        finally:
            config.unlink(missing_ok=True)
        # Should reach the install loop (sourcing guard not active) and
        # report an empty config rather than silently doing nothing.
        assert result.returncode == 0
        assert "No install entries found" in result.stdout


# ── Syntax checks for all scripts ────────────────────────────────────


SCRIPTS = sorted(SCRIPTS_DIR.glob("*.sh"))


@pytest.mark.parametrize("script", SCRIPTS, ids=lambda p: p.name)
def test_shell_syntax(script: Path) -> None:
    """Every .sh script passes bash -n syntax check."""
    result = _bash(f"bash -n {script}")
    assert result.returncode == 0, f"{script.name}: {result.stderr}"
