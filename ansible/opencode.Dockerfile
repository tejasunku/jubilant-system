FROM docker.io/smanx/opencode:latest

USER root

# Install Node.js 22, bun, GitHub CLI, and podman-remote
RUN apt-get update && \
    apt-get install -y curl unzip gnupg && \
    # Node.js 22
    curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    apt-get install -y nodejs && \
    # Bun
    curl -fsSL https://bun.sh/install | bash && \
    # GitHub CLI
    mkdir -p -m 755 /etc/apt/keyrings && \
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/etc/apt/keyrings/githubcli-archive-keyring.gpg && \
    chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null && \
    apt-get update && \
    apt-get install -y gh && \
    # podman-remote for container self-management
    apt-get install -y podman tmux || true && \
    rm -rf /var/lib/apt/lists/*

ENV PATH="/root/.bun/bin:${PATH}"

RUN mkdir -p /run/podman

# Install elan (Lean 4 toolchain manager) — no default toolchain, each project specifies its own
RUN curl https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh -sSf | sh -s -- -y --default-toolchain none

# Add elan to PATH for all shells
ENV PATH="${HOME}/.elan/bin:${PATH}"

# Install uv (Astral's Python package/project manager) — single static binary at /usr/local/bin/uv
RUN curl -LsSf https://astral.sh/uv/install.sh | sh && \
    mv /root/.local/bin/uv /usr/local/bin/uv && \
    mv /root/.local/bin/uvx /usr/local/bin/uvx

# Install zotkit (headless Zotero CLI, https://github.com/oldantique/zotkit) as a uv tool
# so `zotkit` is on PATH for the agent. Config still comes from .env / $ZOTKIT_ENV at runtime.
RUN uv tool install zotkit

# Pre-install oh-my-opencode-slim so it's available without download
RUN bun x oh-my-opencode-slim@latest --version 2>/dev/null || true

# Smoke-test zotkit install (will fail without ZOTERO_* env, but the binary must resolve)
RUN zotkit --version || true
