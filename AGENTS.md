# Agent Instructions: simple-agent-sandbox

## Quick Start
1. **Copy Configs:** Copy the example files and edit to taste:
   ```bash
   cp config.example.yml config.yml
   cp docker-compose.example.yml docker-compose.yml
   ```
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
| Package Manager | npm (for Cline), curl-based installers |

## Project Structure
```
simple-agent-sandbox/
  ├── Dockerfile                    (Container build instructions)
  ├── docker-compose.example.yml    (Template — copy to docker-compose.yml)
  ├── docker-compose.yml            (Real compose file — gitignored)
  ├── config.example.yml            (Template — copy to config.yml)
  ├── config.yml                    (Real config — gitignored)
  ├── scripts/
  │   ├── installer.sh              (Reads config.yml, runs install commands)
  │   ├── run.sh / run.ps1          (Start interactive sandbox shell)
  │   └── build.sh / build.ps1      (Build the Docker image)
  ├── persist/                      (Mounted volume for persistent state, gitignored)
  └── README.md
```

## Essential Directives

### Configuration Management
- **Real files are gitignored:** Both `config.yml` and `docker-compose.yml` are real config files that live in `.gitignore`. The `*.example.*` files are the tracked templates.
- **Adding/Removing Tools:** Edit `config.yml` — add/comment out entries under `install:`
- **Install Format:** Each key under `install:` maps to a shell command string executed by `scripts/installer.sh`
- **Config-Driven:** All tool installation is driven by `config.yml`; do not hardcode installs in the Dockerfile
- **Mounts in Compose:** Volume mounts are defined in `docker-compose.yml`, not parsed from config.yml by helper scripts

### Docker Workflow
- **Real compose over helpers:** The source of truth for volumes, env, and service config is `docker-compose.yml`. The helper scripts (`run.sh`, `build.sh`) are thin wrappers around `docker compose`.
- **Rebuild After Config Changes:** If `config.yml` changes, rebuild with `docker compose build`
- **Persistent State:** All persistent data lives in `./persist` on the host, mounted at `/persist` in the container
- **No State in Image:** Do not store credentials, keys, or session data in the Docker image layers

### Operational Constraints
- **No Interactive Prompts:** Mock or bypass any interactive commands in install scripts
- **No Git Operations:** Don't stage/commit unless explicitly requested
- **Keep Instructions Current:** Update "Tech Stack," "Project Structure," and "Workflow Commands" if the Dockerfile, config format, or core tooling changes

## Workflow Commands
```bash
cp config.example.yml config.yml                # Create real config from template
cp docker-compose.example.yml docker-compose.yml # Create real compose from template
docker compose build                             # Rebuild the sandbox image
docker compose run --rm sandbox                  # Interactive shell in sandbox
docker compose up -d && docker compose exec sandbox bash  # Persistent session
```
