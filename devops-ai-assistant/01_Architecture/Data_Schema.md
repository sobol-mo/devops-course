# Data Schema: My AI Assistant

**Version**: 1.0  
**Date**: 2026-01-15  
**Database**: PostgreSQL (Supabase) + pgvector

---

## 1. Schema Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                          CORE DOMAIN SCHEMAS                         │
├─────────────────────────────────────────────────────────────────────┤
│  users          │   Central user table                               │
├─────────────────────────────────────────────────────────────────────┤
│  HEALTH DOMAIN                                                       │
│  ├── medications                                                     │
│  ├── medication_events                                               │
│  ├── titration_schedules                                             │
│  ├── symptoms                                                        │
│  ├── daily_reflections                                               │
│  └── diet_changes                                                    │
├─────────────────────────────────────────────────────────────────────┤
│  FINANCE DOMAIN                                                      │
│  ├── expense_categories                                              │
│  └── expenses                                                        │
├─────────────────────────────────────────────────────────────────────┤
│  MEMORY DOMAIN                                                       │
│  ├── thoughts                                                        │
│  ├── rules                                                           │
│  ├── thought_embeddings (pgvector)                                   │
│  └── rule_embeddings (pgvector)                                      │
├─────────────────────────────────────────────────────────────────────┤
│  KNOWLEDGE GRAPH DOMAIN                                              │
│  ├── entities                                                        │
│  ├── entity_attributes                                               │
│  ├── relationships                                                   │
│  ├── entity_media                                                    │
│  └── entity_thought_links                                            │
├─────────────────────────────────────────────────────────────────────┤
│  PRODUCTIVITY DOMAIN                                                 │
│  ├── calendar_events                                                 │
│  ├── reminders                                                       │
│  └── priority_topics                                                 │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 2. Core Tables

### 2.1 users

Central user table (supports future multi-user).

```sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    telegram_id BIGINT UNIQUE NOT NULL,
    username VARCHAR(64),
    first_name VARCHAR(128),
    last_name VARCHAR(128),
    language_code VARCHAR(5) DEFAULT 'ru',
    timezone VARCHAR(50) DEFAULT 'Europe/Kiev',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_users_telegram_id ON users(telegram_id);
```

---

## 3. Health Domain

### 3.1 medications

Master table for medication/supplement registry.

```sql
CREATE TABLE medications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    name_normalized VARCHAR(255), -- lowercase for search
    type VARCHAR(50) DEFAULT 'medication', -- medication, supplement, other
    default_unit VARCHAR(20) DEFAULT 'mg',
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT unique_medication_per_user UNIQUE (user_id, name_normalized)
);

CREATE INDEX idx_medications_user ON medications(user_id);
CREATE INDEX idx_medications_name ON medications(name_normalized);
```

### 3.2 medication_events

Timeline of medication changes (immutable event log).

```sql
CREATE TYPE medication_event_type AS ENUM (
    'start',           -- Начал принимать
    'stop',            -- Прекратил принимать
    'dose_change',     -- Изменил дозировку
    'manufacturer_change', -- Сменил производителя
    'note'             -- Заметка о препарате
);

CREATE TABLE medication_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    medication_id UUID REFERENCES medications(id) ON DELETE CASCADE,
    event_type medication_event_type NOT NULL,
    event_date DATE NOT NULL, -- Дата события
    
    -- Дозировка (для start, dose_change)
    dose_amount DECIMAL(10,2),
    dose_unit VARCHAR(20),
    
    -- Производитель (для start, manufacturer_change)
    manufacturer VARCHAR(255),
    
    -- Комментарий
    notes TEXT,
    
    -- Метаданные
    raw_input TEXT, -- Оригинальный текст пользователя
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_med_events_user ON medication_events(user_id);
CREATE INDEX idx_med_events_medication ON medication_events(medication_id);
CREATE INDEX idx_med_events_date ON medication_events(event_date);
CREATE INDEX idx_med_events_type ON medication_events(event_type);
```

### 3.3 titration_schedules

Complex dosing protocols with phases.

