# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.1] - 2026-07-12 - "test coverage for Dockerfile, PowerShell scripts, and no-internet runtime"

### Added

- `tests/test_dockerfile.py`: hadolint compliance for the Dockerfile (mirrors the pre-commit hook)
- `tests/test_windows_scripts.py`: static structure checks plus functional tests for `win-run.ps1`, `win-build.ps1`, `win-cd-mount.ps1`, and `_config_check.ps1` (run under `pwsh`, skipped when unavailable)
- `tests/test_no_internet.py`: no-internet runtime tests driving `run.sh` and `win-run.ps1` against a mock `docker`, including compose-override merge semantics
- Mock-`docker` invocation tests for auto-cd/automount in `run.sh` (`tests/test_scripts.py`)
- CI: installs `yq` and `hadolint` in the test job so the new tests run in CI

### Fixed

- `win-cd-mount.ps1`: `param()` was not the first statement, so arguments were silently ignored (auto-cd/automount never bound)
- `win-cd-mount.ps1`: multi-volume compose parsing broke (`.ToString()` on the volume array returned `System.Object[]`)
- `win-cd-mount.ps1`: missing/unreadable config now defaults `automount_cwd` to `false`, matching `run.sh`
- `win-run.ps1`: `-n/--no-internet` flag was a no-op due to case-insensitive `$noInternet`/`$NoInternet` variable shadowing
- PowerShell scripts: use `Join-Path` for path construction so they work on both Windows and Linux `pwsh`

## [0.2.0] - 2026-07-12 - #10 "initial run in cwd, and add pytest"

### Added

- pytest framework with test suites for installer and scripts
- pip-audit, hatchling build config, `.dockerignore`/`.editorconfig`/`.gitattributes`
- Auto-cd into mounted subdirectories (Bash and PowerShell) with `win-cd-mount.ps1`
- Mount CWD option for non-mounted directories; `GDU` and `lazygit` example installs
- REVIEW.md code review report

### Changed

- CI pipeline expanded with additional test and lint steps
- `installer.sh` error handling and unicode cleanup improved
- Run/build scripts (`.sh` / `.ps1`) enhanced with auto-cd, arg passthrough, and push workflow
- `config.example.yml` and `docker-compose.example.yml` updated with new options/paths

### Fixed

- Path fixes in `run.sh` and `win-run.ps1`

## [0.1.1] - 2026-07-12 - #9 "add opencode functionality"

### Added

- OpenCode CLI support
- CHANGELOG.md
- prek pre-commit: added pymarkdownlnt, hadolint
- Improved AGENTS.md with staging protocol, code review mode, and file maintenance directives

### Fixed

- Moved `ENV PATH` before `RUN installer.sh` so `uv` is on PATH during tool installation (fixes `uv: command not found` build error)
- Removed redundant `uv` entry from config.example.yml (installed via pip in Dockerfile)

### Changed

- Updated dev dependencies: added ruff, pymarkdownlnt, and shellcheck-py

## [0.1.0] - 2026-06-23 - #6 "Incorporate code quality improvements and sandbox sudo from big-sandbox"

### Added

- Config-driven installation system via `config.yml`
- Support for multiple AI agents: Hermes, Cline, Devin CLI, OpenCode
- `installer.sh` with graceful failure handling
- Docker Compose setup with UID/GID passthrough
- Persistent state via `./persist` mount
- Shell wrapper scripts (Bash and PowerShell)
- CI pipeline: pre-commit, config validation, installer dry-run, Docker build
- `.pre-commit-config.yaml` with shellcheck

## 0.0.0 - 2026-06-20

### Added

- Basic functionality with Hermes agent only
- Dockerfile based on `python:3-trixie`

[0.2.0]: https://github.com/AlexAndrewsAI/simple-agent-sandbox/compare/v0.1.1...v0.2.0
[0.1.1]: https://github.com/AlexAndrewsAI/simple-agent-sandbox/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/AlexAndrewsAI/simple-agent-sandbox/releases/tag/v0.1.0
[0.0.0]: https://github.com/AlexAndrewsAI/simple-agent-sandbox/releases/tag/v0.0.0
