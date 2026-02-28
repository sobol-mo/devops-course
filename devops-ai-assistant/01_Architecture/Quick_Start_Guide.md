# Quick Start Guide: DevOps AI Assistant

**Version**: 1.0
**Target Audience**: Students (DevOps course setup)

---

## Overview

This guide explains how to get the local **Dev Environment** running on your virtual machine. By the end, you will have the OpenClaw agent installed and accessible from your host machine via an SSH tunnel.

---

## Prerequisites

Before you start, ensure you have:

- A running Linux VM (Ubuntu Server 22.04+) — see Module 1
- SSH access to your VM — see Modules 2, 3, 4
- The repository cloned on your VM — see Module 5
- Ansible installed on your host machine: `sudo apt install ansible`

---

## 1. Deploy with Ansible

The entire server configuration is automated. One command does everything:

```bash
# On your HOST machine — navigate to the ansible directory
cd 10_Implementation/ansible/

# Edit inventory.ini to point to your VM's IP address first
nano inventory.ini

# Run the playbook
ansible-playbook playbook-openclaw-setup.yml
```

**What this does automatically:**

- Creates the isolated `openclaw` system user (no `sudo`)
- Installs Node.js 22.x
- Creates the application directory at `/opt/openclaw`
- Installs the OpenClaw agent
- Sets up directory permissions
- Deploys and enables the `systemd` service

**Expected result:** The playbook exits with `failed=0`. The agent is installed.

---

## 2. Configure the Agent

SSH into your VM and switch to the `openclaw` user to run the onboarding wizard:

```bash
# Connect to the VM
ssh your-vm-user@YOUR_VM_IP

# Switch to the agent's user
sudo su - openclaw

# Run the setup wizard
openclaw onboard
```

During onboarding:

- **Model:** Use a provider you have an API key for (e.g., Google Gemini)
- **Workspace:** Accept default `~/clawd`
- **Gateway port:** `18789`, bind to `localhost` (127.0.0.1)
- **Token auth:** Required — choose a strong token

---

## 3. Start the Service

```bash
# From your HOST machine — start the systemd service on the VM
ssh your-vm-user@YOUR_VM_IP 'sudo systemctl start openclaw.service'

# Check that it started correctly
ssh your-vm-user@YOUR_VM_IP 'sudo systemctl status openclaw.service'
```

**Expected result:** Status shows `Active: active (running)`.

---

## 4. Access the Agent UI (SSH Tunnel)

The agent UI is only accessible via an SSH tunnel (it is NOT exposed to the network):

```bash
# Create tunnel — runs in the foreground, keep it open
ssh -L 18789:localhost:18789 your-vm-user@YOUR_VM_IP

# In a second terminal — verify the tunnel works
curl http://localhost:18789/health
```

**Expected result:** A JSON response like `{"status":"ok"}`.

Then open your browser at: **<http://localhost:18789>**

---

## 5. Verify Everything Works

```bash
# Quick status summary
echo "=== Agent Status ==="
ssh your-vm-user@YOUR_VM_IP 'sudo systemctl status openclaw.service --no-pager'

echo "=== Port Check ==="
ssh your-vm-user@YOUR_VM_IP 'ss -tlnp | grep 18789'
```

**Expected result:** Port 18789 is listed as `LISTEN` and bound to `127.0.0.1` (not `0.0.0.0`).

---

## Troubleshooting

### `ansible-playbook` fails with "unreachable"

1. Verify your VM IP in `inventory.ini`
2. Test SSH connection manually: `ssh your-vm-user@YOUR_VM_IP`
3. Make sure your SSH key is configured — see Module 4

### `openclaw: command not found`

```bash
# Use the full path
/opt/openclaw/node_modules/.bin/openclaw --version

# Or reload the shell environment
source ~/.bashrc
```

### Gateway shows "Unauthorized"

The gateway token was not set during onboarding. Fix it:

```bash
# As the openclaw user on the VM:
TOKEN=$(openssl rand -base64 32)
sed -i 's|"token": "[^"]*"|"token": "'"$TOKEN"'"|' ~/.openclaw/openclaw.json
echo "Your token: $TOKEN"
```

---

*For detailed architecture, see `01_Architecture/System_Architecture.md`.*
