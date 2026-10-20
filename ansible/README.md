# Ansible Configuration for Ubuntu Server

This directory contains Ansible playbooks and configuration to manage the Ubuntu server.

## Setup

1. **Clone the repo** on your local machine:
   ```bash
   git clone https://github.com/tejasunku/jubilant-system
   cd jubilant-system/ansible
   ```

2. **Copy and configure inventory**:
   ```bash
   cp inventory.ini.example inventory.ini
   # Edit inventory.ini with your server details
   ```

3. **Configure SSH access**:
   - Ensure your SSH key is on the server:
     ```bash
     ssh-copy-id admin@YOUR_SERVER_IP
     ```
   - Or add to `inventory.ini`: `ansible_ssh_private_key_file=~/.ssh/your_key`

4. **Test connection**:
   ```bash
   ansible all -m ping
   ```

5. **Run a playbook**:
   ```bash
   ansible-playbook playbooks/base.yml
   ```

## OpenCode Hot-Reload Setup

The OpenCode container is configured for hot-reloading:

- **Config directory** (`~/.config/opencode`) is bind-mounted into the container. Edit plugins, MCP servers, and settings on the host — changes are live immediately.
- **Podman socket** is mounted so the agent can restart the container after installing new tools.
- **Restart script** is available at `/opt/scripts/restart-opencode.sh` inside the container.

### How it works

1. **Config changes**: Edit files in `~/.config/opencode/` on the host. opencode watches this directory and picks up changes automatically.

2. **Installing packages**: The agent can `npm install`, `bun add`, etc. inside the container. To make new binaries available on `PATH`, restart the container:
   ```bash
   # From inside the container:
   /opt/scripts/restart-opencode.sh
   # Or directly:
   podman restart opencode
   ```

3. **First-time setup**: After initial deploy, run oh-my-opencode-slim inside the container:
   ```bash
   podman exec opencode bun x oh-my-opencode-slim@latest install --preset=opencode-go --no-tui --skills=yes
   ```

4. **Reset workspace**: If the agent messes up the workspace, just recreate:
   ```bash
   podman stop opencode
   podman rm opencode
   podman compose -f ~/opencode/opencode-compose.yml up -d --build
   ```

## Pi Coding Agent + PI WEB

The Pi stack runs in Podman with bind-mounted state and workspaces:

- **Pi state**: `~/.pi` (config, sessions, packages, credentials)
- **PI WEB state**: `~/.pi-web`
- **Hindsight integration state**: `~/.hindsight`
- **Workspaces**: `~/workspace` mounted at `/workspace`; `~/jubilant-system` is also available
- **Web UI**: PI WEB on `127.0.0.1:8504`, exposed as `pi.tejasunku.com`

Deploy it with:

```bash
ansible-playbook playbooks/pi.yml
ansible-playbook playbooks/cloudflared.yml   # publishes pi.tejasunku.com
```

**Prerequisite:** the container runs as UID/GID `1000`, so `admin` must be UID
1000 (the usual first Ubuntu user). Otherwise the bind-mounted state directories
are not writable. Verify with `id admin`.

On rootless Podman the compose file sets `userns_mode: "keep-id"` so container
UID 1000 maps to your host user. This requires **`podman-compose`** (not the
`docker-compose` provider that `podman compose` prefers by default, whose API
rejects `keep-id`). Install it if missing (`sudo apt install podman-compose`, or
`pipx install podman-compose`) and verify with `command -v podman-compose`.

If you deploy by hand instead of running the playbook:

```bash
mkdir -p ~/pi ~/workspace ~/.pi ~/.pi-web ~/.hindsight ~/.config/pi-web ~/jubilant-system
cp ansible/pi-compose.yml ~/pi/pi-compose.yml
cp ansible/pi.Dockerfile  ~/pi/Dockerfile
cp ansible/scripts/pi-setup.sh ~/pi/pi-setup.sh
cp ansible/.env ~/pi/.env
printf '{\n  "host": "127.0.0.1",\n  "port": 8504,\n  "pathAccess": {"allowedPaths": ["/workspace", "/home/admin/jubilant-system"]}\n}\n' \
  > ~/.config/pi-web/config.json

cd ~/pi
podman-compose -f pi-compose.yml up -d --build
podman exec pi-sessiond /usr/local/bin/pi-setup.sh
podman-compose -f pi-compose.yml restart sessiond web
```

The playbook installs the requested Pi packages:

