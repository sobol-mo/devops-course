# HEARTBEAT.md

Execute checks, log status to memory/heartbeat.log, and reply HEARTBEAT_OK if nothing found.

Rules:
- SILENCE POLICY: If nothing needs attention, reply ONLY: HEARTBEAT_OK. IMPORTANT: You must still execute the log command before replying.
- NIGHT SILENCE: Skip all checks between 23:00 and 06:00 Kiev. If CURRENT_HOUR >= 23 or < 06, exit immediately.
- Log every heartbeat: echo "$(date '+%Y-%m-%d %H:%M:%S') - Status: OK [Model: {model}]" >> memory/heartbeat.log
- No changes → HEARTBEAT_OK (suppress Telegram notifications, save tokens)
- No overthinking, just execute
- Report only: tasks completed, events created, updates available, errors
- Critical errors (OAuth/sudo/blockers) → Create Notion task in AI_Assistant project (ID: 2fb76162-6176-812b-b542-d708f462927a) + report
- Don't check twice, just run once, trust result
- Minimize tokens, execute fast

## Daily (14:00 Kiev)
OpenClaw Updates:
- Check: CURRENT_HOUR == 14
- Check memory/heartbeat-state.json lastChecks.openclaw_updates > 1 day or null
- Fetch: https://api.github.com/repos/openclaw/openclaw/releases/latest (get tag_name)
- Compare GitHub tag vs lastKnownVersion in heartbeat-state.json
- If GitHub newer: Create Notion task "Update OpenClaw to v{Version}" under AI_Assistant (ID: 2fb76162-6176-812b-b542-d708f462927a), update lastKnownVersion in state
- If Installed > Running (check session_status): Send Telegram message to 447702171 that restart is needed
- NEVER run safe-update-patched.sh, force_restart.sh, or any restart/update script — these require Maxim's manual action
- Update timestamp: python3 -c "import json,time; s=json.load(open('memory/heartbeat-state.json')); s['lastChecks']['openclaw_updates']=int(time.time()); json.dump(s,open('memory/heartbeat-state.json','w'),indent=2)"
- Report only, never HEARTBEAT_OK

## Every Heartbeat
Context Monitoring:
- Check: python3 scripts/check_context_limit.py
- Report (NOT HEARTBEAT_OK)

Cron Health:
- Check: python3 skills/dev-system/cron-health-check/scripts/check_cron.py
- Report issues (NOT HEARTBEAT_OK)
- Automated fix: if "disallowed model", update jobs.json to google-antigravity/gemini-3-flash and restart gateway

Autonomous Tasks:
- Query: python3 skills/planning-tasks/managing-notion-tasks/scripts/query_tasks.py --project "Calen ToDo" --status "To Do" --limit 1
- Move In Progress: python3 skills/planning-tasks/managing-notion-tasks/scripts/update_status.py <page_id> "In Progress"
- Execute task
- Capture output + verify completion
- Success: python3 skills/planning-tasks/managing-notion-tasks/scripts/complete_task.py complete <page_id> "result" "verification proof"
- Failure: python3 skills/planning-tasks/managing-notion-tasks/scripts/complete_task.py pend <page_id> "blocker reason"
- Report: "✅ Completed [name]: [result]" or "⚠️ Pended: [name]. Blocker: [reason]"
- NEVER HEARTBEAT_OK when task processed
- NEVER use update_status.py for Done/PENDED - complete_task.py enforces verification
- See skills/planning-tasks/autonomous-task-execution/VERIFICATION-PROTOCOL.md

Email Monitoring:
- Maxim forwards invites to ceocalen@gmail.com → auto calendar
- Only read from sobol.mo@gmail.com, Maksym.Sobol@khpi.edu.ua
- Check: gog gmail messages search "is:unread (from:sobol.mo@gmail.com OR from:Maksym.Sobol@khpi.edu.ua)" --max 5 --account ceocalen@gmail.com
- Filter keywords приглашение мероприятие invitation event date/time
- Parse: title date time location description
- Create event ceocalen@gmail.com calendar
- Mark read
- Report (NOT HEARTBEAT_OK)

## Weekly
Memory Maintenance:
- Check memory/heartbeat-state.json lastChecks.memory_maintenance > 7 days or null
- Review recent memory/YYYY-MM-DD.md distill to MEMORY.md clean outdated update timestamp

Disk Maintenance:
- Check memory/heartbeat-state.json lastChecks.disk_maintenance > 7 days or null
- Run: bash scripts/disk_maintenance.sh
- CRITICAL (exit 2): Report immediately, create Notion task in AI_Assistant
- WARNING (exit 1): Report + cleaned items
- OK with cleaned items (exit 0, output non-empty): Report what was cleaned
- OK nothing to clean: HEARTBEAT_OK silently, update timestamp
- Update timestamp: python3 -c "import json,time; s=json.load(open('memory/heartbeat-state.json')); s['lastChecks']['disk_maintenance']=int(time.time()); json.dump(s,open('memory/heartbeat-state.json','w'),indent=2)"

Disk Alert (daily, state-gated):
- Check memory/heartbeat-state.json lastChecks.disk_alert > 1 day or null
- DISK_PCT=$(df / | awk 'NR==2 {print $5}' | tr -d '%')
- If DISK_PCT >= 85: Report CRITICAL (NOT HEARTBEAT_OK), create Notion task in AI_Assistant
- If DISK_PCT >= 80: Report WARNING (NOT HEARTBEAT_OK)
- Update timestamp: python3 -c "import json,time; s=json.load(open('memory/heartbeat-state.json')); s['lastChecks']['disk_alert']=int(time.time()); json.dump(s,open('memory/heartbeat-state.json','w'),indent=2)"

State: memory/heartbeat-state.json timestamps
