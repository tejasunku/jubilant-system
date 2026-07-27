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
    apt-get install -y podman || true && \
    rm -rf /var/lib/apt/lists/*

ENV PATH="/root/.bun/bin:${PATH}"

RUN mkdir -p /run/podman

# Pre-install oh-my-opencode-slim so it's available without download
RUN bun x oh-my-opencode-slim@latest --version 2>/dev/null || true
