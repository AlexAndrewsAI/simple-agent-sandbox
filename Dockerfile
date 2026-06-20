FROM python:3-trixie

# Install Node.js 22+ (required by Cline) from NodeSource
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
  && apt-get install -y --no-install-recommends \
    ca-certificates curl git bash xz-utils tar nodejs \
  && rm -rf /var/lib/apt/lists/*

# Install Bun
RUN curl -fsSL https://bun.sh/install | bash

RUN curl -fsSL https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -o /usr/local/bin/yq \
  && chmod +x /usr/local/bin/yq

COPY scripts/installer.sh /usr/local/bin/installer.sh
COPY config.yml /tmp/config.yml

RUN chmod +x /usr/local/bin/installer.sh && installer.sh

ENV PATH="/root/.local/bin:/root/.bun/bin:/usr/local/bin:${PATH}"

CMD ["bash"]
