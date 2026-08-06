"""Tests for the PowerShell scripts in scripts/.

Covers the Windows-side wrappers (win-run.ps1, win-build.ps1,
win-cd-mount.ps1, _config_check.ps1) with static structure checks plus
functional tests executed under PowerShell when `pwsh` is available.
"""

from __future__ import annotations

import re
import shutil
from pathlib import Path

import pytest
from conftest import (
    SCRIPTS_DIR,
    docker_args,
    make_project,
    mock_env,
    run_pwsh,
)

PS1_SCRIPTS = sorted(p.name for p in SCRIPTS_DIR.glob("*.ps1"))

COMPOSE = """\
services:
  sandbox:
    image: test
    volumes:
      - ./persist:/persist
      - ./mdata:/data
"""

CONFIG_TEMPLATE = """\
options:
  auto_cd_mount: {auto_cd}
  automount_cwd: {automount}
  no_internet: false
"""


def _config(auto_cd: bool = True, automount: bool = False) -> str:
    return CONFIG_TEMPLATE.format(
        auto_cd="true" if auto_cd else "false",
        automount="true" if automount else "false",
    )


# ── Static structure checks (always run) ────────────────────────────


class TestScriptsPresent:
    @pytest.mark.parametrize(
        "name",
        ["win-run.ps1", "win-build.ps1", "win-cd-mount.ps1", "_config_check.ps1"],
    )
    def test_script_exists(self, name: str) -> None:
        assert (SCRIPTS_DIR / name).exists()

    def test_win_run_references_siblings(self) -> None:
        """win-run.ps1 dot-sources _config_check.ps1 and calls win-cd-mount.ps1."""
        src = (SCRIPTS_DIR / "win-run.ps1").read_text()
        assert "_config_check.ps1" in src
        assert "win-cd-mount.ps1" in src

    def test_no_internet_override_present(self) -> None:
        """win-run.ps1 must emit a network_mode: none compose override."""
        src = (SCRIPTS_DIR / "win-run.ps1").read_text()
        assert "network_mode: none" in src


class TestParamBlockPlacement:
    """Regression: param() must be the first executable statement.

    A function definition before param() made PowerShell treat `param` as a
    command, silently disabling argument binding (win-cd-mount.ps1).
    """

    @pytest.mark.parametrize("script", ["win-run.ps1", "win-cd-mount.ps1"])
    def test_param_is_first_statement(self, script: str) -> None:
        lines = [
            line.strip()
            for line in (SCRIPTS_DIR / script).read_text().splitlines()
            if line.strip() and not line.strip().startswith("#")
        ]
        assert lines[0].startswith("param("), (
            f"{script}: param() must be the first statement"
        )


class TestNoParamShadowing:
    """Switch parameters must not be reassigned.

    PowerShell variable names are case-insensitive, so `$noInternet = $false`
    silently shadowed the `$NoInternet` switch — making the `-n` flag a no-op.
    """

    @staticmethod
    def _param_names(src: str) -> list[str]:
        """Names declared in the first param() block (handles nested parens
        such as `[Alias("a")]`)."""
        start = src.index("param(") + len("param(")
        depth = 1
        i = start
        while i < len(src) and depth > 0:
            if src[i] == "(":
                depth += 1
            elif src[i] == ")":
                depth -= 1
            i += 1
        block = src[start : i - 1]
        return re.findall(r"\$(\w+)", block)

    @pytest.mark.parametrize("script", ["win-run.ps1", "win-cd-mount.ps1"])
    def test_params_not_reassigned(self, script: str) -> None:
        src = (SCRIPTS_DIR / script).read_text()
        params = self._param_names(src)
        assert params, f"no parameters declared in {script}"
        for name in params:
            assert not re.search(
                r"\$" + re.escape(name) + r"\s*=", src, re.IGNORECASE
            ), f"{script}: `{name}` parameter is reassigned (case-insensitive shadowing)"


# ── Functional tests (require pwsh) ─────────────────────────────────


