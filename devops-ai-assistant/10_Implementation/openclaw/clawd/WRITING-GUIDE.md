WRITING-GUIDE.md

Universal standards for all content

Applies to: skills docs Telegram messages email Notion tasks daily logs documentation

Markdown Rules:
Applies ONLY to external/UI content (Docs, Telegram, Email, Tasks)
Internal Files Rule: NO MARKDOWN in memory/*.md, skills/*/*/SKILL.md, HEARTBEAT.md
- Strip: # ## - * ``` emoji ** _
- Reason: minimize tokens for startup/heartbeat loading

Header Spacing: blank line BEFORE headers (External only)
Refactoring: ALWAYS git commit before major refactor. Discuss huge logic changes with Maxim first. Less formatting != less logic.
Lists: use - or bullet (External only)
Code: triple backticks with lang hint (External only)
Emphasis: bold for headers key terms (External only)

Context-Specific:

Skills SKILL.md:
- Command-focused not explanation-focused
- Terse prose 1-2 sentences max per section
- One example per pattern
- Verbose details to REFERENCE.md
- Structure: SKILL.md CONFIG.md REFERENCE.md LESSONS.md
- Frontmatter: name description metadata
- Targets: simple 50-80 lines, medium 80-120, complex 120-150, >150 refactor
- Examples: /opt/openclaw/node_modules/openclaw/skills/

Telegram:
- NO markdown tables (mobile unreadable)
- Emoji-rich bullets bold headers
- Short lines vertical layout
- Model footer: \n\n---\n[Model: model_name]
- Voice/audio for stories long explanations
- See skills/communication/managing-telegram-messaging/SKILL.md

Email:
- Professional clear
- Subject specific
- Brief intro purpose first sentence
- Short paragraphs 2-3 sentences
- Lists for multiple points
- Bold action items
- One idea per paragraph

Notion Tasks:
- What: clear description
- Why: context if not obvious
- How: steps if multi-step
- Blockers: dependencies obstacles
- Links: URLs files references
- Front-load critical info
- Bold headers
- Error messages verbatim
- See skills/planning-tasks/managing-notion-tasks/SKILL.md

Daily Memory Logs memory/YYYY-MM-DD.md:
- Raw capture events decisions lessons
- Chronological
- Brief notes not essays
- Decisions with context
- Link related files/tasks

Long-Term Memory MEMORY.md:
- Curated distilled knowledge
- Config values (Notion IDs API paths)
- Decisions reasoning
- User preferences
- Lessons from daily logs
- NOT temporary state (heartbeat-state.json)
- NOT daily details (daily logs)
- NOT workflows (skills)
- Structured sections key-value format brief explanations references

Principles:
Clarity > Cleverness: say what you mean directly, avoid jargon, define acronyms first use
Brevity: one idea per sentence, one topic per paragraph, cut unnecessary words
Consistency: follow rules across contexts, match existing style, check bundled skills/docs when uncertain
Scannability: headers break long content, lists for related items, bold key terms, white space
Anti-Verbosity: answer the question asked, don't create documentation to show work, 3 sentences > 3 documents
Verify First: test feature exists before documenting, 5min verification > hours wasted docs


Checklist:
- Headers blank line before
- Lists formatted consistently
- No verbosity
- Context-appropriate style
- Required elements present
- Links/references included
- Grammar spelling checked

References:
- docs.openclaw.ai/tools/skills
- agentskills.io
- markdownguide.org/basic-syntax
- /opt/openclaw/node_modules/openclaw/skills/
