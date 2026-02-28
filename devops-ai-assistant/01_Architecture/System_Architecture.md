# System Architecture Overview

**Version**: 2.0 (Python Branch - Dual-Agent)
**Date**: 2026-01-26
**Status**: Active Implementation
**Decision**: BUILD (see [Phase2_Synthesis_Decision_Gate.md](../00_Strategy_and_Design/Research/Phase2_Synthesis_Decision_Gate.md))

---

## 1. Architecture Principles

| Principle | Description | Rationale |
|-----------|-------------|-----------|
| **Data Sovereignty**    | All user data in self-controlled storage          | BO-1 requirement          |
| **Modular Agents**     | Each domain as independent agent                  | Extensibility (FR-EXT-001) |
| **Telegram-Native**    | Conversational UX over visual UI                  | User familiarity           |
| **Local-First**        | Prefer local processing for sensitive data         | Privacy                    |
| **Export Always**      | JSON/CSV export from day one                      | BO-1, BO-6                 |
| **Commit-Recall-Verify** | Every action confirmed from DB                  | FR-UIP-001                 |

---

## 2. Design Patterns (Technology-Agnostic)

### 2.1 Hexagonal Architecture (Ports & Adapters)

**Concept**: Separate business logic from infrastructure concerns through clear boundaries.

```text
┌─────────────────────────────────┐
│     Inbound Adapters            │  (Telegram, Web UI, API, CLI)
│  (How users interact)           │
└────────────┬────────────────────┘
             │
┌────────────▼────────────────────┐
│     Application Layer           │  (Use cases, orchestration)
│  (What the system does)         │
└────────────┬────────────────────┘
             │
┌────────────▼────────────────────┐
│     Domain Layer                │  (Pure business logic)
│  (Core rules & entities)        │  • NO external dependencies
└────────────┬────────────────────┘  • NO framework coupling
             │                        • Technology-agnostic
┌────────────▼────────────────────┐
│     Outbound Adapters           │  (Database, LLM APIs, Email, etc.)
│  (How system talks to world)    │
└─────────────────────────────────┘
```

---

## 3. High-Level Architecture (Dual-Agent)

The system is composed of two distinct, specialized agents operating in parallel to serve the user.

```text
┌─────────────────────────────────────────────────────────────────────────┐
│                           USER INTERFACES                                │
├───────────────────────────────────┬─────────────────────────────────────┤
│   Telegram Bot A (ClawdBot)       │    Telegram Bot B (Python Core)     │
│   "The Secretary"                 │    "The Specialist"                 │
└─────────────────┬─────────────────┴──────────────────┬──────────────────┘
                  │                                    │
                  ▼                                    ▼
┌───────────────────────────────────┐  ┌───────────────────────────────────┐
│   Generalist Domain Agent         │  │   Specialized Domain Expert       │
│   (ClawdBot / TypeScript)         │  │   (Python / Hexagonal)            │
├───────────────────────────────────┤  ├───────────────────────────────────┤
│                                   │  │                                   │
│  ┌──────────────┐ ┌────────────┐  │  │  ┌──────────────┐ ┌────────────┐  │
│  │ Productivity │ │  General   │  │  │  │ Health Agent │ │ Finance    │  │
│  │    Skill     │ │   Skill    │  │  │  │              │ │   Agent    │  │
│  └──────────────┘ └────────────┘  │  │  └──────────────┘ └────────────┘  │
│         │               │         │  │         │               │         │
│  ┌──────▼───────┐ ┌─────▼──────┐  │  │  ┌──────▼───────┐ ┌─────▼──────┐  │
│  │ Gmail Integ. │ │ Calendar   │  │  │  │ Medication   │ │  Ledger    │  │
│  └──────────────┘ └────────────┘  │  │  │   Service    │ │  Service   │  │
│                                   │  │  └──────────────┘ └────────────┘  │
│                                   │  │                                   │
└─────────────────┬─────────────────┘  └──────────────────┬────────────────┘
                  │                                       │
                  │                                       ▼
                  │                    ┌───────────────────────────────────┐
                  │                    │            DATA LAYER             │
                  │                    ├───────────────────────────────────┤
                  └───────────────────►│      Supabase (PostgreSQL)        │
                                       │                                   │
                                       │  • Health Records (Medications)   │
                                       │  • Financial Ledger               │
                                       │  • Knowledge Graph (Genealogy)    │
                                       │  • Domain Rules (pgvector)        │
                                       └───────────────────────────────────┘
```

---

## 4. Technology Stack (Specialized Domain Expert: Python Core)

| Layer | Technology | Rationale |
|-------|------------|-----------|
| **Architecture**  | Hexagonal (Ports & Adapters)      | Clean separation, testability, extensibility |
| **Language**      | Python 3.11+                      | Async support, rich ecosystem, type hints    |
| **Bot Framework**  | aiogram 3.x                       | Modern async Telegram bot framework          |
| **Database**      | Supabase (PostgreSQL)             | Free tier, self-hostable, RLS support        |
| **ORM**           | SQLAlchemy 2.0 (async)            | Type-safe, async-first, mature ecosystem     |
| **Vector Store**  | pgvector                          | Native PostgreSQL extension                  |
| **Configuration**  | Pydantic Settings                 | Type-safe config with validation             |
| **Testing**       | pytest + pytest-asyncio           | Industry standard, async support             |
| **Userbot**       | Pyrogram                          | MTProto access for chat filtering            |

### LLM Selection (Cost-Optimized)

| Model | Recommendation |
|-------|----------------|
| **Gemini 1.5 Flash** | ✅ Primary — Best price/performance ratio   |
| **OpenAI GPT-4o**    | Fallback — If needed for complex reasoning |

---

## 5. Agent Responsibilities

### 5.1 Generalist Domain Agent: ClawdBot Responsibilities (Delegated)

* **Calendar**: "Schedule a meeting with X."
* **Email**: "Summarize the email from my boss."
* **Reminders**: "Remind me to call the bank tomorrow."
* **Web**: "Search for the latest news on X."
* **Episodic Memory**: "Write down this thought: ..."

### 5.2 Specialized Domain Expert: Python Core Responsibilities (In Scope)

* **Domain Logic**:
  * Execute business-critical operations with strict validation.
  * Ensure ACID-compliant data persistence (no silent failures).
* **Analytics**:
  * Generate structured reports from stored data.
  * Aggregate and correlate events over time.
* **Retrospective**:
  * Answer complex queries by correlating historical data from the database.

---

## 6. Deployment Options

### Option A: Dual Container (Recommended)

Run both systems as separate services in one `docker-compose.yml`.

```yaml
services:
  clawdbot:
    image: clawdbot:latest
    volumes:
      - ./clawd_data:/root/clawd
    environment:
      - OPENAI_API_KEY=...

  python_core:
    build: ./python_core
    depends_on:
      - db
    environment:
      - DATABASE_URL=...
```
