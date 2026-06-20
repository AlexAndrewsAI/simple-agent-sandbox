# Simple Agent Sandbox

A Docker-based sandbox environment for running AI agents.

## Agents

| Agent                                                  | Description                                       | Notes                              |
| ------------------------------------------------------ | ------------------------------------------------- | ---------------------------------- |
| [Hermes Agent](https://hermes-agent.nousresearch.com/) | NousResearch's general-purpose agent              | Install is large and takes a while |
| [Devin CLI](https://cli.devin.ai/)                     | Cognition's autonomous software engineering agent | Lightweight install                |

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/)
- [Docker Compose](https://docs.docker.com/compose/install/)

## Building

Build the Docker image from the root of the repository:

```bash
docker compose build
```

This will:
1. Start from a `python:3-slim-trixie` base image
2. Install required system packages (`ca-certificates`, `curl`, `git`, `bash`, `xz-utils`, `tar`)
3. Install `yq` for reading YAML config
4. Copy `scripts/installer.sh` and `config.yml`
5. Run `installer.sh`, which conditionally installs tools marked as `true` in `config.yml`
6. Set up the PATH to include installed binaries

## Running

Start an interactive shell inside the sandbox container:

```bash
docker compose run --rm sandbox
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
- Tool installation is driven by `config.yml`. Set entries under `install:` to `true` to include a tool at build time.
- The `scripts/installer.sh` script reads `config.yml` via `yq` and conditionally installs Hermes Agent and/or Devin CLI.

### Configuration

Edit `config.yml` to enable or disable tools:

```yaml
# Install list — set a tool to true to install it at build time
install:
  hermes: false  # Hermes agent by NousResearch
  devin: true   # Devin CLI by Cognition
```
