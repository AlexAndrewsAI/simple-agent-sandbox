# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2026-07-12 - #10 "initial run in cwd, and add pytest"

### Added

- pytest test framework with `test_installer.py` and `test_scripts.py` test suites
- pip-audit for dependency vulnerability scanning
- Build system configuration via hatchling
- `.dockerignore`, `.editorconfig`, `.gitattributes`
- `win-cd-mount.ps1` for Windows auto-cd into mounted volumes
- Auto-cd into mounted subdirectories (Bash and PowerShell)
- Mount CWD option for running sandbox in non-mounted directories
- `GDU` and `lazygit` added to example installs
- REVIEW.md code review report

### Changed

- Updated CI pipeline with expanded test and lint steps
- Improved `installer.sh` with better error handling and unicode cleanup
- Improved `run.sh` with auto-cd mount support
- Improved `win-run.ps1` with auto-cd mount support
- Improved `win-build.ps1` with build arg passthrough
- Improved `push.sh` with expanded push workflow
- Updated `config.example.yml` with new options
- Updated `docker-compose.example.yml` path
- Updated Dockerfile

### Fixed

- Path fixes in `run.sh` and `win-run.ps1`
- Build arg passthrough in `win-build.ps1`

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