```sql
CREATE TABLE titration_schedules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    medication_id UUID REFERENCES medications(id) ON DELETE CASCADE,
    name VARCHAR(255), -- "Вход в магний", "Выход из препарата"
    start_date DATE NOT NULL,
    status VARCHAR(20) DEFAULT 'active', -- active, completed, cancelled
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE titration_phases (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    schedule_id UUID REFERENCES titration_schedules(id) ON DELETE CASCADE,
    phase_order INT NOT NULL,
    duration_days INT NOT NULL,
    dose_amount DECIMAL(10,2) NOT NULL,
    dose_unit VARCHAR(20) NOT NULL,
    start_date DATE NOT NULL, -- Calculated from schedule start
    end_date DATE NOT NULL,
    reminder_t2_sent BOOLEAN DEFAULT FALSE,
    reminder_t0_sent BOOLEAN DEFAULT FALSE,
    calendar_event_id VARCHAR(255), -- Google Calendar event ID
    
    CONSTRAINT unique_phase_order UNIQUE (schedule_id, phase_order)
);

CREATE INDEX idx_titration_user ON titration_schedules(user_id);
CREATE INDEX idx_titration_phases_schedule ON titration_phases(schedule_id);
CREATE INDEX idx_titration_phases_dates ON titration_phases(start_date, end_date);
```

### 3.4 symptoms

Subjective health logging.

```sql
CREATE TABLE symptoms (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    logged_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    symptom_text TEXT NOT NULL, -- "Чувствую усталость"
    severity INT CHECK (severity BETWEEN 1 AND 10), -- 1-10 scale
    category VARCHAR(50), -- physical, mental, emotional
    notes TEXT,
    raw_input TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_symptoms_user ON symptoms(user_id);
CREATE INDEX idx_symptoms_date ON symptoms(logged_at);
```

### 3.5 daily_reflections

End-of-day mental load and stress tracking.

```sql
CREATE TABLE daily_reflections (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    reflection_date DATE NOT NULL,
    mental_load INT CHECK (mental_load BETWEEN 1 AND 10), -- 1-10
    stress_level INT CHECK (stress_level BETWEEN 1 AND 10), -- 1-10
    energy_level INT CHECK (energy_level BETWEEN 1 AND 10), -- 1-10
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT unique_daily_reflection UNIQUE (user_id, reflection_date)
);

CREATE INDEX idx_reflections_user ON daily_reflections(user_id);
CREATE INDEX idx_reflections_date ON daily_reflections(reflection_date);
```

### 3.6 diet_changes

Diet product introduction/removal tracking.

```sql
CREATE TYPE diet_event_type AS ENUM ('introduce', 'remove', 'note');

CREATE TABLE diet_changes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    event_date DATE NOT NULL,
    event_type diet_event_type NOT NULL,
    product_name VARCHAR(255) NOT NULL,
    product_category VARCHAR(100), -- dairy, gluten, supplement, etc.
    notes TEXT,
    raw_input TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_diet_user ON diet_changes(user_id);
CREATE INDEX idx_diet_date ON diet_changes(event_date);
```

---

## 4. Finance Domain

### 4.1 expense_categories

User-defined expense categories.

```sql
CREATE TABLE expense_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    name_normalized VARCHAR(100),
    parent_id UUID REFERENCES expense_categories(id), -- Hierarchical
    icon VARCHAR(20), -- Emoji for display
    color VARCHAR(7), -- Hex color
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT unique_category_per_user UNIQUE (user_id, name_normalized)
);

-- Default categories for new users
-- INSERT: еда, транспорт, здоровье, развлечения, коммуналка, etc.
```

### 4.2 expenses

Financial transaction log.

```sql
CREATE TABLE expenses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    category_id UUID REFERENCES expense_categories(id),
    amount DECIMAL(12,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'UAH',
    description TEXT,
    expense_date DATE NOT NULL,
    vendor VARCHAR(255),
    raw_input TEXT,
    receipt_media_id UUID, -- Link to media storage
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_expenses_user ON expenses(user_id);
CREATE INDEX idx_expenses_date ON expenses(expense_date);
CREATE INDEX idx_expenses_category ON expenses(category_id);
```

---

## 5. Memory Domain

### 5.1 thoughts

Episodic memory storage.

