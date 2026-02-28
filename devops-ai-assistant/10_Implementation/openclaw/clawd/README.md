# OpenClaw Bot Configuration

This repository contains the configuration files that define the personality, behavior, and capabilities of my personal OpenClaw AI assistant bot.

## 🤖 What is OpenClaw?

OpenClaw is an open-source AI assistant framework that provides a conversational interface with various integrations and tools. This repository backs up the bot's core configuration that makes it uniquely mine.

## 📁 Repository Structure

- **AGENTS.md** - Agent definitions and configurations
- **BOOTSTRAP.md** - Bootstrap configuration for initial setup
- **HEARTBEAT.md** - Heartbeat and health check settings
- **IDENTITY.md** - Bot identity and persona configuration
- **SOUL.md** - Core personality, behavior rules, and response patterns
- **TOOLS.md** - Tool configurations and integrations
- **USER.md** - User-specific information and preferences

## 🔒 Privacy & Security

**This is a PRIVATE repository** containing:
- Personal bot configurations
- User preferences and information
- Custom behavior patterns

**Do NOT make this repository public** as it may contain sensitive configuration details.

## 🚀 Deployment

This configuration is deployed on a VPS and automatically synced from  on the server.

### How to Update Configuration

1. SSH into the VPS
2. Edit files in 
3. Commit changes: `git add -A && git commit -m "description"`
4. Push to backup: `git push origin master`

## � Accessing the Web UI (VPS to Local)

If you are running OpenClaw on a VPS and want to access the Web UI on your local machine:

### 1. Create an SSH Tunnel
Run this command from your **local computer** terminal:

```bash
ssh -L 18789:localhost:18789 openclaw@46.225.60.55
```

### 2. Launch the Dashboard
Inside the SSH session (on the VPS), run:

```bash
openclaw dashboard --no-open
```

### 3. Open in Browser
Copy the generated URL (e.g., `http://localhost:18789/?token=...`) and open it in the browser on your **local computer**.

## �🔄 Backup & Recovery

This repository serves as a backup for the bot's configuration. In case of server issues or accidental changes:

1. Clone this repository
2. Copy files to `/home/openclaw/clawd/`
3. Restart the OpenClaw service

## 📝 Version History

- **2026-01-31** - Initial commit with base OpenClaw configuration

## 🎯 Related Projects

This bot is part of the **My AI Assistant** project ecosystem:
- **Generalist Agent**: OpenClaw (this configuration)
- **Specialized Agent**: Python-based domain expert for health and finance
- **Main Project**: [My_AI_Assistant](https://github.com/sobol-mo/My_AI_Assistant)

---

**Last Updated**: 2026-01-31
