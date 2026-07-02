# Simple Agent Sandbox

A Docker-based sandbox environment for running AI agents. Mounts `./persist` directory as run-time `HOME` so agents' states are durable across container restart.

## Quick Start
1. **Copy Configs:** Copy the example files (build/run scripts will prompt if missing):
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
- **Apt Packages:** Edit `config.yml` — add/remove packages under `apt:` (installed during Docker build as root)
- **Install Format:** Each key under `install:` maps to a shell command string executed by `scripts/installer.sh`
- **Config-Driven:** All tool installation is driven by `config.yml`; do not hardcode installs in the Dockerfile
- **Mounts in Compose:** Volume mounts are defined in `docker-compose.yml`, not parsed from config.yml by helper scripts

### Docker Workflow
- **Real compose over helpers:** The source of truth for volumes, env, and service config is `docker-compose.yml`. The helper scripts (`run.sh`, `build.sh`) are thin wrappers around `docker compose`.
- **Rebuild After Config Changes:** If `config.yml` changes, rebuild with `docker compose build`
- **Container User:** Container runs as the `sandbox` user (non-root) with password-less sudo access
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

## Agents

All CLIs listed below offer usable free plans.

| Agent | Description | Notes |
|-------|-------------|-------|
| [Hermes Agent](https://hermes-agent.nousresearch.com/) | Free models via API with [OpenRouter](https://openrouter.ai) or [Nvidia](https://build.nvidia.com) | Install is large and takes a while |
| [Cline](https://cline.bot/) | Offers a free plan with decent LLM models | Heavy install |
| [Devin CLI](https://cli.devin.ai/) | Offers free plan with decent LLM model | Lightweight install |

## Data Persistence

The `./persist` directory on the host is mounted into the container at `/persist`. This directory is used to store:

- Home directory and tool state (`/persist/.local/`)
- Shell history (`/persist/.bash_history`)

Changes made inside `/persist` in the container are persisted on the host and survive container restarts.

### Personal Bashrc

If you want personal shell customizations (aliases, functions, env vars) that won't be committed to git, put them in `/persist/bashrc-extra`. The sourced `.bashrc` sources this file at startup if it exists. This file is gitignored, so it stays local to your environment.

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/)
- [Docker Compose](https://docs.docker.com/compose/install/)

## Quick Pull (Pre-built Image)

A pre-built image is available on Docker Hub. If you don't need to customize the build, you can skip the clone-and-build workflow entirely:

```bash
docker pull alexandrewsai/simple-agent-sandbox:latest
```

Then run it with your own config and persist directory:

```bash
docker run -it --rm \
  -v $(pwd)/config.yml:/app/config.yml \
  -v $(pwd)/persist:/persist \
  -e HOME=/persist \
  alexandrewsai/simple-agent-sandbox:latest
```

To use `docker-compose` with the pre-built image, set the `IMAGE` environment variable or edit `docker-compose.yml` to reference `alexandrewsai/simple-agent-sandbox:latest` instead of building locally:

```bash
IMAGE=alexandrewsai/simple-agent-sandbox:latest docker compose run --rm sandbox
```

## Environment Variables

| Variable | Value | Description |
|----------|-------|-------------|
| `HOME` | `/persist` | Sets the home directory inside the container |
| `PATH` | `/persist/.local/bin:$PATH` | Ensures installed binaries are available |

## Troubleshooting

### Cline

- cline is buggy in setup in this environment, but it will work
- don't run from root '/' directory, this seems to cause problems

```bash
cd ~
cline
```

- when signing up, initially select bring your own key | ollama
- Once this can change provider by typing `/model` then `TAB` to change to whichever provider you want
  - if you initially select `Login with Cline` it crashes, but if you switch to it after getting to the main interface it works