```sql
CREATE TABLE thoughts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    logged_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    tags TEXT[], -- Array of semantic tags
    location_lat DECIMAL(10,7),
    location_lon DECIMAL(10,7),
    mood VARCHAR(50), -- Optional mood capture
    raw_input TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_thoughts_user ON thoughts(user_id);
CREATE INDEX idx_thoughts_date ON thoughts(logged_at);
CREATE INDEX idx_thoughts_tags ON thoughts USING GIN(tags);
```

### 5.2 rules

Behavioral rules for LLM injection.

```sql
CREATE TABLE rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    category VARCHAR(50), -- personality, preference, constraint
    is_active BOOLEAN DEFAULT TRUE,
    priority INT DEFAULT 0, -- Higher = more important
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_rules_user ON rules(user_id);
CREATE INDEX idx_rules_active ON rules(is_active);
```

### 5.3 Vector Embeddings (pgvector)

```sql
-- Enable pgvector extension
CREATE EXTENSION IF NOT EXISTS vector;

CREATE TABLE thought_embeddings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    thought_id UUID REFERENCES thoughts(id) ON DELETE CASCADE UNIQUE,
    embedding vector(1536), -- OpenAI ada-002 dimension
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_thought_embeddings ON thought_embeddings 
    USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);

CREATE TABLE rule_embeddings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    rule_id UUID REFERENCES rules(id) ON DELETE CASCADE UNIQUE,
    embedding vector(1536),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_rule_embeddings ON rule_embeddings 
    USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);
```

---

## 6. Knowledge Graph Domain

### 6.1 entities

Core entity storage (people, places, organizations).

```sql
CREATE TYPE entity_type AS ENUM ('person', 'place', 'organization', 'event', 'other');

CREATE TABLE entities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    entity_type entity_type NOT NULL,
    name VARCHAR(255) NOT NULL,
    name_normalized VARCHAR(255),
    description TEXT,
    birth_date DATE, -- For persons
    death_date DATE, -- For persons
    latitude DECIMAL(10,7), -- For places
    longitude DECIMAL(10,7), -- For places
    is_deleted BOOLEAN DEFAULT FALSE, -- Soft delete for versioning
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_entities_user ON entities(user_id);
CREATE INDEX idx_entities_type ON entities(entity_type);
CREATE INDEX idx_entities_name ON entities(name_normalized);
```

### 6.2 entity_attributes

Flexible key-value attributes for entities.

```sql
CREATE TABLE entity_attributes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entity_id UUID REFERENCES entities(id) ON DELETE CASCADE,
    attribute_key VARCHAR(100) NOT NULL,
    attribute_value TEXT NOT NULL,
    valid_from DATE, -- Temporal validity
    valid_to DATE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_entity_attrs ON entity_attributes(entity_id);
```

### 6.3 relationships

Typed edges between entities.

```sql
CREATE TYPE relationship_type AS ENUM (
    -- Family
    'parent_of', 'child_of', 'spouse_of', 'sibling_of',
    -- Professional
    'worked_at', 'employed', 'colleague_of',
    -- Location
    'born_in', 'lives_in', 'located_in',
    -- Other
    'knows', 'member_of', 'owns', 'related_to'
);

CREATE TABLE relationships (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    source_entity_id UUID REFERENCES entities(id) ON DELETE CASCADE,
    target_entity_id UUID REFERENCES entities(id) ON DELETE CASCADE,
    relationship_type relationship_type NOT NULL,
    description TEXT,
    valid_from DATE,
    valid_to DATE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT no_self_relationship CHECK (source_entity_id != target_entity_id)
);

CREATE INDEX idx_rel_source ON relationships(source_entity_id);
CREATE INDEX idx_rel_target ON relationships(target_entity_id);
CREATE INDEX idx_rel_type ON relationships(relationship_type);
```

### 6.4 entity_media

Photos and images attached to entities.

```sql
CREATE TABLE entity_media (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entity_id UUID REFERENCES entities(id) ON DELETE CASCADE,
    media_type VARCHAR(20) DEFAULT 'image', -- image, document
    file_path TEXT NOT NULL, -- Storage path
    file_name VARCHAR(255),
    mime_type VARCHAR(50),
    caption TEXT,
    is_primary BOOLEAN DEFAULT FALSE, -- Primary photo
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_entity_media ON entity_media(entity_id);
```

