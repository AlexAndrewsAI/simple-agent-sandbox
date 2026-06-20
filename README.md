# Simple Agent Sandbox

A Docker-based sandbox environment for running AI agents.

## Agents

All CLIs listed below offer usable free plans.

| Agent                                                  | Description                                                                 | Notes                              |
| ------------------------------------------------------ | --------------------------------------------------------------------------- | ---------------------------------- |
| [Hermes Agent](https://hermes-agent.nousresearch.com/) | Free models via API with [OpenRouter](https://openrouter.ai) or [Nvidia](https://build.nvidia.com) | Install is large and takes a while |
| [Cline](https://cline.bot/)                             | Offers a free plan with decent LLM models                                   | Lightweight install                |
| [Devin CLI](https://cli.devin.ai/)                     | Offers free plan with decent LLM model                                      | Lightweight install                |

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/)
- [Docker Compose](https://docs.docker.com/compose/install/)

## Building

Build the Docker image from the root of the repository:

```bash
docker compose build
```

Or use the helper script:

```bash
./scripts/build.sh        # Bash
.\scripts\build.ps1       # PowerShell
```

This will:
1. Start from a `python:3-slim-trixie` base image
2. Install required system packages (`ca-certificates`, `curl`, `git`, `bash`, `xz-utils`, `tar`)
3. Install `yq` for reading YAML config
4. Copy `scripts/installer.sh` and `config.yml`
5. Run `installer.sh`, which installs all tools listed under `install:` in `config.yml`
6. Set up the PATH to include installed binaries

## Running

Start an interactive shell inside the sandbox container:

```bash
docker compose run --rm sandbox
```

Or use the helper script:

```bash
./scripts/run.sh          # Bash
.\scripts\run.ps1         # PowerShell
```

Or, for a persistent TTY session:

```bash
docker compose up -d
docker compose exec sandbox bash
```

## Data Persistence

The `./persist` directory on the host is mounted into the container at `/persist`. This directory is used to store:

- Home directory and tool state (`/persist/.local/`)
- Shell history (`/persist/.bash_history`)

Changes made inside `/persist` in the container are persisted on the host and survive container restarts.

## Environment Variables

| Variable | Value                       | Description                                  |
| -------- | --------------------------- | -------------------------------------------- |
| `HOME`   | `/persist`                  | Sets the home directory inside the container |
| `PATH`   | `/persist/.local/bin:$PATH` | Ensures installed binaries are available     |

## Project Structure

```
simple-agent-sandbox
├── docker-compose.yml
├── Dockerfile
├── config.yml
├── .gitignore
├── scripts
│   └── installer.sh
├── persist
│   └── .bashrc
└── README.md
```

## Notes

- The `./persist` directory is gitignored and should not be committed.
- The container runs `bash` by default, providing an interactive shell.
- Tool installation is driven by `config.yml`. Each key under `install:` maps directly to its install command string.
- The `scripts/installer.sh` script reads `config.yml` via `yq` and runs each install command listed.

### Configuration

Edit `config.yml` to enable or disable tools:

- Comment out undesired apps

```yaml
# Install list — each key maps to its install command
install:
  tool-name: "command to install the tool"
  # undesired-tool: "skip this one"
  another-tool: "another install command"

```
