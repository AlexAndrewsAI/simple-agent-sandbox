# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.3.0] - 2026-08-05

### Added

- `ollama` local LLM runtime and `fresh` terminal IDE
- No-internet runtime mode via `options.no_internet` in `config.yml` or the `-n/--no-internet` flag on `run.sh`/`win-run.ps1`
- `-a/--automount-cwd` CLI flag to force mounting the current directory as `/cwd`
- Resume aliases (`cline-resume`, `hermes-resume`, `devin-resume`, `opencode-resume`) in the sandbox shell
- `zstd` in the base image packages

### Fixed

- `win-run.ps1`: `-n/--no-internet` flag was a no-op due to variable shadowing
- `win-cd-mount.ps1`: auto-cd/automount arguments were silently ignored, and multi-volume compose parsing broke
- PowerShell scripts: `Join-Path` used for paths so they work on Windows and Linux `pwsh`

### Changed

- Tools are now installed as root during the build so sudo-requiring installers (like `ollama`) work
- `config.example.yml`: `cline` installed globally, `automount_cwd` defaults to `false`, new `no_internet` option
- Docker build arg renamed to `SANDBOX_PW` (legacy `SANDBOX_PASSWORD` still accepted)
- `pyproject.toml` version bumped to `0.3.0`

## [0.2.0] - 2026-07-12 - #10 "initial run in cwd, and add pytest"

> Note: pyproject.toml was intended to be bumped to 0.2.0 with this release, but the version field was mistakenly left at 0.1.1.

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

[0.3.0]: https://github.com/AlexAndrewsAI/simple-agent-sandbox/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/AlexAndrewsAI/simple-agent-sandbox/compare/v0.1.1...v0.2.0
[0.1.1]: https://github.com/AlexAndrewsAI/simple-agent-sandbox/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/AlexAndrewsAI/simple-agent-sandbox/releases/tag/v0.1.0
[0.0.0]: https://github.com/AlexAndrewsAI/simple-agent-sandbox/releases/tag/v0.0.0
