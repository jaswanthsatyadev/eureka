-- ==============================================================================
-- 001_initial_schema.sql: Identity, Profiles & Project Domain
-- ==============================================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 1. Profiles Table (D1)
-- Extends Supabase auth.users without duplicating auth fields
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    display_name TEXT,
    avatar_url TEXT,
    role VARCHAR(20) NOT NULL DEFAULT 'user' CHECK (role IN ('user', 'admin')),
    usage_tier VARCHAR(20) NOT NULL DEFAULT 'free' CHECK (usage_tier IN ('free', 'pro', 'enterprise')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

-- Index on role for fast admin checks
CREATE INDEX IF NOT EXISTS idx_profiles_role ON public.profiles(role);

-- 2. Trigger on auth.users Signup (D1)
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
    RETURN NEW;
END;
$$;

-- Drop trigger if exists and recreate
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 3. Project Categories Lookup Table (D2)
CREATE TABLE IF NOT EXISTS public.project_categories (
    id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

-- 4. Projects Table (D2)
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

-- Indexes for projects
CREATE INDEX IF NOT EXISTS idx_projects_owner_id ON public.projects(owner_id);
CREATE INDEX IF NOT EXISTS idx_projects_status ON public.projects(status);
CREATE INDEX IF NOT EXISTS idx_projects_share_token ON public.projects(share_token) WHERE share_token IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_projects_updated_at ON public.projects(updated_at DESC);

-- 5. Project Versions Table (D2)
-- Append-only historical snapshots
CREATE TABLE IF NOT EXISTS public.project_versions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
    version_number INT NOT NULL,
    circuit_state JSONB NOT NULL, -- Full CircuitGraph shape
    change_summary TEXT,
    created_by JSONB NOT NULL, -- Actor shape: {"actor_type": "user"|"ai", "user_id": "...", "ai_run_id": "..."}
    parent_version_id UUID REFERENCES public.project_versions(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    CONSTRAINT uq_project_version_number UNIQUE (project_id, version_number)
);

CREATE INDEX IF NOT EXISTS idx_project_versions_project_id ON public.project_versions(project_id);
CREATE INDEX IF NOT EXISTS idx_project_versions_created_at ON public.project_versions(created_at DESC);

-- Add foreign key constraint from projects to project_versions
ALTER TABLE public.projects 
    DROP CONSTRAINT IF EXISTS fk_projects_current_version;
ALTER TABLE public.projects 
    ADD CONSTRAINT fk_projects_current_version 
    FOREIGN KEY (current_version_id) 
    REFERENCES public.project_versions(id) 
    ON DELETE SET NULL 
    DEFERRABLE INITIALLY DEFERRED;

-- 6. Project Live State Table (D2)
-- Single mutable row per project; target of Supabase Realtime
CREATE TABLE IF NOT EXISTS public.project_live_state (
    project_id UUID PRIMARY KEY REFERENCES public.projects(id) ON DELETE CASCADE,
    circuit_state JSONB NOT NULL, -- Current CircuitGraph
    validation_summary JSONB DEFAULT '{"is_valid": true, "findings": []}'::jsonb,
    bom_summary JSONB DEFAULT '{"items": [], "total_cost": 0.0, "currency": "USD"}'::jsonb,
    last_mutation JSONB,
    last_actor JSONB,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);