- `billion-context-pi`
- `pi-subagents`
- `pi-web-access`
- `pi-lens`
- `@juicesharp/rpiv-ask-user-question`
- `pi-background-tasks`
- `@gotgenes/pi-permission-system`
- Hindsight via `hindsight-coding-agents install pi --server self-hosted --api-url http://127.0.0.1:8888`

`billion-context-pi` also ships a delegation tool. `~/.pi/acp.json` is set to
`{"delegate": false}` so `pi-subagents` remains the single delegation path.

`@gotgenes/pi-permission-system` enforces a policy on tool calls, bash, MCP,
skills, and file paths. The default policy in `pi-permission-config.json` allows
normal work but denies reads of `.env*`, `auth.json`, `.ssh`, `*.pem`, and
`*.key`, plus `rm -rf /` and `sudo`. Both playbooks install it to
`~/.pi/agent/extensions/pi-permission-system/config.json`; edit that file on the
host (or the repo copy and re-run the playbook) to add `ask` rules. Permission
prompts use Pi's extension UI, which PI WEB supports. Rules compose
most-restrictive-wins across `path`, `external_directory`, per-tool, and `bash`
surfaces, so a `deny` cannot be loosened by a broader `allow`.

Hindsight is pinned to the existing `opencode` bank so Pi and OpenCode share one
memory bank. `scripts/pi-setup.sh` writes `bankId` and `manageBankConfig: false`
into `~/.hindsight/coding-agent.json`; the static `bankId` applies to every
workspace, and disabling bank-config management stops Pi from reshaping the
bank's settings. Hindsight reads this file once per workspace, so restart
`pi.service` after changing it.

MCP servers use Pi's built-in MCP support. Because only `~/.pi` is mounted into
the container, configure them on the host at:

- User scope: `~/.pi/agent/mcp.json`
- Project scope: `<project>/.pi/mcp.json` (for example `~/jubilant-system/.pi/mcp.json`)
- OAuth tokens: `~/.pi/agent/mcp-auth.json`

Use `pi mcp add` / `pi mcp list` / `pi mcp login`, or `/mcp` inside a session.
`~/.config/mcp/mcp.json` is not mounted, so prefer `~/.pi/agent/mcp.json`.

The interactive MCP panel is TUI-only; under PI WEB (RPC mode) edit the JSON
instead. To manage servers from the repo, copy `pi-mcp.json.example` to
`pi-mcp.json` (gitignored because it may contain secrets) and run
`ansible-playbook playbooks/pi-plugins.yml`, which installs it as
`~/.pi/agent/mcp.json` with mode `0600`. Prefer `${VAR}` references for tokens
and put the values in `~/pi/.env`. MCP servers connect at session start, so open
a new conversation afterwards; `/reload` does not reconnect them.

If `pi-mcp-adapter` is still installed from an earlier deploy, it replaces Pi's
built-in MCP. Its `/mcp` setup panel is also TUI-only, and it reads the same
`~/.pi/agent/mcp.json`, so the config above works either way. Remove it with
`ansible-playbook playbooks/pi-plugins.yml -e 'pi_remove_packages=["npm:pi-mcp-adapter"]'`
to use native MCP.

### Browser and UI iteration

The image also contains Google Chrome, font packages, and Microsoft's Playwright
MCP server (`playwright-mcp`). This is an image-level change, so rebuild rather
than only re-running the plugin playbook:

```bash
podman-compose -f ~/pi/pi-compose.yml up -d --build
```

`playbooks/pi-plugins.yml` merges a `playwright` entry into
`~/.pi/agent/mcp.json` with `exposure: direct` so screenshot results reach the
model. Open a new session afterwards and verify with `pi mcp list`.

No X server or GPU is needed: Chrome runs headless with software rendering. The
compose file sets `shm_size: 1g` because Chrome crashes with the default 64 MB
`/dev/shm`, and the server passes `--no-sandbox` because a rootless container
cannot use Chrome's setuid sandbox (Ubuntu also restricts unprivileged user
namespaces).

The design loop is: start the dev server (for example with
`pi-background-tasks`), then have Pi use `browser_navigate`, `browser_snapshot`
(the accessibility tree, which is cheaper than an image), `browser_resize`, and
`browser_take_screenshot`. Screenshots are written to `/workspace/.playwright`
and PI WEB can preview them. To open the dev server from your own browser,
tunnel it over SSH:

```bash
ssh -L 3000:127.0.0.1:3000 admin@194.163.139.8
```

### Persistence

These host paths are bind-mounted and survive container rebuilds:

