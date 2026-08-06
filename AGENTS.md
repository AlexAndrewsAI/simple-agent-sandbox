# Agent Instructions: simple-agent-sandbox

## Quick Start

1. **User Configs:** Do not remove the user's files config.yml and docker-compose.yml unless explicitly asked to
2. **Edit:** Uncomment/adjust mounts in `docker-compose.yml` and tools in `config.yml`
3. **Build:** `docker compose build`
4. **Run:** `docker compose run --rm sandbox`

## Tech Stack

| Component | Tool |
|-----------|------|
| Container Runtime | Docker & Docker Compose |
| Base Image | python:3-trixie |
| Config Format | YAML (read via yq) |
| Shell | Bash |
| Package Manager | pip (uv), npm (Cline), curl-based installers |
| AI Agents | hermes, devin, cline, opencode |
| Local LLM Runtime | ollama |
| Terminal IDE | fresh |
| Markdown Lint | pymarkdownlnt |
| Shell Script Lint | shellcheck |
| Docker Lint | hadolint |
| Git Hooks | prek |

## Project Structure

```text
simple-agent-sandbox/
  ├── .github/
  │   └── workflows/
  │       └── ci.yml                (CI pipeline for linting and validation)
  ├── Dockerfile                    (Container build instructions)
  ├── .dockerignore                 (Docker build context exclusions)
  ├── .hadolint.yaml                (Hadolint configuration)
  ├── docker-compose.example.yml    (Template)
  ├── docker-compose.yml            (Real compose file — gitignored)
  ├── config.example.yml            (Template)
  ├── config.yml                    (Real config — gitignored)
  ├── scripts/
  │   ├── installer.sh              (Reads config.yml, runs install commands)
  │   ├── run.sh / win-run.ps1      (Start interactive sandbox shell)
  │   └── build.sh / win-build.ps1  (Build the Docker image)
  ├── persist/                      (Mounted volume for persistent state, gitignored)
  ├── AGENTS.md                     (Agent-specific instructions)
  ├── CHANGELOG.md                  (Project changelog)
  └── README.md
```

## Essential Directives

### Configuration Management

- **Real files are gitignored:** Both `config.yml` and `docker-compose.yml` are real config files that live in `.gitignore`. The `*.example.*` files are the tracked templates.
- **Adding/Removing Tools:** Edit `config.yml` — add/comment out entries under `install:`
- **Apt Packages:** Edit `config.yml` — add/remove packages under `apt:` (installed during Docker build as root)
- **Install Format:** Each key under `install:` maps to a shell command string executed by `scripts/installer.sh`
- **Config-Driven:** All tool installation is driven by `config.yml`; do not hardcode installs in the Dockerfile
  - **Exception — `uv`:** The `uv` tool manager is installed via `pip` in the Dockerfile (line 47) because the installer itself depends on it to manage Python dev tools (pytest, ruff, mypy). Do not add a `uv` install entry in `config.yml`.
- **Mounts in Compose:** Volume mounts are defined in `docker-compose.yml`, not parsed from config.yml by helper scripts
- **Options:** `options:` in `config.yml` controls run script behavior:
  - `auto_cd_mount` (default: `true`): Auto-cd to the matching path inside the container when CWD is within a mounted volume
  - `automount_cwd` (default: `false`): When CWD is NOT within any mounted volume, mount it as `/cwd` for this run only. Also triggers auto-cd to `/cwd` if `auto_cd_mount` is enabled
  - `no_internet` (default: `false`): Disable internet access at runtime by merging a temporary compose override setting `network_mode: none` (build unaffected). Overridden by the `-n|--no-internet` CLI flag on `run.sh` / `win-run.ps1`

### Docker Workflow

- **Real compose over helpers:** The source of truth for volumes, env, and service config is `docker-compose.yml`. The helper scripts (`run.sh`, `build.sh`) are thin wrappers around `docker compose`.
- **Rebuild After Config Changes:** If `config.yml` changes, rebuild with `docker compose build`
- **Container User:** Container runs as the `sandbox` user (non-root) with sudo access (password required)
- **Persistent State:** All persistent data lives in `./persist` on the host, mounted at `/persist` in the container
- **No State in Image:** Do not store credentials, keys, or session data in the Docker image layers

### Operational Constraints

- **No Interactive Prompts:** Mock or bypass any interactive commands in install scripts
- **No Git Operations:** Don't stage/commit unless explicitly requested
- **Staging & Commit Protocol:** When you have completed work and updated files, stage the changes with `git add` and then display a suggested commit message for the user's review. DO NOT actually commit.
- **Code Review Mode:** Analyze only; record findings in `./REVIEW.md` without making modifications.
- **Keep Instructions Current:** Update "Tech Stack," "Project Structure," and "Workflow Commands" if the Dockerfile, config format, or core tooling changes

### File Maintenance

- **Keep Instructions Current:** Update "Tech Stack," "Project Structure," and "Workflow Commands" if the Dockerfile, config format, or core tooling changes
- **Pre-commit Config:** Keep `.pre-commit-config.yaml` in sync with CI workflow when tool requirements change

## Workflow Commands

```bash
cp config.example.yml config.yml                # Create real config from template
cp docker-compose.example.yml docker-compose.yml # Create real compose from template
docker compose build                             # Rebuild the sandbox image
docker compose run --rm sandbox                  # Interactive shell in sandbox
docker compose up -d && docker compose exec sandbox bash  # Persistent session
uv run prek install                              # Install git hooks
uv run prek run --all-files                      # Run all hooks
```
