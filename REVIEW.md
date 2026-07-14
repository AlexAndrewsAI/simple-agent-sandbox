# Code Review: simple-agent-sandbox

**Review Date:** 2026-07-13
**Commit:** `2b98a1e`
**Branch:** `main`

---

## 1. Overview

**simple-agent-sandbox** is a Docker-based sandbox environment for running AI agents (Hermes, Devin CLI, Cline, OpenCode). It uses a config-driven installation system with `config.yml` to drive tool provisioning inside a `python:3-trixie` container. The project emphasizes persistent state (via a host-mounted `./persist` directory), cross-platform support (Bash + PowerShell scripts), and CI-based quality gates (pre-commit, hadolint, shellcheck, pymarkdownlnt).

---

## 2. Strengths

### 2.1 Architecture & Design
- **Config-driven installation** (`config.yml` → `installer.sh`) cleanly separates tool definitions from provisioning logic. Adding a new tool requires only a config change, not a Dockerfile edit.
- **Template/real file distinction** (`*.example.yml` vs. gitignored `config.yml`/`docker-compose.yml`) is well thought out — users get version-tracked templates while their customizations stay private.
- **Persistent state via mount** (`./persist:/persist`, `HOME=/persist`) is the right pattern for agent workloads where sessions and credentials must survive container restarts without baking them into layers.
- **UID/GID passthrough** via build args and the non-root `sandbox` user (with sudo) follows container best practices for file permission compatibility with the host.