- `~/.pi` — sessions, settings, `auth.json`, `mcp.json`, `models.json`, skills, and installed Pi packages/plugins
- `~/.pi-web` — PI WEB data, including sessions kept alive across reloads
- `~/.hindsight` — Hindsight integration config
- `~/.config/pi-web/config.json`
- `~/workspace` and `~/jubilant-system` — your projects

Container-local paths (`~/.cache`, `~/.npm`, `~/.local`, `~/.ssh`, `~/.gitconfig`)
are **not** mounted and are lost when the container is recreated. Keep work under
`/workspace` or `/home/admin/jubilant-system`; those are also the only paths in
`pathAccess.allowedPaths`. Git access uses `GITHUB_TOKEN` from `~/pi/.env`, not
host SSH keys.

### Model providers

Inside PI WEB, run `/login` in a Pi session to pick a provider; the credential is
stored in `~/.pi/agent/auth.json` (persisted). Use `/model` to select a model and
`Ctrl+S` to save it as the default. Alternatively, set the provider's environment
variable (for example `OPENROUTER_API_KEY` or `ANTHROPIC_API_KEY`) in
`~/pi/.env` and recreate the containers:

```bash
podman-compose -f ~/pi/pi-compose.yml up -d --force-recreate
```

Stored `auth.json` credentials take precedence over environment variables.
Custom or OpenAI-compatible endpoints belong in `~/.pi/agent/models.json`.

After deployment, open the UI, complete `/login` for your model provider, and
select a working directory under `/workspace` or `/home/admin/jubilant-system`.

### Applying package and config changes

Pi packages are installed into `~/.pi/agent`, which is bind-mounted, so plugin
changes never need an image rebuild:

```bash
ansible-playbook playbooks/pi-plugins.yml
```

That installs the packages listed in the playbook, rewrites `~/.pi/acp.json` and
the Hindsight bank pin, and prints the installed package list. To change the
set, pass variables:

```bash
ansible-playbook playbooks/pi-plugins.yml -e 'pi_packages=["npm:billion-context-pi","npm:pi-subagents","npm:pi-web-access","npm:new-package"]'
ansible-playbook playbooks/pi-plugins.yml -e 'pi_remove_packages=["npm:old-package"]'
```

Then run `/reload` in each idle Pi conversation (new conversations pick the
changes up automatically). `/reload` covers extensions, skills, prompt
templates, themes, and context files. A few changes still need the session
daemon restarted, which interrupts live sessions:

- packages that ship PI WEB server plugins
- global model-provider registration or connection changes
- MCP server and Hindsight config changes

Pass `-e pi_restart_sessiond=true` for those. `~/pi/.env` changes are the one
thing that cannot be applied live: container environment is fixed at creation,
so recreate the containers (no rebuild needed):

```bash
podman-compose -f ~/pi/pi-compose.yml up -d --force-recreate
```


**Security:** PI WEB has no built-in authentication. Keep it behind Cloudflare
Access (or another authenticated proxy). Exposing it directly is equivalent to
exposing a shell and filesystem to the internet.

## Security Notes

- **NEVER commit `inventory.ini`** - it contains server IPs and credentials
- Use `ansible-vault` for sensitive data: `ansible-vault encrypt_string 'password' --name 'db_password'`
- Alternatively, use environment variables in playbooks: `{{ lookup('env', 'MY_SECRET') }}`

## Directory Structure

```
ansible/
├── ansible.cfg                # Ansible configuration
├── inventory.ini.example      # Template for inventory (safe to commit)
├── opencode-compose.yml       # Container compose with hot-reload mounts
├── opencode.Dockerfile        # Container image (tools only, config is mounted)
├── pi-compose.yml             # Pi + PI WEB container compose
├── pi.Dockerfile              # Pi + PI WEB image with plugins available
├── scripts/
│   ├── pi-setup.sh            # Installs Pi packages and Hindsight wiring
│   └── restart-opencode.sh    # Agent-callable restart helper
├── playbooks/
│   ├── base.yml               # Base server setup
│   ├── cloudflared.yml        # Cloudflare tunnel setup
│   ├── firewall.yml           # Firewall rules
│   ├── hindsight.yml          # Hindsight AI memory setup
│   ├── opencode.yml           # OpenCode container deployment
│   ├── pi.yml                 # Pi + PI WEB deployment
│   ├── pi-plugins.yml         # Apply Pi packages/config without rebuild
│   └── shell.yml              # Shell container setup
└── README.md
```
