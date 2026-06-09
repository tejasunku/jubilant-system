FROM docker.io/smanx/opencode:latest

USER root

# Install npm for oh-my-opencode-slim
RUN apt-get update && apt-get install -y npm && rm -rf /var/lib/apt/lists/*

# Install oh-my-opencode-slim with opencode-go preset (non-tui mode)
RUN npx oh-my-opencode-slim@latest install --preset=opencode-go --no-tui --skills=yes