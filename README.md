# Simple Agent Sandbox

A Docker-based sandbox environment for running [Hermes Agent](https://hermes-agent.nousresearch.com/) from NousResearch.

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
3. Download and install the Hermes Agent via the official install script
4. Set up the PATH to include the Hermes Agent binary

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

- Hermes Agent configuration and state (`/persist/.local/`)
- Shell history (`/persist/.bash_history`)

Changes made inside `/persist` in the container are persisted on the host and survive container restarts.

## Environment Variables

| Variable | Value | Description |
|----------|-------|-------------|
| `HOME` | `/persist` | Sets the home directory inside the container |
| `PATH` | `/persist/.local/bin:$PATH` | Ensures installed binaries are available |

## Project Structure

```
.
├── Dockerfile          # Image definition
├── docker-compose.yml  # Container orchestration
├── .gitignore          # Ignores ./persist directory
├── persist/            # Persistent data (gitignored)
└── README.md           # This file
```

## Notes

- The `./persist` directory is gitignored and should not be committed.
- The container runs `bash` by default, providing an interactive shell.
- The Hermes Agent is installed system-wide via its official install script.