### 6.5 entity_thought_links

Links between thoughts and entities.

```sql
CREATE TABLE entity_thought_links (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entity_id UUID REFERENCES entities(id) ON DELETE CASCADE,
    thought_id UUID REFERENCES thoughts(id) ON DELETE CASCADE,
    link_type VARCHAR(50) DEFAULT 'mentioned', -- mentioned, about, by
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT unique_entity_thought UNIQUE (entity_id, thought_id)
);

CREATE INDEX idx_etl_entity ON entity_thought_links(entity_id);
CREATE INDEX idx_etl_thought ON entity_thought_links(thought_id);
```

---

## 7. Productivity Domain

### 7.1 calendar_events

Internal calendar event storage.

```sql
CREATE TABLE calendar_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ,
    all_day BOOLEAN DEFAULT FALSE,
    location TEXT,
    conference_link TEXT, -- Zoom, Meet link
    source VARCHAR(50), -- manual, email, titration
    source_reference_id UUID, -- Link to titration_phase, etc.
    google_event_id VARCHAR(255), -- Google Calendar sync
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_calendar_user ON calendar_events(user_id);
CREATE INDEX idx_calendar_time ON calendar_events(start_time);
```

### 7.2 reminders

Scheduled notification storage.

```sql
CREATE TYPE reminder_type AS ENUM (
    'titration_t2',    -- 2 дня до смены дозы
    'titration_t0',    -- День смены дозы
    'daily_reflection', -- Ежедневная рефлексия
    'morning_briefing', -- Утренняя сводка
    'custom'           -- Пользовательское
);

CREATE TABLE reminders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    reminder_type reminder_type NOT NULL,
    scheduled_at TIMESTAMPTZ NOT NULL,
    message TEXT NOT NULL,
    reference_id UUID, -- Link to source (titration_phase, etc.)
    is_sent BOOLEAN DEFAULT FALSE,
    sent_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_reminders_user ON reminders(user_id);
CREATE INDEX idx_reminders_scheduled ON reminders(scheduled_at);
CREATE INDEX idx_reminders_pending ON reminders(is_sent, scheduled_at);
```

### 7.3 priority_topics

User-defined priority topics for chat filtering.

```sql
CREATE TABLE priority_topics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    topic VARCHAR(100) NOT NULL,
    keywords TEXT[], -- Related keywords for matching
    is_active BOOLEAN DEFAULT TRUE,
    priority INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_topics_user ON priority_topics(user_id);
```

---

## 8. Helper Views

### 8.1 Active Medications View

```sql
CREATE VIEW active_medications AS
SELECT 
    m.id,
    m.user_id,
    m.name,
    e.dose_amount,
    e.dose_unit,
    e.manufacturer,
    e.event_date as started_at
FROM medications m
JOIN medication_events e ON m.id = e.medication_id
WHERE e.event_type = 'start'
AND NOT EXISTS (
    SELECT 1 FROM medication_events e2
    WHERE e2.medication_id = m.id
    AND e2.event_type = 'stop'
    AND e2.event_date > e.event_date
);
```

### 8.2 Upcoming Reminders View

```sql
CREATE VIEW upcoming_reminders AS
SELECT *
FROM reminders
WHERE is_sent = FALSE
AND scheduled_at > NOW()
ORDER BY scheduled_at ASC;
```

---

## 9. Seed Data

### Default Expense Categories

```sql
INSERT INTO expense_categories (user_id, name, name_normalized, icon) VALUES
(NULL, 'Еда', 'еда', '🍔'),
(NULL, 'Транспорт', 'транспорт', '🚗'),
(NULL, 'Здоровье', 'здоровье', '💊'),
(NULL, 'Развлечения', 'развлечения', '🎬'),
(NULL, 'Коммуналка', 'коммуналка', '🏠'),
(NULL, 'Одежда', 'одежда', '👕'),
(NULL, 'Связь', 'связь', '📱'),
(NULL, 'Другое', 'другое', '📦');
```

---

## 10. Migration Strategy

1. **Development**: Fresh schema creation
2. **Production**: Apply migrations in order
3. **Versioning**: Track in `/01_Architecture/migrations/`

---

*This schema supports all functional requirements from System_Requirements.md.*
