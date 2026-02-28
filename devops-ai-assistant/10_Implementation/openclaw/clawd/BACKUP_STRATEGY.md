# Backup Strategy Documentation

**Last Updated:** February 13, 2026
**Author:** Calen
**Purpose:** Comprehensive backup strategy for OpenClaw bot and home directory

---

## Overview

The OpenClaw bot (clawd) has access to the full home directory (`/home/openclaw`). Backups are stored in `clawd/backups/` before being uploaded to Google Drive. This document ensures proper exclusions to prevent recursive backup issues.

---

## Backup Architecture

### Primary Backup Location
```
/home/openclaw/clawd/backups/
├── openclaw-full/      # Complete bot workspace + configuration + SQLite
└── home-full/          # Full home directory backup (if needed)
```

### Cloud Storage
- **Destination:** Google Drive (`gdrive:/OpenClaw-Backups/`)
- **Tool:** rclone
- **Retention:**
  - Local: 14 days
  - Google Drive: 60-90 days depending on backup type

---

## Current Backup Scripts

### 1. **backup_openclaw_full.sh** (PRIMARY - COMPREHENSIVE)
**Location:** `/home/openclaw/clawd/scripts/backup_openclaw_full.sh`

**Backs up:**
- ✅ SQLite database (`/home/openclaw/.openclaw/memory/main.sqlite`)
- ✅ Clawd workspace (excluding: logs, .git, My_AI_Assistant, backups)
- ✅ Essential configurations from `.openclaw/`:
  - `openclaw.json`
  - `.env`
  - `processed_emails.json`
  - `credentials/` directory
  - `agents/` directory
  - `identity/` directory
  - `settings/` directory

**Process:**
1. Integrity check on SQLite database
2. Safe hot backup of database using SQLite `.backup` command
3. Rsync workspace with exclusions
4. Copy configurations
5. Create compressed tar.gz archive
6. Upload to `gdrive:/OpenClaw-Backups/full`
7. Clean up old backups (14 days local, 60 days cloud)

**Usage:**
```bash
/home/openclaw/clawd/scripts/backup_openclaw_full.sh
```

**Recommendation:** Use this as the PRIMARY backup script. Run daily via cron.

---

### 2. **backup_vector_memory.sh** (REDUNDANT)
**Status:** ⚠️ Redundant - SQLite already backed up in `backup_openclaw_full.sh`

**Can be:**
- Deprecated (recommended)
- OR kept for quick incremental SQLite-only backups between full backups

---

### 3. **backup_openclaw_json.sh** (REDUNDANT)
**Status:** ⚠️ Redundant - openclaw.json already backed up in `backup_openclaw_full.sh`

**Can be:**
- Deprecated (recommended)
- OR kept for emergency quick config backups to `.openclaw/local_backup_openclaw_json/`

---

### 4. **manual_backup.sh** (DEPRECATED)
**Status:** ❌ Uses PostgreSQL (wrong database type)

**Recommendation:** DELETE or replace with call to `backup_openclaw_full.sh`

---

## Critical Exclusion Rules

### ⚠️ ALWAYS EXCLUDE FROM BACKUPS

When creating ANY backup that includes the clawd directory or home directory:

```bash
--exclude '/home/openclaw/clawd/backups'
--exclude '/home/openclaw/backups'
--exclude '/home/openclaw/clawd/logs'
--exclude '/home/openclaw/clawd/.git'
--exclude '/home/openclaw/clawd/My_AI_Assistant'
--exclude '/home/openclaw/clawd/.venv'
--exclude '/home/openclaw/.cache'
--exclude '/home/openclaw/.local/share/Trash'
--exclude '/home/openclaw/.antigravity-server'
--exclude '/home/openclaw/.gemini'
```

### Why These Exclusions?

