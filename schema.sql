-- ============================================================
-- VALCRIUM — Supabase Schema
-- Run this in your Supabase SQL Editor
-- ============================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ── Profiles (extends Supabase auth.users) ──────────────────
CREATE TABLE IF NOT EXISTS profiles (
  id            UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name     TEXT,
  role          TEXT DEFAULT 'analyst',       -- admin | manager | analyst | founder
  firm_name     TEXT,
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  updated_at    TIMESTAMPTZ DEFAULT NOW()
);

-- ── Companies ───────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS companies (
  id                    UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id               UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name                  TEXT NOT NULL,
  sector                TEXT,
  country               TEXT,
  city                  TEXT,
  website               TEXT,
  year_founded          INTEGER,
  description           TEXT,
  investment            NUMERIC(12,2),
  equity                NUMERIC(12,2),
  entry_rev             NUMERIC(12,2),
  entry_ebitda          NUMERIC(12,2),
  entry_ev_rev_multiple NUMERIC(8,2),
  acq_date              DATE,
  deal_lead             TEXT,
  target_irr            NUMERIC(8,2),
  target_moic           NUMERIC(8,2),
  thesis                TEXT,
  color                 TEXT DEFAULT '#3266ad',
  created_at            TIMESTAMPTZ DEFAULT NOW(),
  updated_at            TIMESTAMPTZ DEFAULT NOW()
);

-- ── Value Creation Plans ────────────────────────────────────
CREATE TABLE IF NOT EXISTS value_creation_plans (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id         UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  company_id      UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  plan_owner      TEXT,
  target_rev      NUMERIC(12,2),
  target_ebitda   NUMERIC(12,2),
  key_priorities  TEXT,
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ── Objectives ──────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS objectives (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id         UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  company_id      UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  name            TEXT NOT NULL,
  theme           TEXT,
  key_priorities  TEXT,
  status          TEXT DEFAULT 'Not Started',
  pct             INTEGER DEFAULT 0,
  owner           TEXT,
  start_date      DATE,
  end_date        DATE,
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ── Initiatives ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS initiatives (
  id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id          UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  company_id       UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  objective_id     UUID REFERENCES objectives(id) ON DELETE SET NULL,
  objective_name   TEXT,
  title            TEXT NOT NULL,
  category         TEXT,
  theme            TEXT,
  key_priorities   TEXT,
  owner            TEXT,
  status           TEXT DEFAULT 'Not Started',
  pct              INTEGER DEFAULT 0,
  start_date       DATE,
  end_date         DATE,
  is_quantitative  BOOLEAN DEFAULT FALSE,
  kpi              TEXT,
  freq_monthly     BOOLEAN DEFAULT FALSE,
  freq_annually    BOOLEAN DEFAULT FALSE,
  completed_date   DATE,
  completed_by     TEXT,
  completed_at     TIMESTAMPTZ,
  created_at       TIMESTAMPTZ DEFAULT NOW(),
  updated_at       TIMESTAMPTZ DEFAULT NOW()
);

-- ── KPI Data ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS kpi_data (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id         UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  initiative_id   UUID NOT NULL REFERENCES initiatives(id) ON DELETE CASCADE,
  period          TEXT,
  value           NUMERIC(16,4),
  notes           TEXT,
  recorded_at     TIMESTAMPTZ DEFAULT NOW()
);

-- ── Notes ───────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS notes (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id       UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  entity_type   TEXT NOT NULL,   -- 'initiative' | 'objective' | 'company'
  entity_id     UUID NOT NULL,
  text          TEXT NOT NULL,
  author_name   TEXT,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

-- ── Updated_at triggers ─────────────────────────────────────
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN NEW.updated_at = NOW(); RETURN NEW; END;
$$ LANGUAGE plpgsql;

DO $$ DECLARE t TEXT;
BEGIN
  FOREACH t IN ARRAY ARRAY['profiles','companies','value_creation_plans','objectives','initiatives']
  LOOP
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_' || t || '_updated_at') THEN
      EXECUTE format(
        'CREATE TRIGGER trg_%I_updated_at BEFORE UPDATE ON %I
         FOR EACH ROW EXECUTE FUNCTION set_updated_at()', t, t);
    END IF;
  END LOOP;
END $$;

-- ── Row Level Security (each user sees only their own data) ─
ALTER TABLE profiles              ENABLE ROW LEVEL SECURITY;
ALTER TABLE companies             ENABLE ROW LEVEL SECURITY;
ALTER TABLE value_creation_plans  ENABLE ROW LEVEL SECURITY;
ALTER TABLE objectives            ENABLE ROW LEVEL SECURITY;
ALTER TABLE initiatives           ENABLE ROW LEVEL SECURITY;
ALTER TABLE kpi_data              ENABLE ROW LEVEL SECURITY;
ALTER TABLE notes                 ENABLE ROW LEVEL SECURITY;

-- Profiles
CREATE POLICY "Users can manage own profile"
  ON profiles FOR ALL USING (auth.uid() = id);

-- Companies
CREATE POLICY "Users can manage own companies"
  ON companies FOR ALL USING (auth.uid() = user_id);

-- VCPs
CREATE POLICY "Users can manage own vcps"
  ON value_creation_plans FOR ALL USING (auth.uid() = user_id);

-- Objectives
CREATE POLICY "Users can manage own objectives"
  ON objectives FOR ALL USING (auth.uid() = user_id);

-- Initiatives
CREATE POLICY "Users can manage own initiatives"
  ON initiatives FOR ALL USING (auth.uid() = user_id);

-- KPI data
CREATE POLICY "Users can manage own kpi data"
  ON kpi_data FOR ALL USING (auth.uid() = user_id);

-- Notes
CREATE POLICY "Users can manage own notes"
  ON notes FOR ALL USING (auth.uid() = user_id);

-- ── Founder view (sees all data across all users) ───────────
CREATE OR REPLACE VIEW founder_overview AS
SELECT
  p.full_name,
  p.firm_name,
  p.role,
  p.created_at AS joined,
  COUNT(DISTINCT c.id)  AS companies,
  COUNT(DISTINCT o.id)  AS objectives,
  COUNT(DISTINCT i.id)  AS initiatives
FROM profiles p
LEFT JOIN companies  c ON c.user_id = p.id
LEFT JOIN objectives o ON o.user_id = p.id
LEFT JOIN initiatives i ON i.user_id = p.id
GROUP BY p.id, p.full_name, p.firm_name, p.role, p.created_at;

-- Auto-create profile on signup
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO profiles (id, full_name)
  VALUES (NEW.id, NEW.raw_user_meta_data->>'full_name');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();
