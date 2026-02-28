# Quick Start: Create Development VM with Vagrant

**Time Required:** 15-20 minutes  
**Difficulty:** Easy  
**Prerequisites:** VirtualBox installed on Linux Mint

---

## Step-by-Step Guide

### Step 1: Install Vagrant (5 minutes)

```bash
# On your Linux Mint machine
sudo apt update
sudo apt install -y vagrant

# Verify installation
vagrant --version
# Should show: Vagrant 2.x.x
```

### Step 2: Navigate to VM Directory (1 minute)

```bash
# Go to the terraform-vm directory
cd ~/clawd/My_AI_Assistant/10_Implementation/openclaw/terraform-vm

# Or if you're on the VPS, you need to do this on your Linux Mint machine:
# First, pull the latest code from GitHub
cd /path/to/your/local/clawd
git pull origin main
cd My_AI_Assistant/10_Implementation/openclaw/terraform-vm
```

### Step 3: Create and Start VM (10 minutes)

```bash
# This single command will:
# - Download Ubuntu 22.04 image (~700 MB, first time only)
# - Create VM with 2GB RAM, 2 CPUs
# - Install Node.js 18
# - Install OpenClaw
# - Set up openclaw user
vagrant up
```

**What you'll see:**
```
Bringing machine 'default' up with 'virtualbox' provider...
==> default: Importing base box 'ubuntu/jammy64'...
==> default: Matching MAC address for NAT networking...
==> default: Setting the name of the VM: openclaw-dev
==> default: Forwarding ports...
    default: 18789 (guest) => 18790 (host)
    default: 22 (guest) => 2222 (host)
==> default: Running provisioner: shell...
    default: Installing Node.js 18...
    default: Installing OpenClaw...
    default: OpenClaw installation complete!
```

### Step 4: SSH to VM (1 minute)

```bash
# Easy way (Vagrant handles everything)
vagrant ssh

# You're now in the VM!
vagrant@openclaw-dev:~$

# Switch to openclaw user
sudo su - openclaw

# Read welcome message
cat ~/WELCOME.txt
```

### Step 5: Run OpenClaw Onboarding (5 minutes)

```bash
# As openclaw user in the VM
openclaw onboard

# Follow the prompts:
# 1. Model: Choose "Google Antigravity" (use your Gemini subscription)
# 2. Workspace: Default ~/clawd (press Enter)
# 3. Gateway: Port 18789, localhost (127.0.0.1), token auth
# 4. Channels: Telegram (you'll need a DEV bot token)
```

### Step 6: Create Development Telegram Bot (5 minutes)

**On your phone/computer (Telegram):**

1. Open Telegram
2. Search for `@BotFather`
3. Send: `/newbot`
4. Name: `YourBotName DEV` (e.g., "OpenClaw DEV")
5. Username: `your_bot_dev_bot` (must end in 'bot')
6. **Copy the token** (e.g., `1234567890:ABCdef...`)

**Back in the VM:**

```bash
# Edit OpenClaw config
nano ~/.openclaw/openclaw.json

# Find the line with "botToken" and paste your DEV bot token
# Save: Ctrl+X, Y, Enter
```

### Step 7: Clone Your Projects (2 minutes)

```bash
# Still as openclaw user in VM
cd ~/clawd

# Clone your repository
git clone https://github.com/YOUR_USERNAME/clawd.git .

# Or if you have SSH keys set up:
# git clone git@github.com:YOUR_USERNAME/clawd.git .
```

### Step 8: Start OpenClaw Gateway (1 minute)

```bash
# In VM, as openclaw user
openclaw-gateway

# You should see:
# OpenClaw Gateway starting...
# Listening on http://127.0.0.1:18789
```

### Step 9: Test Development Bot (1 minute)

1. Open Telegram
2. Search for your DEV bot
3. Send: `/start`
4. Bot should respond!

### Step 10: Configure Antigravity Remote-SSH (5 minutes)

**On your Linux Mint machine (host):**

```bash
# Get VM SSH configuration
cd ~/clawd/My_AI_Assistant/10_Implementation/openclaw/terraform-vm
vagrant ssh-config

# You'll see something like:
# Host default
#   HostName 127.0.0.1
#   User vagrant
#   Port 2222
#   IdentityFile /path/to/.vagrant/machines/default/virtualbox/private_key
```

**Add to your SSH config:**

```bash
# Append to your SSH config
vagrant ssh-config >> ~/.ssh/config

# Or manually add:
cat >> ~/.ssh/config << 'EOF'

Host openclaw-dev
    HostName 127.0.0.1
    User vagrant
    Port 2222
    IdentityFile ~/.vagrant.d/insecure_private_key
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
EOF
```

**In Antigravity:**

