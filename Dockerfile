FROM python:3-slim-trixie

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl git bash xz-utils tar \
  && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -o /usr/local/bin/yq \
  && chmod +x /usr/local/bin/yq

COPY scripts/installer.sh /usr/local/bin/installer.sh
COPY config.yml /tmp/config.yml

RUN chmod +x /usr/local/bin/installer.sh && installer.sh

ENV PATH="/root/.local/bin:/usr/local/bin:${PATH}"

CMD ["bash"]
