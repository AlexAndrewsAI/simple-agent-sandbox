FROM python:3-slim-trixie

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl git bash xz-utils tar \
  && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash

ENV PATH="/root/.local/bin:${PATH}"

CMD ["bash"]
