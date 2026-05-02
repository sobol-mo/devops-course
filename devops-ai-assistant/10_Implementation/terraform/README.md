# Infrastructure as Code: Development VM Setup

**Created:** 2026-02-07  
**Purpose:** Implement IaC approach for local development environment  
**Status:** Ready to deploy

---

## 🎯 Overview

This directory contains **Infrastructure as Code** configuration for creating a local development VM on your Linux Mint machine. This follows the same IaC principles you've already implemented for production infrastructure.

### Your Existing IaC Stack

```
Production Infrastructure (Hetzner Cloud)
├── Terraform (main.tf)
│   └── Provisions VPS server
└── Ansible (playbook-openclaw-setup.yml)
    └── Configures OpenClaw on VPS

Development Infrastructure (Local Machine) ← NEW!
├── Vagrant (Vagrantfile)
│   └── Provisions local VM
└── Shell Provisioning (inline)
    └── Configures OpenClaw in VM
```

---

## 📚 What We've Created

### 1. Core Files

| File | Purpose | IaC Tool |
|------|---------|----------|
| `Vagrantfile` | VM definition and provisioning | Vagrant |
| `README.md` | Complete documentation | - |
| `QUICK_START.md` | Step-by-step guide | - |
| `.gitignore` | Prevent committing secrets | - |

### 2. Helper Scripts

| Script | Purpose |
|--------|---------|
| `scripts/sync_config.sh` | Sync config from production to dev |

### 3. Documentation

| Document | Content |
|----------|---------|
| `README.md` | Architecture, comparison, DevOps integration |
| `QUICK_START.md` | 30-minute setup guide |

---

## 🏗️ Architecture Comparison

### Production (Hetzner Cloud)

```
Terraform → Hetzner API → VPS Created
    ↓
Ansible → SSH to VPS → OpenClaw Configured
    ↓
Production Bot Running
```

### Development (Local VM)

```
Vagrant → VirtualBox API → VM Created
    ↓
Shell Provisioning → VM → OpenClaw Configured
    ↓
Development Bot Running
```

**Both are Infrastructure as Code!**

---

## 🎓 DevOps Course Value

This setup demonstrates multiple IaC approaches:

### 1. Cloud Infrastructure (Production)
- **Tool:** Terraform
- **Provider:** Hetzner Cloud
- **Use Case:** Production VPS
- **Cost:** ~€4/month
- **Lesson:** Cloud infrastructure provisioning

### 2. Local Infrastructure (Development)
- **Tool:** Vagrant
- **Provider:** VirtualBox (or KVM)
- **Use Case:** Development VM
- **Cost:** $0 (local)
- **Lesson:** Local development environments

### 3. Configuration Management (Both)
- **Tool:** Ansible (production) / Shell (dev)
- **Use Case:** Software installation and configuration
- **Lesson:** Idempotent configuration

### Student Learning Path

```
Week 1: Manual VM creation (understand the basics)
Week 2: Vagrant (automate VM creation)
Week 3: Ansible (automate configuration)
Week 4: Terraform (cloud infrastructure)
Week 5: Complete pipeline (IaC end-to-end)
```

---

## 🚀 Quick Start

### Prerequisites

```bash
# On your Linux Mint machine
sudo apt update
sudo apt install -y vagrant virtualbox
```

### Create Development VM

```bash
# Navigate to this directory
cd ~/clawd/My_AI_Assistant/10_Implementation/openclaw/terraform-vm

# Create and provision VM (one command!)
vagrant up

# Wait 10-15 minutes for:
# - Ubuntu download (~700 MB, first time only)
# - VM creation
# - Node.js installation
# - OpenClaw installation
```

### Access VM

```bash
# SSH to VM
vagrant ssh

# Switch to openclaw user
sudo su - openclaw

# Run onboarding
openclaw onboard
```

### Configure Antigravity

```bash
# Get SSH config
vagrant ssh-config >> ~/.ssh/config

# In Antigravity:
# Ctrl+Shift+P → "Remote-SSH: Connect to Host" → "default"
# Open folder: /home/openclaw/clawd
```

---

## 📊 Comparison: Terraform vs Vagrant

| Aspect | Terraform (Production) | Vagrant (Development) |
|--------|----------------------|---------------------|
| **Best For** | Cloud infrastructure | Local VMs |
| **Providers** | AWS, Azure, GCP, Hetzner | VirtualBox, VMware, KVM |
| **State Management** | Remote state (S3, etc.) | Local .vagrant directory |
| **Cost** | Pay for cloud resources | Free (local) |
| **Speed** | Network-dependent | Fast (local) |
| **Collaboration** | Shared state | Individual VMs |
| **Use Case** | Production, staging | Development, testing |

**Both are valid IaC tools!** Use the right tool for the job.

---

## 🔄 Workflow Integration

### Development Workflow

```
1. Start VM
   ├── vagrant up
   └── VM boots with OpenClaw ready

2. Develop
   ├── Antigravity → SSH → VM
   ├── Edit code in ~/clawd
   └── Test with dev Telegram bot

3. Commit
   ├── git add .
   ├── git commit -m "..."
   └── git push origin feature/xyz

4. Deploy
   ├── SSH to production VPS
   ├── git pull origin main
   └── Restart if needed

5. Stop VM
   └── vagrant halt (free resources)
```

### Infrastructure Updates

```
# Update VM configuration
1. Edit Vagrantfile
2. vagrant reload --provision
3. Test changes
4. Commit Vagrantfile to Git

# Destroy and recreate (clean slate)
1. vagrant destroy
2. vagrant up
3. Fresh environment in minutes!
```

---

## 🔒 Security Considerations

### VM Isolation