class TestPwshSyntax:
    """Every .ps1 file must parse without errors under PowerShell."""

    @pytest.mark.parametrize("script", PS1_SCRIPTS)
    def test_parses_without_errors(self, pwsh: str, script: str) -> None:
        path = SCRIPTS_DIR / script
        snippet = (
            "$errs = $null; "
            f"[void][System.Management.Automation.Language.Parser]::ParseFile("
            f"'{path}', [ref]$null, [ref]$errs); "
            "if ($errs.Count -gt 0) { $errs | ForEach-Object { $_.Message }; exit 1 }"
        )
        result = run_pwsh(["-Command", snippet], SCRIPTS_DIR.parent)
        assert result.returncode == 0, result.stdout + result.stderr


class TestWinCdMount:
    """win-cd-mount.ps1 mount detection and automount logic (under pwsh)."""

    @staticmethod
    def _lines(result) -> list[str]:
        assert result.returncode == 0, result.stderr
        return [line for line in result.stdout.splitlines() if line.strip()]

    @classmethod
    def _run(
        cls,
        project: Path,
        cwd: Path,
        config_path: Path | None = None,
        compose_path: Path | None = None,
        force: bool = False,
    ) -> list[str]:
        args = [
            "-File",
            str(project / "scripts" / "win-cd-mount.ps1"),
            "-ProjectRoot",
            str(project),
            "-ConfigPath",
            str(config_path or project / "config.yml"),
            "-ComposePath",
            str(compose_path or project / "docker-compose.yml"),
        ]
        if force:
            args.append("-ForceAutomount")
        return cls._lines(run_pwsh(args, cwd=cwd))

    def test_inside_mount_subdir(self, pwsh: str, tmp_path: Path) -> None:
        project = make_project(tmp_path, ["win-cd-mount.ps1"], _config(), COMPOSE)
        sub = project / "persist" / "sub"
        sub.mkdir(parents=True)
        assert self._run(project, cwd=sub) == ["/persist/sub"]

    def test_at_mount_root(self, pwsh: str, tmp_path: Path) -> None:
        project = make_project(tmp_path, ["win-cd-mount.ps1"], _config(), COMPOSE)
        project.joinpath("persist").mkdir()
        assert self._run(project, cwd=project / "persist") == ["/persist"]

    def test_second_mount(self, pwsh: str, tmp_path: Path) -> None:
        """A multi-volume compose is handled (regression: `.ToString()` on the
        volume array returned 'System.Object[]', breaking detection)."""
        project = make_project(tmp_path, ["win-cd-mount.ps1"], _config(), COMPOSE)
        project.joinpath("mdata").mkdir()
        assert self._run(project, cwd=project / "mdata") == ["/data"]

    def test_outside_mounts_automount_off(self, pwsh: str, tmp_path: Path) -> None:
        project = make_project(tmp_path, ["win-cd-mount.ps1"], _config(), COMPOSE)
        work = project / "work"
        work.mkdir()
        assert self._run(project, cwd=work) == []

    def test_outside_mounts_automount_on(self, pwsh: str, tmp_path: Path) -> None:
        project = make_project(
            tmp_path, ["win-cd-mount.ps1"], _config(automount=True), COMPOSE
        )
        work = project / "work"
        work.mkdir()
        lines = self._run(project, cwd=work)
        assert len(lines) == 2
        assert lines[0] == "/cwd"
        assert lines[1].startswith("-v ")
        assert lines[1].endswith(f"{work}:/cwd")

    def test_force_automount(self, pwsh: str, tmp_path: Path) -> None:
        project = make_project(tmp_path, ["win-cd-mount.ps1"], _config(), COMPOSE)
        work = project / "work"
        work.mkdir()
        lines = self._run(project, cwd=work, force=True)
        assert lines[0] == "/cwd"
        assert lines[1].endswith(f"{work}:/cwd")

    def test_missing_config_defaults(self, pwsh: str, tmp_path: Path) -> None:
        """Missing/unreadable config falls back to automount_cwd=false
        (matching run.sh) — must NOT auto-mount CWD."""
        project = make_project(tmp_path, ["win-cd-mount.ps1"], _config(), COMPOSE)
        work = project / "work"
        work.mkdir()
        lines = self._run(
            project,
            cwd=work,
            config_path=project / "does-not-exist.yml",
            compose_path=project / "does-not-exist-compose.yml",
        )
        assert lines == []


