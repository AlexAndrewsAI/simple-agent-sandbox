# Simple Agent Sandbox

A Docker-based sandbox environment for running AI agents.

## Agents

All CLIs listed below offer usable free plans.

| Agent                                                  | Description                                                                 | Notes                              |
| ------------------------------------------------------ | --------------------------------------------------------------------------- | ---------------------------------- |
| [Hermes Agent](https://hermes-agent.nousresearch.com/) | Free models via API with [OpenRouter](https://openrouter.ai) or [Nvidia](https://build.nvidia.com) | Install is large and takes a while |
| [Cline](https://cline.bot/)                             | Offers a free plan with decent LLM models                                   | Heavy install               |
| [Devin CLI](https://cli.devin.ai/)                     | Offers free plan with decent LLM model                                      | Lightweight install                |

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/)
- [Docker Compose](https://docs.docker.com/compose/install/)

## Setup

Both `config.yml` and `docker-compose.yml` are gitignored real config files. Copy the example templates to create your own:

```bash
cp config.example.yml config.yml
cp docker-compose.example.yml docker-compose.yml
```

- Edit `config.yml` to enable/disable agent tools (comment out what you don't need)
- Edit `docker-compose.yml` to add/remove volume mounts as needed

## Building

Build the Docker image from the root of the repository:

```bash
docker compose build
```

Or use the helper script:

```bash
./scripts/build.sh        # Bash (uses --progress=plain for visible output)
.\scripts\build.ps1       # PowerShell (uses --progress=plain for visible output)
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
├── Dockerfile
├── docker-compose.example.yml   (tracked template)
├── docker-compose.yml           (your real config — gitignored)
├── config.example.yml           (tracked template)
├── config.yml                   (your real config — gitignored)
├── .gitignore
├── scripts/
│   ├── installer.sh
│   ├── run.sh / run.ps1
│   └── build.sh / build.ps1
├── persist/                     (gitignored)
│   └── .bashrc
└── README.md
```

## Notes

- The `./persist` directory is gitignored and should not be committed.
- The container runs `bash` by default, providing an interactive shell.
- Tool installation is driven by `config.yml`. Each key under `install:` maps directly to its install command string.
- The `scripts/installer.sh` script reads `config.yml` via `yq` and runs each install command listed.
- Volume mounts are defined in `docker-compose.yml` — the single source of truth. Helper scripts are thin wrappers and do not duplicate mount logic.

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