1. **backups/** - Prevents recursive backup explosion
2. **logs/** - Temporary files, grow indefinitely, not critical
3. **.git/** - Version control, redundant with GitHub
4. **My_AI_Assistant/** - Large project directory, has its own repository
5. **.venv/** - Python virtual environments, can be recreated
6. **.cache/** - Temporary cache files
7. **Trash/** - Deleted files
8. **.antigravity-server/** - IDE server cache
9. **.gemini/** - Cache directories

---

## Recommended Backup Schedule

### Option 1: Single Comprehensive Backup (Recommended)
```cron
# Daily full backup at 3 AM
0 3 * * * /home/openclaw/clawd/scripts/backup_openclaw_full.sh
```

### Option 2: Full + Incremental SQLite
```cron
# Daily full backup at 3 AM
0 3 * * * /home/openclaw/clawd/scripts/backup_openclaw_full.sh

# Incremental SQLite every 6 hours
0 */6 * * * /home/openclaw/clawd/scripts/backup_vector_memory.sh
```

---

## Disaster Recovery

### Restore from Backup

1. **Download from Google Drive:**
```bash
rclone copy "gdrive:/OpenClaw-Backups/full/openclaw-full-TIMESTAMP.tar.gz" /tmp/
```

2. **Extract archive:**
```bash
cd /tmp
tar -xzf openclaw-full-TIMESTAMP.tar.gz
```

3. **Restore SQLite database:**
```bash
cp /tmp/openclaw-full-TIMESTAMP/main.sqlite /home/openclaw/.openclaw/memory/
```

4. **Restore clawd workspace:**
```bash
rsync -av /tmp/openclaw-full-TIMESTAMP/clawd/ /home/openclaw/clawd/
```

5. **Restore configurations:**
```bash
cp -r /tmp/openclaw-full-TIMESTAMP/dot-openclaw/* /home/openclaw/.openclaw/
```

6. **Verify integrity:**
```bash
sqlite3 /home/openclaw/.openclaw/memory/main.sqlite "PRAGMA integrity_check;"
```

---

## Home Directory Full Backup

For complete system backup including home directory, use `backup_home_full.sh` (see next section).

### What's Included:
- All home directory contents
- All hidden files and configurations
- Excludes: backups/, large caches, temporary files

### What's Excluded:
- Backup directories (prevent recursion)
- Cache directories
- Virtual environments
- Large project repositories with their own backups

---

## Monitoring and Verification

### Check Backup Status
```bash
# View backup logs
tail -f /home/openclaw/clawd/logs/backup_openclaw_full.log

# List local backups
ls -lh /home/openclaw/clawd/backups/openclaw-full/

# List Google Drive backups
rclone ls "gdrive:/OpenClaw-Backups/full"
```

### Verify Backup Integrity
```bash
# Test archive
tar -tzf /home/openclaw/clawd/backups/openclaw-full/openclaw-full-TIMESTAMP.tar.gz > /dev/null

# Check SQLite integrity (if extracted)
sqlite3 /path/to/backup/main.sqlite "PRAGMA integrity_check;"
```

---

## Storage Management

### Current Usage
```bash
# Check local backup size
du -sh /home/openclaw/clawd/backups/

# Check Google Drive usage
rclone size "gdrive:/OpenClaw-Backups/"
```

### Cleanup
Automatic cleanup is configured in scripts:
- **Local:** 14 days retention
- **Google Drive:** 60-90 days retention

Manual cleanup if needed:
```bash
# Remove backups older than 7 days
find /home/openclaw/clawd/backups/openclaw-full/ -name "*.tar.gz" -mtime +7 -delete
```

---

## Security Considerations

1. **Encryption:** Backups contain sensitive data (credentials, .env files)
   - ⚠️ Currently stored unencrypted on Google Drive
   - Consider encrypting archives before upload

2. **Access Control:**
   - Google Drive access via rclone OAuth token
   - Token stored in `~/.config/rclone/rclone.conf`

3. **Sensitive Files Included:**
   - `.openclaw/.env` (API keys)
   - `.openclaw/credentials/` (OAuth tokens, passwords)
   - `.openclaw/openclaw.json` (configuration with secrets)

**Recommendation:** Implement GPG encryption for backups before Google Drive upload.

---

## Best Practices

1. ✅ **Test restores regularly** - Verify backups are actually recoverable
2. ✅ **Monitor backup logs** - Check for failures
3. ✅ **Verify archive integrity** - Ensure tar.gz files are not corrupted
4. ✅ **Keep multiple backup generations** - Don't rely on single backup
5. ✅ **Document restore procedures** - Ensure recovery is possible
6. ✅ **Exclude temporary and cache directories** - Keep backups lean
7. ⚠️ **Never backup the backups directory** - Prevents recursive explosion

---

## Quick Reference Commands

```bash
# Manual full backup
/home/openclaw/clawd/scripts/backup_openclaw_full.sh

# Manual home backup
/home/openclaw/clawd/scripts/backup_home_full.sh

# List backups
ls -lh /home/openclaw/clawd/backups/openclaw-full/

# View logs
tail -f /home/openclaw/clawd/logs/backup_openclaw_full.log

# Check Google Drive
rclone ls "gdrive:/OpenClaw-Backups/full"

# Download latest backup
rclone copy "gdrive:/OpenClaw-Backups/full" /tmp/restore/ --max-age 24h
```

---

## Changelog

- **2026-02-13:** Initial documentation created
  - Consolidated backup strategy
  - Identified redundant scripts
  - Documented exclusion rules
  - Added disaster recovery procedures
