FROM docker.io/library/node:22-bookworm

ARG PI_VERSION=1.3.0
ARG PI_WEB_VERSION=1.202610.4
ARG HINDSIGHT_VERSION=0.8.2
ARG PLAYWRIGHT_MCP_VERSION=0.0.83
ARG PLAYWRIGHT_VERSION=1.64.1

RUN apt-get update && apt-get install -y --no-install-recommends \
      bash ca-certificates curl git git-lfs gh jq less ripgrep fd-find fzf bat \
      tmux procps unzip xz-utils openssh-client python3 python3-pip \
      build-essential pkg-config libssl-dev \
      fonts-liberation fonts-dejavu-core fonts-noto-color-emoji \
    && ln -sf /usr/bin/fdfind /usr/local/bin/fd \
    && ln -sf /usr/bin/batcat /usr/local/bin/bat \
    && rm -rf /var/lib/apt/lists/*

RUN npm install -g --no-audit --no-fund \
      @earendil-works/pi-coding-agent@${PI_VERSION} \
      @jmfederico/pi-web@${PI_WEB_VERSION} \
      @vectorize-io/hindsight-coding-agents@${HINDSIGHT_VERSION} \
    && npm cache clean --force

RUN npm install -g --no-audit --no-fund \
      @playwright/mcp@${PLAYWRIGHT_MCP_VERSION} \
      playwright@${PLAYWRIGHT_VERSION} \
    && playwright install --with-deps chrome \
    && rm -rf /var/lib/apt/lists/* \
    && npm cache clean --force

ENV HOME=/home/admin \
    XDG_CONFIG_HOME=/home/admin/.config \
    PI_CODING_AGENT_DIR=/home/admin/.pi/agent \
    PI_WEB_DATA_DIR=/home/admin/.pi-web \
    PI_WEB_SESSIOND_SOCKET=/home/admin/.pi-web/sessiond.sock \
    PI_WEB_HOST=127.0.0.1 \
    PI_WEB_PORT=8504 \
    HINDSIGHT_API_URL=http://127.0.0.1:8888 \
    NPM_CONFIG_UPDATE_NOTIFIER=false

RUN pi --version && pi-web --version && playwright-mcp --version

RUN mkdir -p /home/admin/.config /home/admin/.cache /home/admin/.local /workspace \
    && chown -R 1000:1000 /home/admin /workspace

USER 1000:1000
WORKDIR /workspace
CMD ["pi-web-server"]
