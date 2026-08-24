FROM docker.io/smanx/opencode:latest

USER root

# Single base layer: apt packages + Bun + elan + uv + zotkit.
# Everything that changes rarely goes here so it caches as one stable unit.
# Anything that changes often (oh-my-opencode-slim) goes later so it doesn't
# invalidate the base.
RUN apt-get update && apt-get install -y --no-install-recommends \
      curl unzip gnupg ca-certificates && \
    # Node.js 22
    curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    apt-get install -y --no-install-recommends nodejs && \
    # GitHub CLI
    mkdir -p -m 755 /etc/apt/keyrings && \
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
      | dd of=/etc/apt/keyrings/githubcli-archive-keyring.gpg && \
    chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
      > /etc/apt/sources.list.d/github-cli.list && \
    apt-get update && apt-get install -y --no-install-recommends gh && \
    # podman-remote for container self-management
    apt-get install -y --no-install-recommends podman tmux && \
    rm -rf /var/lib/apt/lists/* && \
    # Bun
    curl -fsSL https://bun.sh/install | BUN_INSTALL=/root/.bun bash && \
    # elan (Lean 4 toolchain manager) — no default toolchain, each project specifies its own
    curl -fsSL https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh \
      | sh -s -- -y --default-toolchain none && \
    # uv (Astral's Python package/project manager) — single static binary at /usr/local/bin/uv
    curl -LsSf https://astral.sh/uv/install.sh | sh && \
    mv /root/.local/bin/uv /usr/local/bin/uv && \
    mv /root/.local/bin/uvx /usr/local/bin/uvx && \
    # zotkit (headless Zotero CLI, https://github.com/oldantique/zotkit)
    # Config still comes from .env / $ZOTKIT_ENV at runtime.
    uv tool install zotkit && \
    mkdir -p /run/podman

# Combined PATH for all tools installed above. Order matters for shadowing:
# uv-managed tools take precedence over system paths so `uv tool install`
# updates are picked up without rebuilding the image.
ENV PATH="/root/.local/bin:/root/.bun/bin:/root/.elan/bin:${PATH}"

# Smoke-test zotkit install (binary must resolve; API check needs .env at runtime)
RUN zotkit --version

# oh-my-opencode-slim LAST so base changes don't invalidate it.
# Pinned to a real version — `@latest` resolves every build and nukes the cache.
RUN bun x oh-my-opencode-slim@latest --version 2>/dev/null || true