class TestWinRunInvocation:
    """win-run.ps1 forwards auto-cd/automount results to docker (under pwsh)."""

    def test_automount_passes_volume_and_cwd(
        self, pwsh: str, tmp_path: Path, mock_docker: Path
    ) -> None:
        project = make_project(
            tmp_path,
            ["win-run.ps1", "win-cd-mount.ps1", "_config_check.ps1"],
            _config(automount=True),
            COMPOSE,
        )
        work = project / "work"
        work.mkdir()
        script = project / "scripts" / "win-run.ps1"
        result = run_pwsh(
            ["-File", str(script)], cwd=work, env_extra=mock_env(mock_docker)
        )
        assert result.returncode == 0, result.stderr
        args = docker_args(mock_docker)
        assert "compose" in args and "run" in args
        assert "-v" in args
        vol = args[args.index("-v") + 1]
        assert vol.endswith(f"{work}:/cwd")
        assert "cd '/cwd' && exec bash" in " ".join(args)

    def test_container_cwd_inside_mount(
        self, pwsh: str, tmp_path: Path, mock_docker: Path
    ) -> None:
        project = make_project(
            tmp_path,
            ["win-run.ps1", "win-cd-mount.ps1", "_config_check.ps1"],
            _config(),
            COMPOSE,
        )
        sub = project / "persist" / "sub"
        sub.mkdir(parents=True)
        script = project / "scripts" / "win-run.ps1"
        result = run_pwsh(
            ["-File", str(script)], cwd=sub, env_extra=mock_env(mock_docker)
        )
        assert result.returncode == 0, result.stderr
        args = docker_args(mock_docker)
        assert "cd '/persist/sub' && exec bash" in " ".join(args)
        assert "-v" not in args


class TestWinBuildInvocation:
    """win-build.ps1 forwards build args and the sandbox password to docker."""

    def test_passes_build_args(self, pwsh: str, tmp_path: Path, mock_docker: Path) -> None:
        project = make_project(
            tmp_path,
            ["win-build.ps1", "_config_check.ps1"],
            "options: {}\n",
            COMPOSE,
        )
        result = run_pwsh(
            ["-File", "scripts/win-build.ps1"], project, mock_env(mock_docker)
        )
        assert result.returncode == 0, result.stderr
        args = docker_args(mock_docker)
        assert "compose" in args and "build" in args
        assert "--progress=plain" in args
        assert any(a.startswith("SANDBOX_PASSWORD=") for a in args)


class TestConfigCheckPs1:
    """_config_check.ps1 parity with the .sh variant."""

    def test_silent_when_configs_present(self, pwsh: str, tmp_path: Path) -> None:
        project = make_project(
            tmp_path, ["_config_check.ps1"], "options: {}\n", "services: {}\n"
        )
        result = run_pwsh(
            ["-Command", ". './scripts/_config_check.ps1'; Write-Output 'OK'"], project
        )
        assert result.returncode == 0, result.stderr
        assert "OK" in result.stdout

    def test_auto_copies_missing_configs(self, pwsh: str, tmp_path: Path) -> None:
        project = tmp_path
        (project / "scripts").mkdir()
        shutil.copy(
            SCRIPTS_DIR / "_config_check.ps1", project / "scripts" / "_config_check.ps1"
        )
        (project / "config.example.yml").write_text("options: {}\n")
        (project / "docker-compose.example.yml").write_text("services: {}\n")
        result = run_pwsh(
            [
                "-Command",
                (
                    ". './scripts/_config_check.ps1'; "
                    "(Test-Path './config.yml'); (Test-Path './docker-compose.yml')"
                ),
            ],
            project,
        )
        assert result.returncode == 0, result.stderr
        assert (project / "config.yml").exists()
        assert (project / "docker-compose.yml").exists()
