FROM python:3-trixie

# Build args for matching host user UID/GID
ARG USER_UID=1000
ARG USER_GID=1000

ENV HOME=/persist
WORKDIR /persist

# Install Node.js 22+ (required by Cline) from NodeSource
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
  && apt-get install -y --no-install-recommends \
    ca-certificates curl git bash xz-utils tar nodejs \
  && rm -rf /var/lib/apt/lists/*

ARG YQ_VERSION=v4.44.6
RUN curl -fsSL "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64" -o /usr/local/bin/yq \
  && chmod +x /usr/local/bin/yq

# Create a non-root user that matches the host UID/GID
RUN groupadd --gid ${USER_GID} sandbox \
  && useradd --uid ${USER_UID} --gid ${USER_GID} --create-home --shell /bin/bash sandbox

COPY scripts/installer.sh /usr/local/bin/installer.sh
COPY config.example.yml /tmp/config.yml

RUN chown sandbox:sandbox /usr/local/bin/installer.sh /tmp/config.yml \
  && chmod +x /usr/local/bin/installer.sh

# Create /persist directory so installer.sh can target it as HOME
# (at runtime this is mounted from the host, but we need it during build)
RUN mkdir -p /persist && chown sandbox:sandbox /persist

# Switch to non-root user for tool installation,
# with HOME=/persist so tools (npm install -g, pip, etc.) write there
# instead of to /usr/lib/node_modules (EACCES) or /home/sandbox (non-persistent).
USER sandbox


RUN mkdir -p /persist/.npm-global \
  && npm config set prefix /persist/.npm-global

RUN installer.sh

ENV PATH="/persist/.npm-global/bin:/persist/.local/bin:/home/sandbox/.local/bin:/root/.local/bin:/root/.bun/bin:/usr/local/bin:${PATH}"

CMD ["bash"]
