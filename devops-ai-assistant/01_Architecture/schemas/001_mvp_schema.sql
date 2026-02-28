-- Migration: 001_mvp_schema.sql
-- Description: MVP database schema for My AI Assistant
-- Date: 2026-01-16 (Updated)
-- Compatible with: PostgreSQL 14+ with pgvector extension

-- =============================================================================
-- 0. EXTENSIONS
-- =============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS vector;

-- =============================================================================
-- 1. CORE TABLES
-- =============================================================================

-- Users table
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    telegram_id BIGINT UNIQUE NOT NULL,
    username VARCHAR(64),
    first_name VARCHAR(128),
    last_name VARCHAR(128),
    language_code VARCHAR(5) DEFAULT 'ru',
    timezone VARCHAR(50) DEFAULT 'Europe/Kiev',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_users_telegram_id ON users(telegram_id);

-- =============================================================================
-- 2. HEALTH DOMAIN
-- =============================================================================

-- Medications registry
CREATE TABLE IF NOT EXISTS medications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    name_normalized VARCHAR(255),
    type VARCHAR(50) DEFAULT 'medication', -- medication, supplement, other
    default_unit VARCHAR(20) DEFAULT 'mg',
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT unique_medication_per_user UNIQUE (user_id, name_normalized)
);

CREATE INDEX IF NOT EXISTS idx_medications_user ON medications(user_id);
CREATE INDEX IF NOT EXISTS idx_medications_name ON medications(name_normalized);