```
Linux Mint Host
├── Your files (protected)
├── Your browser (protected)
└── Development VM (sandboxed)
    ├── Can't access host files (unless shared)
    ├── Separate network namespace
    └── Easy to destroy and recreate
```

### Credentials Separation

| Environment | Bot Token | Config | Data |
|------------|-----------|--------|------|
| **Production** | Production token | Production config | Real user data |
| **Development** | DEV token | Dev config | Test data only |

**Never use production credentials in development!**

---

## 📈 Expected Results

### Before (Current State)

```
Production VPS:
├── RAM: 3.4 GB / 3.7 GB (92% ⚠️)
├── Antigravity: 2 GB
├── OpenClaw Prod: 0.9 GB
└── System: 0.5 GB

Development: Same VPS (risky!)
```

### After (Separated Environments)

```
Production VPS:
├── RAM: 1.4 GB / 3.7 GB (38% ✅)
├── OpenClaw Prod: 0.9 GB
└── System: 0.5 GB

Development VM (Local):
├── RAM: 2 GB (from your Linux Mint)
├── OpenClaw Dev: 0.9 GB
└── System: 0.3 GB

Antigravity: Runs on Linux Mint host
```

**Benefits:**
- ✅ Production VPS: 60% more RAM available
- ✅ Development: Isolated, safe to experiment
- ✅ Workflow: Same Antigravity SSH workflow
- ✅ Cost: $0 (local VM)
- ✅ Speed: Fast (no network latency)

---

## 🛠️ Customization

### Change VM Resources

Edit `Vagrantfile`:

```ruby
config.vm.provider "virtualbox" do |vb|
  vb.memory = "4096"  # Increase to 4 GB
  vb.cpus = 4         # Increase to 4 cores
end
```

Then reload:

```bash
vagrant reload
```

### Add Shared Folder

Edit `Vagrantfile`:

```ruby
# Share your projects folder
config.vm.synced_folder "~/projects", "/home/openclaw/projects"
```

### Use KVM Instead of VirtualBox

```bash
# Install KVM
sudo apt install -y qemu-kvm libvirt-daemon-system

# Install vagrant-libvirt plugin
vagrant plugin install vagrant-libvirt

# Use KVM provider
vagrant up --provider=libvirt
```

---

## 📝 Maintenance

### Update OpenClaw in VM

```bash
# SSH to VM
vagrant ssh
sudo su - openclaw

# Update OpenClaw
cd /opt/openclaw
npm update openclaw

# Restart gateway
pkill -f openclaw-gateway
openclaw-gateway &
```

### Backup VM State

```bash
# Save snapshot
vagrant snapshot save before-major-update

# List snapshots
vagrant snapshot list

# Restore if needed
vagrant snapshot restore before-major-update
```

### Clean Up

```bash
# Stop VM (keeps disk)
vagrant halt

# Destroy VM (delete everything)
vagrant destroy

# Remove downloaded box (free disk space)
vagrant box remove ubuntu/jammy64
```

---

## 🎯 Next Steps

### Immediate (Today)

1. ✅ Review the Vagrantfile
2. ✅ Run `vagrant up`
3. ✅ Configure Antigravity SSH
4. ✅ Create dev Telegram bot
5. ✅ Start developing!

### Short-term (This Week)

1. Close Antigravity on production VPS
2. Monitor production VPS RAM (should drop to ~40%)
3. Develop a feature in VM
4. Deploy to production

### Long-term (This Month)

1. Add automated testing
2. Create deployment scripts
3. Implement CI/CD pipeline
4. Document for DevOps course

---

## 🆘 Troubleshooting

### Vagrant Issues

```bash
# Vagrant not found
sudo apt install vagrant

# VirtualBox not found
sudo apt install virtualbox

# VM won't start
sudo /sbin/vboxconfig  # Reinstall kernel modules
vagrant reload

# SSH issues
vagrant ssh-config  # Check SSH configuration
```

### OpenClaw Issues

```bash
# OpenClaw not found
vagrant ssh
sudo su - openclaw
source ~/.bashrc
openclaw --version

# Gateway won't start
# Check if port is already in use
netstat -tlnp | grep 18789
```

---

## 📚 Additional Resources

### Documentation

- [Vagrant Documentation](https://www.vagrantup.com/docs)
- [VirtualBox Manual](https://www.virtualbox.org/manual/)
- [Ansible Documentation](https://docs.ansible.com/)
- [OpenClaw Documentation](https://openclaw.dev/)

### Your Existing IaC

- Production Terraform: `../python/terraform/`
- Production Ansible: `../ansible/`
- Production README: `../README.md`

---

## ✅ Success Criteria

You'll know this is working when:

- [ ] `vagrant up` creates VM successfully
- [ ] Can SSH to VM with `vagrant ssh`
- [ ] OpenClaw installed and working in VM
- [ ] Development Telegram bot responds
- [ ] Antigravity connects to VM via SSH
- [ ] Can edit code in VM via Antigravity
- [ ] Production VPS RAM usage drops to ~40%
- [ ] Can develop without affecting production

---

## 🎉 Conclusion

You now have:

1. **Infrastructure as Code** for both production and development
2. **Separated environments** (dev vs prod)
3. **Reproducible setup** (Vagrantfile + Ansible)
4. **DevOps teaching material** (multiple IaC approaches)
5. **Stable production** (60% more RAM available)
6. **Safe development** (isolated VM)

**Total setup time:** ~30 minutes  
**Total cost:** $0  
**Total benefit:** Huge! 🚀

---

**Ready to start?** → See `QUICK_START.md`

**Questions?** → Just ask!

**Want to compare VirtualBox vs KVM?** → Great DevOps lesson!