1. Press `Ctrl+Shift+P`
2. Type: "Remote-SSH: Connect to Host"
3. Select: `openclaw-dev` (or `default`)
4. Wait for connection
5. Open folder: `/home/openclaw/clawd`

**You're now editing code in the VM via Antigravity!**

---

## Verification Checklist

- [ ] Vagrant installed (`vagrant --version`)
- [ ] VM created and running (`vagrant status`)
- [ ] Can SSH to VM (`vagrant ssh`)
- [ ] OpenClaw installed (`openclaw --version`)
- [ ] Development bot created (Telegram @BotFather)
- [ ] OpenClaw config updated with dev bot token
- [ ] clawd repository cloned in VM
- [ ] OpenClaw gateway running
- [ ] Dev bot responds in Telegram
- [ ] Antigravity connects to VM via SSH
- [ ] Can edit files in VM via Antigravity

---

## Daily Workflow

### Starting Your Day

```bash
# On Linux Mint host
cd ~/clawd/My_AI_Assistant/10_Implementation/openclaw/terraform-vm

# Start VM (if not running)
vagrant up

# Open Antigravity
# Connect to openclaw-dev via Remote-SSH
# Open folder: /home/openclaw/clawd

# Start coding!
```

### Ending Your Day

```bash
# Save your work in Antigravity
# Commit and push to Git

# Stop VM to free resources
vagrant halt
```

### Making Changes

```bash
# In VM (via Antigravity terminal)
cd ~/clawd

# Make changes to code
# Test with dev bot

# Commit
git add .
git commit -m "Add new feature"
git push origin feature/new-skill
```

### Deploying to Production

```bash
# After testing in dev VM, deploy to production VPS
ssh openclaw@PRODUCTION_VPS
cd ~/clawd
git pull origin main

# Restart if needed
```

---

## Useful Commands

### VM Management

```bash
# Start VM
vagrant up

# Stop VM (graceful shutdown)
vagrant halt

# Restart VM
vagrant reload

# SSH to VM
vagrant ssh

# Check VM status
vagrant status

# Destroy VM (delete completely)
vagrant destroy

# Re-run provisioning (reinstall everything)
vagrant provision
```

### Snapshots (Backups)

```bash
# Save current state
vagrant snapshot save working-state

# List snapshots
vagrant snapshot list

# Restore to saved state
vagrant snapshot restore working-state

# Delete snapshot
vagrant snapshot delete working-state
```

### Troubleshooting

```bash
# Check VirtualBox VMs
vboxmanage list vms

# Check running VMs
vboxmanage list runningvms

# Validate Vagrantfile
vagrant validate

# Verbose output
vagrant up --debug
```

---

## Resource Usage

**Disk Space:**
- Ubuntu image: ~700 MB (downloaded once)
- VM disk: ~5 GB (grows as you use it, max 20 GB)
- Total: ~6 GB

**RAM:**
- VM uses 2 GB when running
- Returns to host when VM is stopped

**CPU:**
- 2 cores allocated (shared with host)
- Only used when VM is running

---

## Comparison: Before vs After

### Before (Production VPS Overloaded)

```
Production VPS:
├── OpenClaw Production: 900 MB
├── Antigravity: 2000 MB
└── System: 500 MB
Total: 3.4 GB / 3.7 GB (92% ⚠️)
```

### After (Separated Environments)

```
Production VPS:
├── OpenClaw Production: 900 MB
└── System: 500 MB
Total: 1.4 GB / 3.7 GB (38% ✅)

Linux Mint (Your Machine):
└── Development VM: 2 GB (only when running)
    ├── OpenClaw DEV
    └── All development work
```

---

## Next Steps

1. ✅ **VM is running** - You have a development environment!
2. 🔄 **Clean up production VPS** - Close Antigravity on VPS
3. 📚 **Start developing** - Use VM for all development work
4. 🚀 **Deploy when ready** - Push to Git, pull on production

---

## Need Help?

### Common Issues

**VM won't start:**
```bash
# Check VirtualBox is running
systemctl status vboxdrv

# Reinstall VirtualBox kernel modules
sudo /sbin/vboxconfig
```

**Can't SSH to VM:**
```bash
# Check VM is running
vagrant status

# Try reloading
vagrant reload
```

**OpenClaw not found:**
```bash
# SSH to VM
vagrant ssh

# Switch to openclaw user
sudo su - openclaw

# Reload bashrc
source ~/.bashrc

# Or use full path
/opt/openclaw/node_modules/.bin/openclaw --version
```

---

## Success! 🎉

You now have:
- ✅ Isolated development environment
- ✅ Production VPS freed up (60% more RAM available)
- ✅ Same Antigravity workflow
- ✅ Safe place to experiment
- ✅ Infrastructure as Code (Vagrantfile)
- ✅ Great example for DevOps course!

**Total time:** ~30 minutes  
**Benefit:** Huge improvement in stability and workflow!