-- Medication events (immutable log)
DO $$ BEGIN
    CREATE TYPE medication_event_type AS ENUM (
        'start',
        'stop',
        'dose_change',
        'manufacturer_change',
        'note'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

CREATE TABLE IF NOT EXISTS medication_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    medication_id UUID REFERENCES medications(id) ON DELETE CASCADE,
    event_type medication_event_type NOT NULL,
    event_date DATE NOT NULL,
    dose_amount DECIMAL(10,2),
    dose_unit VARCHAR(20),
    manufacturer VARCHAR(255),
    notes TEXT,
    raw_input TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_med_events_user ON medication_events(user_id);
CREATE INDEX IF NOT EXISTS idx_med_events_medication ON medication_events(medication_id);
CREATE INDEX IF NOT EXISTS idx_med_events_date ON medication_events(event_date);
CREATE INDEX IF NOT EXISTS idx_med_events_type ON medication_events(event_type);

-- Symptoms log
CREATE TABLE IF NOT EXISTS symptoms (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    logged_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    symptom_text TEXT NOT NULL,
    severity INT CHECK (severity BETWEEN 1 AND 10),
    category VARCHAR(50), -- physical, mental, emotional
    notes TEXT,
    raw_input TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_symptoms_user ON symptoms(user_id);
CREATE INDEX IF NOT EXISTS idx_symptoms_date ON symptoms(logged_at);

-- Diet changes
DO $$ BEGIN
    CREATE TYPE diet_event_type AS ENUM ('introduce', 'remove', 'note');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

CREATE TABLE IF NOT EXISTS diet_changes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    event_date DATE NOT NULL,
    event_type diet_event_type NOT NULL,
    product_name VARCHAR(255) NOT NULL,
    product_category VARCHAR(100),
    notes TEXT,
    raw_input TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_diet_user ON diet_changes(user_id);
CREATE INDEX IF NOT EXISTS idx_diet_date ON diet_changes(event_date);

-- =============================================================================
-- 3. FINANCE DOMAIN (Updated: Income + Expenses)
-- =============================================================================

-- Financial transaction type
DO $$ BEGIN
    CREATE TYPE fin_transaction_type AS ENUM ('income', 'expense');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Financial categories (supports both income and expense)
CREATE TABLE IF NOT EXISTS fin_categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    transaction_type fin_transaction_type NOT NULL,
    name VARCHAR(100) NOT NULL,
    name_normalized VARCHAR(100),
    parent_id UUID REFERENCES fin_categories(id),  -- For hierarchy (Еда → молочные продукты)
    icon VARCHAR(20),
    color VARCHAR(7),
    is_default BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT unique_fin_category_per_user UNIQUE (user_id, transaction_type, name_normalized)
);

CREATE INDEX IF NOT EXISTS idx_fin_categories_user ON fin_categories(user_id);
CREATE INDEX IF NOT EXISTS idx_fin_categories_type ON fin_categories(transaction_type);

-- Currencies reference table (fiat + crypto)
CREATE TABLE IF NOT EXISTS currencies (
    code VARCHAR(10) PRIMARY KEY,        -- UAH, USD, EUR, BTC, ETH, USDT
    name VARCHAR(100) NOT NULL,
    symbol VARCHAR(10),                   -- ₴, $, €, ₿, Ξ
    type VARCHAR(10) NOT NULL,            -- fiat, crypto
    decimals INT DEFAULT 2,               -- 2 for fiat, 8 for most crypto
    is_active BOOLEAN DEFAULT TRUE
);

-- Seed common currencies
INSERT INTO currencies (code, name, symbol, type, decimals) VALUES
    ('UAH', 'Ukrainian Hryvnia', '₴', 'fiat', 2),
    ('USD', 'US Dollar', '$', 'fiat', 2),
    ('EUR', 'Euro', '€', 'fiat', 2),
    ('BTC', 'Bitcoin', '₿', 'crypto', 8),
    ('ETH', 'Ethereum', 'Ξ', 'crypto', 8),
    ('USDT', 'Tether', '₮', 'crypto', 6),
    ('USDC', 'USD Coin', '$', 'crypto', 6)
ON CONFLICT (code) DO NOTHING;

-- Accounts/Wallets table (where money is stored)
CREATE TABLE IF NOT EXISTS fin_accounts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,           -- "Monobank UAH", "Binance", "Cold Wallet"
    account_type VARCHAR(20) NOT NULL,    -- bank, exchange, wallet, cash
    currency VARCHAR(10) REFERENCES currencies(code),
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_fin_accounts_user ON fin_accounts(user_id);

-- Financial transactions (income + expenses combined) - MULTI-CURRENCY
CREATE TABLE IF NOT EXISTS fin_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    category_id UUID REFERENCES fin_categories(id),
    account_id UUID REFERENCES fin_accounts(id),    -- Which account/wallet
    
    -- Transaction type and amount
    transaction_type fin_transaction_type NOT NULL,
    amount DECIMAL(18,8) NOT NULL,        -- Higher precision for crypto
    currency VARCHAR(10) DEFAULT 'UAH',   -- Extended for crypto codes
    transaction_date DATE NOT NULL,
    
    -- Description (hybrid approach)
    item_name VARCHAR(255),               -- Specific item: "хлеб и молоко", "зарплата за январь"
    description TEXT,                     -- Additional comment/notes
    
    -- Counterparty (vendor for expense, source for income)
    counterparty VARCHAR(255),            -- АТБ, Employer, Client name, etc.
    
    -- Metadata for tracking input source
    input_method VARCHAR(20),             -- text, voice, photo
    raw_input TEXT,
    
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_fin_transactions_user ON fin_transactions(user_id);

CREATE INDEX IF NOT EXISTS idx_fin_transactions_date ON fin_transactions(transaction_date);
CREATE INDEX IF NOT EXISTS idx_fin_transactions_type ON fin_transactions(transaction_type);
CREATE INDEX IF NOT EXISTS idx_fin_transactions_category ON fin_transactions(category_id);

-- =============================================================================
-- 4. MEMORY DOMAIN
-- =============================================================================

-- Thoughts (episodic memory)
CREATE TABLE IF NOT EXISTS thoughts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    logged_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    tags TEXT[],
    location_lat DECIMAL(10,7),
    location_lon DECIMAL(10,7),
    mood VARCHAR(50),
    raw_input TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_thoughts_user ON thoughts(user_id);
CREATE INDEX IF NOT EXISTS idx_thoughts_date ON thoughts(logged_at);
CREATE INDEX IF NOT EXISTS idx_thoughts_tags ON thoughts USING GIN(tags);

-- Rules (behavioral rules for LLM)
CREATE TABLE IF NOT EXISTS rules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    category VARCHAR(50), -- personality, preference, constraint
    is_active BOOLEAN DEFAULT TRUE,
    priority INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_rules_user ON rules(user_id);
CREATE INDEX IF NOT EXISTS idx_rules_active ON rules(is_active);

-- Thought embeddings (pgvector)
CREATE TABLE IF NOT EXISTS thought_embeddings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    thought_id UUID REFERENCES thoughts(id) ON DELETE CASCADE UNIQUE,
    embedding vector(1536), -- OpenAI text-embedding-ada-002
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Rule embeddings (pgvector)
CREATE TABLE IF NOT EXISTS rule_embeddings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    rule_id UUID REFERENCES rules(id) ON DELETE CASCADE UNIQUE,
    embedding vector(1536),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================================================
-- 5. HELPER VIEWS
-- =============================================================================

-- Active medications view
CREATE OR REPLACE VIEW active_medications AS
SELECT 
    m.id,
    m.user_id,
    m.name,
    m.type,
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
)
AND NOT EXISTS (
    SELECT 1 FROM medication_events e3
    WHERE e3.medication_id = m.id
    AND e3.event_type = 'start'
    AND e3.event_date > e.event_date
);

-- Monthly financial summary view
CREATE OR REPLACE VIEW fin_monthly_summary AS
SELECT 
    user_id,
    DATE_TRUNC('month', transaction_date) as month,
    transaction_type,
    SUM(amount) as total_amount,
    COUNT(*) as transaction_count