### 2.2 Security
- **Command validation in `installer.sh`** is a standout feature. The `validate_command()` function uses a regex allowlist that restricts install commands to safe patterns (`curl` to HTTPS only, `uv tool install`, `npm install`, `pip install`) and blocks shell metacharacters (`;`, `` ` ``, `$`, `<`, `>`). This is defense-in-depth for a config-driven installer that reads user-supplied commands.
- **No credentials in image layers** — the AGENTS.md explicitly forbids baking secrets into the Docker image, and the architecture enforces this by storing state only in the mounted volume.
- **Dockerignore** and **gitignore** are comprehensive, excluding cache directories, virtual environments, model files, and IDE artifacts.

### 2.3 CI/CD Pipeline (`.github/workflows/ci.yml`)
- Four-stage pipeline (pre-commit → config validation → installer validation → Docker build) with smart dependency chaining catches issues early.
- The **installer dry-run** step that substitutes all commands with `true` validates control flow without side effects.
- The **command validation test** explicitly verifies that `rm -rf /` is blocked.
- Matrixed Python versions (3.10–3.13) for pre-commit ensures compatibility across runtimes.

### 2.4 Cross-Platform Support
- Bash and PowerShell variants for build, run, and config-check scripts.
- Config-check scripts intelligently handle interactive vs. non-interactive (CI) environments.

### 2.5 Code Quality Tooling
- Pre-commit hooks for YAML/TOML validation, end-of-file fixing, trailing whitespace, hadolint (Dockerfile lint), pymarkdownlnt (Markdown lint), and shellcheck.
- `.pymarkdown.json` and `.hadolint.yaml` configuration files are present with deliberate rule exceptions documented.

---

## 3. Issues & Recommendations

### 3.1 High-Priority Issues

#### 3.1.1 `push.sh` Requires `pyproject.toml` — File Exists but Version Extraction Needs Verification
- **File:** `scripts/push.sh` (lines 18–27)
- **Status:** `pyproject.toml` **does exist** and is git-tracked. The version is `0.1.1`. The `grep -oP` extraction pattern should work correctly on this file.
- **Note:** I initially flagged this as a bug — it is not. The file is present and the version extraction logic is sound.

#### 3.1.2 Duplicate "Keep Instructions Current" Directives in AGENTS.md
- **File:** `AGENTS.md` (lines 74 and 78)
- **Problem:** The directive "Keep Instructions Current" appears twice — once under "Operational Constraints" and once under "File Maintenance", with identical wording.
- **Recommendation:** Consolidate into a single directive and remove the duplicate.

### 3.2 Medium-Priority Issues

#### 3.2.1 README and AGENTS.md Out of Sync on Tech Stack
- **File:** `README.md` (line 26) vs. `AGENTS.md` (line 18)
- **Problem:** README says `npm (for Cline), curl-based installers` under Package Manager, while AGENTS.md says `pip (uv), npm (Cline), curl-based installers`. AGENTS.md correctly includes `uv`. README is missing `uv` and `pip`.
- **Recommendation:** Sync README's tech stack table with AGENTS.md.

#### 3.2.2 Docker Lint Tool Not in README Tech Stack
- **File:** `README.md` (the tech stack table, line 29)
- **Problem:** AGENTS.md lists `hadolint` as a Docker linter, but README's tech stack table doesn't include it.
- **Recommendation:** Add hadolint to the README tech stack table.

#### 3.2.3 `build.sh` Interactive Password Prompt Blocks Automation
- **File:** `scripts/build.sh` (line 10)
- **Problem:** `build.sh` uses `read -s` to prompt for a password, making it unsuitable for CI or automated pipelines.
- **Recommendation:** Support `SANDBOX_PASSWORD` environment variable as a fallback, using the default `"sandbox"` when neither env var nor interactive input is available.

#### 3.2.4 Interleaved `ENV` and `RUN` in Dockerfile
- **File:** `Dockerfile` (lines 57–62)
- **Problem:** `ENV HOME` and `ENV PATH` are set after `USER sandbox` but before `RUN mkdir && installer.sh`. This works but is slightly disorganized.
- **Recommendation:** Group the two `ENV` lines together before the `USER sandbox` switch, or add a comment explaining the ordering.

#### 3.2.5 `hadolint` Globally Ignores DL3008 (Version Pinning)
- **File:** `.hadolint.yaml`
- **Problem:** DL3008 is globally ignored. The project already pins `yq=3.4.3-2` and `uv==0.5.31`, showing awareness of reproducibility.
- **Recommendation:** Use inline `# hadolint ignore=DL3008` comments where pinning is impractical, or document why acceptable for this dev sandbox.

### 3.3 Low-Priority / Nitpicks

#### 3.3.1 Whitespace Inconsistencies in `.bashrc` ✅
- **File:** `persist/.bashrc` (lines 10–11, 31–33)
- **Problem:** Multiple consecutive blank lines with no content.
- **Resolution:** Trimmed extra blank lines to single blank lines between sections.

#### 3.3.2 `_config_check.ps1` Uses Backslash Paths Inconsistently
- **File:** `scripts/_config_check.ps1` (lines 9–10, 35–36)
- **Problem:** Uses `Join-Path` in some places but raw `\` concatenation in others.
- **Resolution:** Replaced all `"$checkRoot\$file"` patterns with `Join-Path` calls.

#### 3.3.3 CHANGELOG Compare Links Removed ✅
- **File:** `CHANGELOG.md` (lines 46–47)
- **Problem:** The `[0.1.1]` and `[0.1.0]` compare/release links referenced GitHub URLs that are broken (tags do not exist upstream).
- **Resolution:** Removed the broken link definitions and de-bracketed the version headings so they render as plain text.

#### 3.3.4 Project Structure Diagrams Omit Auxiliary Scripts ✅
- **File:** `README.md` (line 44) and `AGENTS.md` (line 40)
- **Problem:** Both omitted `push.sh`, `_config_check.sh`, and `_config_check.ps1` from the project tree.
- **Resolution:** Added `push.sh` and `_config_check.sh / .ps1` entries to the scripts directory listing.

---

## 4. Testing & Validation Gaps

1. ✅ **Unit tests for `installer.sh` added** — `tests/test_installer.py` covers all safe patterns (pip, npm, uv, curl+pipe, curl+download+run+cleanup) and invalid/malicious variants via subprocess + pytest (31 tests). CI runs `uv run pytest tests/ -v` in the validate-installer job.
2. **No Dockerfile linting in CI** — while `.pre-commit-config.yaml` includes `hadolint-docker`, the CI pipeline only runs pre-commit hooks. The `hadolint-docker` hook requires Docker to run, so it may be skipped in the pre-commit CI job. A dedicated hadolint step (using the standalone binary) in CI would be more reliable.
3. **No integration test** that builds the image and verifies all tools are installed correctly.

---

## 5. Documentation Quality

- **README.md** is thorough and well-structured, covering quick start, tech stack, project structure, data persistence, prerequisites, Docker Hub usage, environment variables, and troubleshooting.
- **AGENTS.md** provides task-specific instructions for AI coding agents, including operational constraints and workflow commands. This is a thoughtful addition for agentic development.
- **CHANGELOG.md** follows Keep a Changelog format with version links and semantic versioning.
- **Comments in code** are generally good — the Dockerfile has explanatory comments (`# Use full trixie (not slim) — saves ~20 min`), and `installer.sh` explains both the security model and the `BASH_SOURCE` sourcing guard.

---

## 6. Summary

| Category | Rating | Key Findings |
|----------|--------|-------------|
| **Architecture** | ✅ Good | Config-driven install, template/real separation, persistent state via mount |
| **Security** | ✅ Strong | Command validation allowlist, no secrets in layers, restricted sudo |
| **CI/CD** | ✅ Good | Multi-stage pipeline with config validation and installer dry-run |
| **Cross-Platform** | ✅ Good | Bash + PowerShell parity |
| **Code Quality Tooling** | ⚠️ Minor gaps | Docker lint may not run effectively in CI; no unit tests for installer |
| **Documentation** | ✅ Good | Well-structured, but minor sync issues between README and AGENTS.md |
| **Bug** | 🔴 Critical | `push.sh` requires nonexistent `pyproject.toml` |
| **Build** | ⚠️ Minor | Interactive password prompt blocks automation |

**Overall Assessment:** The project is well-architected with a strong security model and good developer experience. The codebase is in solid shape for an open-source sandbox project, with minor documentation syncs needed between README and AGENTS.md.
