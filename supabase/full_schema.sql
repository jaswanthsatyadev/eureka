-- ==============================================================================
-- EUREKA AI ELECTRONICS PROJECT BUILDER - COMPLETE MASTER DATABASE SCHEMA
-- ==============================================================================
-- Run this script in the Supabase SQL Editor to initialize the complete database.

-- ------------------------------------------------------------------------------
-- 1. EXTENSIONS
-- ------------------------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- ------------------------------------------------------------------------------
-- 2. IDENTITY & PROFILES (D1)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    display_name TEXT,
    avatar_url TEXT,
    role VARCHAR(20) NOT NULL DEFAULT 'user' CHECK (role IN ('user', 'admin')),
    usage_tier VARCHAR(20) NOT NULL DEFAULT 'free' CHECK (usage_tier IN ('free', 'pro', 'enterprise')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

CREATE INDEX IF NOT EXISTS idx_profiles_role ON public.profiles(role);

-- ------------------------------------------------------------------------------
-- 3. PROJECT DOMAIN & LIVE STATE (D2)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.project_categories (
    id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

CREATE TABLE IF NOT EXISTS public.projects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title VARCHAR(120) NOT NULL,
    description TEXT,
    category_id VARCHAR(50) REFERENCES public.project_categories(id) ON DELETE SET NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'archived', 'deleted')),
    is_favorite BOOLEAN NOT NULL DEFAULT FALSE,
    share_token VARCHAR(64) UNIQUE,
    current_version_id UUID,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    deleted_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_projects_owner_id ON public.projects(owner_id);
CREATE INDEX IF NOT EXISTS idx_projects_status ON public.projects(status);
CREATE INDEX IF NOT EXISTS idx_projects_share_token ON public.projects(share_token) WHERE share_token IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_projects_updated_at ON public.projects(updated_at DESC);

CREATE TABLE IF NOT EXISTS public.project_versions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
    version_number INT NOT NULL,
    circuit_state JSONB NOT NULL,
    change_summary TEXT,
    created_by JSONB NOT NULL,
    parent_version_id UUID REFERENCES public.project_versions(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    CONSTRAINT uq_project_version_number UNIQUE (project_id, version_number)
);

CREATE INDEX IF NOT EXISTS idx_project_versions_project_id ON public.project_versions(project_id);
CREATE INDEX IF NOT EXISTS idx_project_versions_created_at ON public.project_versions(created_at DESC);

ALTER TABLE public.projects 
    DROP CONSTRAINT IF EXISTS fk_projects_current_version;
ALTER TABLE public.projects 
    ADD CONSTRAINT fk_projects_current_version 
    FOREIGN KEY (current_version_id) 
    REFERENCES public.project_versions(id) 
    ON DELETE SET NULL 
    DEFERRABLE INITIALLY DEFERRED;