FROM fin_transactions
GROUP BY user_id, DATE_TRUNC('month', transaction_date), transaction_type;

-- =============================================================================
-- 6. SEED DATA: Default financial categories
-- =============================================================================

-- Function to create default categories for new users
CREATE OR REPLACE FUNCTION create_default_fin_categories(p_user_id UUID)
RETURNS void AS $$
BEGIN
    -- Expense categories
    INSERT INTO fin_categories (user_id, transaction_type, name, name_normalized, icon, is_default)
    VALUES 
        (p_user_id, 'expense', 'Еда', 'еда', '🍔', TRUE),
        (p_user_id, 'expense', 'Транспорт', 'транспорт', '🚗', TRUE),
        (p_user_id, 'expense', 'Здоровье', 'здоровье', '💊', TRUE),
        (p_user_id, 'expense', 'Развлечения', 'развлечения', '🎬', TRUE),
        (p_user_id, 'expense', 'Коммуналка', 'коммуналка', '🏠', TRUE),
        (p_user_id, 'expense', 'Одежда', 'одежда', '👕', TRUE),
        (p_user_id, 'expense', 'Связь', 'связь', '📱', TRUE),
        (p_user_id, 'expense', 'Другое', 'другое', '📦', TRUE);
    
    -- Income categories
    INSERT INTO fin_categories (user_id, transaction_type, name, name_normalized, icon, is_default)
    VALUES 
        (p_user_id, 'income', 'Зарплата', 'зарплата', '💰', TRUE),
        (p_user_id, 'income', 'Фриланс', 'фриланс', '💼', TRUE),
        (p_user_id, 'income', 'Подарок', 'подарок', '🎁', TRUE),
        (p_user_id, 'income', 'Инвестиции', 'инвестиции', '📈', TRUE),
        (p_user_id, 'income', 'Другое', 'другое', '📦', TRUE);
END;
$$ LANGUAGE plpgsql;

-- Trigger to create default categories for new users
CREATE OR REPLACE FUNCTION trigger_create_default_fin_categories()
RETURNS TRIGGER AS $$
BEGIN
    PERFORM create_default_fin_categories(NEW.id);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS tr_user_created_fin_categories ON users;
CREATE TRIGGER tr_user_created_fin_categories
    AFTER INSERT ON users
    FOR EACH ROW
    EXECUTE FUNCTION trigger_create_default_fin_categories();

-- =============================================================================
-- 7. ROW LEVEL SECURITY (RLS)
-- =============================================================================

-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE medications ENABLE ROW LEVEL SECURITY;
ALTER TABLE medication_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE symptoms ENABLE ROW LEVEL SECURITY;
ALTER TABLE diet_changes ENABLE ROW LEVEL SECURITY;
ALTER TABLE fin_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE fin_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE thoughts ENABLE ROW LEVEL SECURITY;
ALTER TABLE rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE thought_embeddings ENABLE ROW LEVEL SECURITY;
ALTER TABLE rule_embeddings ENABLE ROW LEVEL SECURITY;

-- =============================================================================
-- 8. UPDATED_AT TRIGGER
-- =============================================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS tr_users_updated_at ON users;
CREATE TRIGGER tr_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS tr_medications_updated_at ON medications;
CREATE TRIGGER tr_medications_updated_at
    BEFORE UPDATE ON medications
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS tr_rules_updated_at ON rules;
CREATE TRIGGER tr_rules_updated_at
    BEFORE UPDATE ON rules
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =============================================================================
-- 9. CLEANUP: Drop old expenses table if exists
-- =============================================================================

-- Uncomment this line to drop the old expenses table:
-- DROP TABLE IF EXISTS expenses CASCADE;

-- =============================================================================
-- END OF MIGRATION
-- =============================================================================

COMMENT ON TABLE users IS 'User profiles, linked to Telegram accounts';
COMMENT ON TABLE medications IS 'Master registry of medications and supplements';
COMMENT ON TABLE medication_events IS 'Immutable log of medication changes';
COMMENT ON TABLE symptoms IS 'Subjective health symptom logging';
COMMENT ON TABLE diet_changes IS 'Diet product additions and removals';
COMMENT ON TABLE fin_categories IS 'Financial transaction categories (income + expense)';
COMMENT ON TABLE fin_transactions IS 'Financial transaction log (income + expense)';
COMMENT ON TABLE thoughts IS 'Episodic memory storage';
COMMENT ON TABLE rules IS 'Behavioral rules for LLM injection';
COMMENT ON TABLE thought_embeddings IS 'Vector embeddings for semantic thought search';
COMMENT ON TABLE rule_embeddings IS 'Vector embeddings for semantic rule search';
