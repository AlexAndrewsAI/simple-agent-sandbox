# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- ruff lint and format pre-commit hooks
- pymarkdownlnt markdown linting pre-commit hook
- Comprehensive ruff configuration in pyproject.toml
- `.pymarkdown.json` for markdown linting config
- `!.env.example` and `!.pymarkdown.json` to .gitignore whitelist
- Improved AGENTS.md with staging protocol, code review mode, and file maintenance directives
- CHANGELOG.md

### Changed

- Updated dev dependencies: added ruff, pymarkdownlnt, and shellcheck-py

## [0.1.0] - 2026-06-23

### Added

- Config-driven installation system via `config.yml`
- Support for multiple AI agents: Hermes, Cline, Devin CLI, OpenCode
- `installer.sh` with graceful failure handling
- Docker Compose setup with UID/GID passthrough
- Persistent state via `./persist` mount
- Shell wrapper scripts (Bash and PowerShell)
- CI pipeline: pre-commit, config validation, installer dry-run, Docker build
- `.pre-commit-config.yaml` with shellcheck

## [0.0.0] - 2026-06-20

### Added

- Basic functionality with Hermes agent only
- Dockerfile based on `python:3-trixie`

[Unreleased]: https://github.com/AlexAndrewsAI/simple-agent-sandbox/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/AlexAndrewsAI/simple-agent-sandbox/releases/tag/v0.1.0
[0.0.0]: https://github.com/AlexAndrewsAI/simple-agent-sandbox/releases/tag/v0.0.0