CREATE TABLE IF NOT EXISTS public.project_live_state (
    project_id UUID PRIMARY KEY REFERENCES public.projects(id) ON DELETE CASCADE,
    circuit_state JSONB NOT NULL,
    validation_summary JSONB DEFAULT '{"is_valid": true, "findings": []}'::jsonb,
    bom_summary JSONB DEFAULT '{"items": [], "total_cost": 0.0, "currency": "USD"}'::jsonb,
    last_mutation JSONB,
    last_actor JSONB,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

-- ------------------------------------------------------------------------------
-- 4. COMPONENT CATALOG & ALTERNATIVES (D3)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.component_categories (
    id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    sort_order INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

CREATE TABLE IF NOT EXISTS public.component_definitions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(120) NOT NULL,
    category_id VARCHAR(50) NOT NULL REFERENCES public.component_categories(id) ON DELETE RESTRICT,
    purpose TEXT NOT NULL,
    manufacturer VARCHAR(100),
    part_number VARCHAR(100),
    structured_pins JSONB NOT NULL DEFAULT '[]'::jsonb,
    electrical_characteristics JSONB NOT NULL DEFAULT '{}'::jsonb,
    unit_price NUMERIC(10, 4) NOT NULL DEFAULT 0.0000,
    currency VARCHAR(3) NOT NULL DEFAULT 'USD',
    is_available BOOLEAN NOT NULL DEFAULT TRUE,
    asset_key TEXT,
    view_box JSONB DEFAULT '{"width": 120, "height": 120}'::jsonb,
    confidence VARCHAR(20) NOT NULL DEFAULT 'verified' CHECK (confidence IN ('verified', 'ai_extracted', 'community')),
    search_vector TSVECTOR GENERATED ALWAYS AS (
        to_tsvector('english', name || ' ' || purpose || ' ' || COALESCE(part_number, '') || ' ' || COALESCE(manufacturer, ''))
    ) STORED,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

CREATE INDEX IF NOT EXISTS idx_comp_defs_category ON public.component_definitions(category_id);
CREATE INDEX IF NOT EXISTS idx_comp_defs_is_available ON public.component_definitions(is_available);
CREATE INDEX IF NOT EXISTS idx_comp_defs_name_trgm ON public.component_definitions USING gin (name gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_comp_defs_search ON public.component_definitions USING gin (search_vector);

CREATE TABLE IF NOT EXISTS public.component_alternatives (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    component_id UUID NOT NULL REFERENCES public.component_definitions(id) ON DELETE CASCADE,
    alternative_component_id UUID NOT NULL REFERENCES public.component_definitions(id) ON DELETE CASCADE,
    reason TEXT,
    price_difference_note TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    CONSTRAINT uq_component_alternative_pair UNIQUE (component_id, alternative_component_id),
    CONSTRAINT chk_different_components CHECK (component_id <> alternative_component_id)
);

CREATE INDEX IF NOT EXISTS idx_comp_alt_component_id ON public.component_alternatives(component_id);
CREATE INDEX IF NOT EXISTS idx_comp_alt_alt_component_id ON public.component_alternatives(alternative_component_id);

-- ------------------------------------------------------------------------------
-- 5. DERIVED ARTIFACTS & EXPORTS (D4)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.generated_artifacts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
    version_id UUID REFERENCES public.project_versions(id) ON DELETE CASCADE,
    artifact_type VARCHAR(50) NOT NULL CHECK (
        artifact_type IN (
            'firmware_arduino',
            'firmware_esp32',
            'wiring_guide',
            'assembly_instructions',
            'flowchart',
            'bom_csv'
        )
    ),
    content TEXT,
    storage_key TEXT,
    is_stale BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    CONSTRAINT uq_project_artifact_type UNIQUE (project_id, artifact_type)
);

CREATE INDEX IF NOT EXISTS idx_gen_artifacts_project_id ON public.generated_artifacts(project_id);

CREATE TABLE IF NOT EXISTS public.export_jobs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
    requester_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    format VARCHAR(20) NOT NULL CHECK (format IN ('pdf', 'svg', 'png', 'zip', 'json')),
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed')),
    storage_key TEXT,
    download_url TEXT,
    error_message TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    completed_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_export_jobs_project_id ON public.export_jobs(project_id);

-- ------------------------------------------------------------------------------
-- 6. AI DOMAIN & OBSERVABILITY (D5)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.ai_agent_runs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    thread_id VARCHAR(100) NOT NULL,
    run_type VARCHAR(50) NOT NULL CHECK (run_type IN ('generation', 'modification', 'clarification')),
    prompt TEXT NOT NULL,
    status VARCHAR(30) NOT NULL DEFAULT 'in_progress' CHECK (
        status IN ('in_progress', 'completed', 'clarification_needed', 'failed')
    ),
    clarifying_question TEXT,
    total_tokens INT NOT NULL DEFAULT 0,
    estimated_cost_usd NUMERIC(10, 6) NOT NULL DEFAULT 0.000000,
    started_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    completed_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_ai_agent_runs_project_id ON public.ai_agent_runs(project_id);
CREATE INDEX IF NOT EXISTS idx_ai_agent_runs_thread_id ON public.ai_agent_runs(thread_id);

CREATE TABLE IF NOT EXISTS public.ai_action_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    run_id UUID NOT NULL REFERENCES public.ai_agent_runs(id) ON DELETE CASCADE,
    project_id UUID NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
    tool_name VARCHAR(100) NOT NULL,
    tool_input JSONB,
    tool_output JSONB,
    before_version_id UUID REFERENCES public.project_versions(id) ON DELETE SET NULL,
    after_version_id UUID REFERENCES public.project_versions(id) ON DELETE SET NULL,
    model_used VARCHAR(100),
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

CREATE INDEX IF NOT EXISTS idx_ai_action_logs_run_id ON public.ai_action_logs(run_id);

CREATE TABLE IF NOT EXISTS public.ai_conversation_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
    run_id UUID REFERENCES public.ai_agent_runs(id) ON DELETE SET NULL,
    sender VARCHAR(20) NOT NULL CHECK (sender IN ('user', 'ai', 'system')),
    message_type VARCHAR(30) NOT NULL DEFAULT 'chat' CHECK (
        message_type IN ('chat', 'clarification_prompt', 'clarification_response', 'error')
    ),
    content TEXT NOT NULL,
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

CREATE INDEX IF NOT EXISTS idx_ai_conv_messages_project_id ON public.ai_conversation_messages(project_id);

CREATE TABLE IF NOT EXISTS public.model_usage_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    run_id UUID NOT NULL REFERENCES public.ai_agent_runs(id) ON DELETE CASCADE,
    project_id UUID NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
    provider VARCHAR(50) NOT NULL,
    model_name VARCHAR(100) NOT NULL,
    node_name VARCHAR(100) NOT NULL,
    input_tokens INT NOT NULL DEFAULT 0,
    output_tokens INT NOT NULL DEFAULT 0,
    latency_ms INT,
    estimated_cost_usd NUMERIC(10, 6) NOT NULL DEFAULT 0.000000,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

CREATE INDEX IF NOT EXISTS idx_model_usage_run_id ON public.model_usage_logs(run_id);

CREATE TABLE IF NOT EXISTS public.ai_usage_limits (
    user_id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
    monthly_token_limit INT NOT NULL DEFAULT 500000,
    monthly_tokens_consumed INT NOT NULL DEFAULT 0,
    monthly_cost_limit_usd NUMERIC(10, 2) NOT NULL DEFAULT 5.00,
    monthly_cost_consumed_usd NUMERIC(10, 4) NOT NULL DEFAULT 0.0000,
    reset_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()) + INTERVAL '30 days',
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

-- ------------------------------------------------------------------------------
-- 7. ADMIN & OPERATIONS (D6)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.admin_audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
    action VARCHAR(100) NOT NULL,
    target_type VARCHAR(50),
    target_id VARCHAR(100),
    details JSONB DEFAULT '{}'::jsonb,
    ip_address VARCHAR(45),
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

CREATE TABLE IF NOT EXISTS public.failed_generations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID REFERENCES public.projects(id) ON DELETE SET NULL,
    run_id UUID REFERENCES public.ai_agent_runs(id) ON DELETE SET NULL,
    stage VARCHAR(100) NOT NULL,
    user_prompt TEXT,
    error_detail TEXT NOT NULL,
    stack_trace TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

-- ------------------------------------------------------------------------------
-- 8. SIGNUP TRIGGER (D1 & D5)
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
BEGIN
    INSERT INTO public.profiles (id, display_name, avatar_url, role, usage_tier)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1)),
        NEW.raw_user_meta_data->>'avatar_url',
        'user',
        'free'
    )
    ON CONFLICT (id) DO NOTHING;

    INSERT INTO public.ai_usage_limits (user_id, monthly_token_limit, monthly_cost_limit_usd)
    VALUES (NEW.id, 500000, 5.00)
    ON CONFLICT (user_id) DO NOTHING;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ------------------------------------------------------------------------------
