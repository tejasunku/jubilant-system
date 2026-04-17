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

## Security Notes

- **NEVER commit `inventory.ini`** - it contains server IPs and credentials
- Use `ansible-vault` for sensitive data: `ansible-vault encrypt_string 'password' --name 'db_password'`
- Alternatively, use environment variables in playbooks: `{{ lookup('env', 'MY_SECRET') }}`

## Directory Structure

```
ansible/
├── ansible.cfg           # Ansible configuration
├── inventory.ini.example # Template for inventory (safe to commit)
├── playbooks/
│   └── base.yml          # Basic server setup playbook
└── README.md
```
