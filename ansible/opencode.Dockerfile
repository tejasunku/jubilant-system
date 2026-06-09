FROM docker.io/smanx/opencode:latest

USER root

# Install Node.js 22 and bun
RUN apt-get update && \
    apt-get install -y curl && \
    curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    apt-get install -y nodejs && \
    curl -fsSL https://bun.sh/install | bash && \
    rm -rf /var/lib/apt/lists/*

# Install oh-my-opencode-slim with opencode-go preset (non-tui mode)
RUN /root/.local/bin/bunx oh-my-opencode-slim@latest install --preset=opencode-go --no-tui --skills=yes