-- 9. ROW-LEVEL SECURITY (RLS) POLICIES (D7)
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER SET search_path = public
STABLE
AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND role = 'admin'
    );
$$;

CREATE OR REPLACE FUNCTION public.is_project_owner(p_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER SET search_path = public
STABLE
AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.projects
        WHERE id = p_id AND owner_id = auth.uid()
    );
$$;

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.project_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.project_versions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.project_live_state ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.component_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.component_definitions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.component_alternatives ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.generated_artifacts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.export_jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_agent_runs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_action_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_conversation_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.model_usage_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_usage_limits ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.failed_generations ENABLE ROW LEVEL SECURITY;

-- Profiles
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
CREATE POLICY "Users can view own profile" ON public.profiles FOR SELECT USING (id = auth.uid() OR public.is_admin());

DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE USING (id = auth.uid()) WITH CHECK (id = auth.uid());

-- Categories
DROP POLICY IF EXISTS "Public read project categories" ON public.project_categories;
CREATE POLICY "Public read project categories" ON public.project_categories FOR SELECT USING (TRUE);

DROP POLICY IF EXISTS "Public read component categories" ON public.component_categories;
CREATE POLICY "Public read component categories" ON public.component_categories FOR SELECT USING (TRUE);

-- Projects
DROP POLICY IF EXISTS "Users can view own projects or shared" ON public.projects;
CREATE POLICY "Users can view own projects or shared" ON public.projects FOR SELECT USING (owner_id = auth.uid() OR share_token IS NOT NULL OR public.is_admin());

DROP POLICY IF EXISTS "Users can insert own projects" ON public.projects;
CREATE POLICY "Users can insert own projects" ON public.projects FOR INSERT WITH CHECK (owner_id = auth.uid());

