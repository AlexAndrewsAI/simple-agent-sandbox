# Agent Instructions: simple-agent-sandbox

## Quick Start
1. **Build:** Run `docker compose build` to build the sandbox image
2. **Run:** Use `docker compose run --rm sandbox` for an interactive shell
3. **Config:** Edit `config.yml` to enable/disable agent tools

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
  ├── Dockerfile              (Container build instructions)
  ├── docker-compose.yml      (Service definition, volumes, env)
  ├── config.yml              (Tool install list + volume mounts)
  ├── config.example.yml      (Example config template)
  ├── scripts/
  │   └── installer.sh        (Reads config.yml, runs install commands)
  ├── persist/                (Mounted volume for persistent state, gitignored)
  └── README.md
```

## Essential Directives

### Configuration Management
- **Adding/Removing Tools:** Edit `config.yml` — add/comment out entries under `install:`
- **Install Format:** Each key under `install:` maps to a shell command string executed by `scripts/installer.sh`
- **Config-Driven:** All tool installation is driven by `config.yml`; do not hardcode installs in the Dockerfile

### Docker Workflow
- **Rebuild After Config Changes:** If `config.yml` changes, rebuild with `docker compose build`
- **Persistent State:** All persistent data lives in `./persist` on the host, mounted at `/persist` in the container
- **No State in Image:** Do not store credentials, keys, or session data in the Docker image layers

### Operational Constraints
- **No Interactive Prompts:** Mock or bypass any interactive commands in install scripts
- **No Git Operations:** Don't stage/commit unless explicitly requested
- **Keep Instructions Current:** Update "Tech Stack," "Project Structure," and "Workflow Commands" if the Dockerfile, config format, or core tooling changes

## Workflow Commands
```bash
docker compose build                        # Rebuild the sandbox image
docker compose run --rm sandbox             # Interactive shell in sandbox
docker compose up -d && docker compose exec sandbox bash  # Persistent session
```
