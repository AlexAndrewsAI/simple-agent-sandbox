# Use full trixie (not slim) — saves ~20 min of build time by avoiding
# apt-get compilation of native deps during agent installs.
FROM python:3-trixie

# Set shell options for better error handling in piped commands
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Build args for matching host user UID/GID and sandbox password
ARG USER_UID=1000
ARG USER_GID=1000
ARG SANDBOX_PASSWORD=sandbox

# Install Node.js 22+ (required by Cline) from NodeSource
# yq is the Debian (Python/jq wrapper) package; pinned to a known version.
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
  && apt-get install -y --no-install-recommends \
    ca-certificates curl git bash xz-utils tar nodejs yq=3.4.3-2 \
  && rm -rf /var/lib/apt/lists/*

COPY config.yml /tmp/config.yml

# Install apt packages from config.yml (if any)
RUN if [ -f /tmp/config.yml ] && yq '.apt' /tmp/config.yml &>/dev/null; then \
      apt-get update && \
      mapfile -t PACKAGES < <(yq -r '.apt[]' /tmp/config.yml) && \
      apt-get install -y --no-install-recommends "${PACKAGES[@]}" && \
      rm -rf /var/lib/apt/lists/*; \
    fi

# Install uv system-wide (tool manager for Python tools like pytest, ruff, mypy)
# Using pip directly is more reliable than the astral.sh | sh installer in
# constrained build environments. The --break-system-packages flag is needed
# on PEP 668 (externally-managed) Python environments like Debian Trixie.
# Version pinned for reproducibility (0.5.31 is the latest stable release).
RUN pip install --no-cache-dir --break-system-packages "uv==0.5.31"

# Create a non-root user that matches the host UID/GID
RUN groupadd --gid ${USER_GID} sandbox \
  && useradd --uid ${USER_UID} --gid ${USER_GID} --create-home --shell /bin/bash sandbox \
  && echo "sandbox:${SANDBOX_PASSWORD}" | chpasswd

# Install sudo for sandbox user (password required)
RUN apt-get update && \
      apt-get install -y --no-install-recommends sudo \
      && rm -rf /var/lib/apt/lists/* && \
      echo "sandbox ALL=(ALL) ALL" > /etc/sudoers.d/sandbox && \
      chmod 0440 /etc/sudoers.d/sandbox

COPY scripts/installer.sh /usr/local/bin/installer.sh

RUN chown sandbox:sandbox /usr/local/bin/installer.sh /tmp/config.yml \
  && chmod +x /usr/local/bin/installer.sh \
  && mkdir -p /persist && chown sandbox:sandbox /persist

# Switch to non-root user for tool installation.
USER sandbox
ENV HOME=/home/sandbox
WORKDIR /home/sandbox

ENV PATH="/home/sandbox/.opencode/bin:/home/sandbox/node_modules/cline/bin:/home/sandbox/.npm-global/bin:/home/sandbox/.local/bin:/persist/.local/bin:/usr/local/bin:/usr/bin:/bin"

RUN mkdir -p /home/sandbox/.npm-global && \
    yq '.' /tmp/config.yml > /dev/null 2>&1 || { echo "ERROR: /tmp/config.yml is missing or invalid YAML"; exit 1; } && \
    installer.sh

CMD ["bash"]