DROP POLICY IF EXISTS "Users can update own projects" ON public.projects;
CREATE POLICY "Users can update own projects" ON public.projects FOR UPDATE USING (owner_id = auth.uid() OR public.is_admin()) WITH CHECK (owner_id = auth.uid() OR public.is_admin());

DROP POLICY IF EXISTS "Users can delete own projects" ON public.projects;
CREATE POLICY "Users can delete own projects" ON public.projects FOR DELETE USING (owner_id = auth.uid() OR public.is_admin());

-- Project Versions & Live State
DROP POLICY IF EXISTS "Owner access project versions" ON public.project_versions;
CREATE POLICY "Owner access project versions" ON public.project_versions FOR ALL USING (public.is_project_owner(project_id) OR public.is_admin());

DROP POLICY IF EXISTS "Owner access project live state" ON public.project_live_state;
CREATE POLICY "Owner access project live state" ON public.project_live_state FOR ALL USING (public.is_project_owner(project_id) OR public.is_admin());

-- Component Catalog
DROP POLICY IF EXISTS "Public read components" ON public.component_definitions;
CREATE POLICY "Public read components" ON public.component_definitions FOR SELECT USING (TRUE);

DROP POLICY IF EXISTS "Admin write components" ON public.component_definitions;
CREATE POLICY "Admin write components" ON public.component_definitions FOR ALL USING (public.is_admin());

DROP POLICY IF EXISTS "Public read component alternatives" ON public.component_alternatives;
CREATE POLICY "Public read component alternatives" ON public.component_alternatives FOR SELECT USING (TRUE);

DROP POLICY IF EXISTS "Admin write component alternatives" ON public.component_alternatives;
CREATE POLICY "Admin write component alternatives" ON public.component_alternatives FOR ALL USING (public.is_admin());

-- Artifacts & Exports
DROP POLICY IF EXISTS "Owner access generated artifacts" ON public.generated_artifacts;
CREATE POLICY "Owner access generated artifacts" ON public.generated_artifacts FOR ALL USING (public.is_project_owner(project_id) OR public.is_admin());

DROP POLICY IF EXISTS "Requester access export jobs" ON public.export_jobs;
CREATE POLICY "Requester access export jobs" ON public.export_jobs FOR ALL USING (requester_id = auth.uid() OR public.is_admin());

-- AI Domain
DROP POLICY IF EXISTS "Owner access ai agent runs" ON public.ai_agent_runs;
CREATE POLICY "Owner access ai agent runs" ON public.ai_agent_runs FOR ALL USING (user_id = auth.uid() OR public.is_admin());

DROP POLICY IF EXISTS "Owner access ai action logs" ON public.ai_action_logs;
CREATE POLICY "Owner access ai action logs" ON public.ai_action_logs FOR ALL USING (public.is_project_owner(project_id) OR public.is_admin());

DROP POLICY IF EXISTS "Owner access ai conversation messages" ON public.ai_conversation_messages;
CREATE POLICY "Owner access ai conversation messages" ON public.ai_conversation_messages FOR ALL USING (public.is_project_owner(project_id) OR public.is_admin());

DROP POLICY IF EXISTS "Owner view usage limits" ON public.ai_usage_limits;
CREATE POLICY "Owner view usage limits" ON public.ai_usage_limits FOR SELECT USING (user_id = auth.uid() OR public.is_admin());

-- Telemetry & Admin
DROP POLICY IF EXISTS "Admin access model usage logs" ON public.model_usage_logs;
CREATE POLICY "Admin access model usage logs" ON public.model_usage_logs FOR ALL USING (public.is_admin());

DROP POLICY IF EXISTS "Admin access audit logs" ON public.admin_audit_logs;
CREATE POLICY "Admin access audit logs" ON public.admin_audit_logs FOR ALL USING (public.is_admin());

DROP POLICY IF EXISTS "Admin access failed generations" ON public.failed_generations;
CREATE POLICY "Admin access failed generations" ON public.failed_generations FOR ALL USING (public.is_admin());

-- ------------------------------------------------------------------------------
-- 10. REALTIME CONFIGURATION (D8)
-- ------------------------------------------------------------------------------
ALTER TABLE public.project_live_state REPLICA IDENTITY FULL;

DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime'
    ) THEN
        IF NOT EXISTS (
            SELECT 1 FROM pg_publication_tables 
            WHERE pubname = 'supabase_realtime' 
            AND schemaname = 'public' 
            AND tablename = 'project_live_state'
        ) THEN
            ALTER PUBLICATION supabase_realtime ADD TABLE public.project_live_state;
        END IF;
    END IF;
END $$;
