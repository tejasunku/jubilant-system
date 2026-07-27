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
├── scripts/
│   └── restart-opencode.sh    # Agent-callable restart helper
├── playbooks/
│   ├── base.yml               # Base server setup
│   ├── cloudflared.yml        # Cloudflare tunnel setup
│   ├── firewall.yml           # Firewall rules
│   ├── hindsight.yml          # Hindsight AI memory setup
│   ├── opencode.yml           # OpenCode container deployment
│   └── shell.yml              # Shell container setup
└── README.md
```
