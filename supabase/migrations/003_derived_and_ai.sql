-- ==============================================================================
-- 003_derived_and_ai.sql: Generated Artifacts, Exports & AI Domain
-- ==============================================================================

-- 1. Generated Artifacts Table (D4)
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
    content TEXT, -- Inline source code / markdown
    storage_key TEXT, -- Optional Cloudflare R2 path for larger renders
    is_stale BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    CONSTRAINT uq_project_artifact_type UNIQUE (project_id, artifact_type)
);

CREATE INDEX IF NOT EXISTS idx_gen_artifacts_project_id ON public.generated_artifacts(project_id);

-- 2. Export Jobs Table (D4)
CREATE TABLE IF NOT EXISTS public.export_jobs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
    requester_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    format VARCHAR(20) NOT NULL CHECK (format IN ('pdf', 'svg', 'png', 'zip', 'json')),
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed')),
    storage_key TEXT, -- Cloudflare R2 private bucket key
    download_url TEXT,
    error_message TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    completed_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_export_jobs_project_id ON public.export_jobs(project_id);
CREATE INDEX IF NOT EXISTS idx_export_jobs_status ON public.export_jobs(status);

-- 3. AI Agent Runs Table (D5)
CREATE TABLE IF NOT EXISTS public.ai_agent_runs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    thread_id VARCHAR(100) NOT NULL, -- Maps directly to LangGraph checkpoint thread
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
CREATE INDEX IF NOT EXISTS idx_ai_agent_runs_user_id ON public.ai_agent_runs(user_id);

-- 4. AI Action Logs Table (D5)
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
CREATE INDEX IF NOT EXISTS idx_ai_action_logs_project_id ON public.ai_action_logs(project_id);

-- 5. AI Conversation Messages Table (D5)
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
CREATE INDEX IF NOT EXISTS idx_ai_conv_messages_created_at ON public.ai_conversation_messages(created_at ASC);

-- 6. Model Usage Logs Table (D5)
CREATE TABLE IF NOT EXISTS public.model_usage_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    run_id UUID NOT NULL REFERENCES public.ai_agent_runs(id) ON DELETE CASCADE,
    project_id UUID NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
    provider VARCHAR(50) NOT NULL, -- e.g. "gemini", "anthropic", "openrouter"
    model_name VARCHAR(100) NOT NULL,
    node_name VARCHAR(100) NOT NULL, -- LangGraph node (e.g. "requirement_analysis", "circuit_construction")
    input_tokens INT NOT NULL DEFAULT 0,
    output_tokens INT NOT NULL DEFAULT 0,
    latency_ms INT,
    estimated_cost_usd NUMERIC(10, 6) NOT NULL DEFAULT 0.000000,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

CREATE INDEX IF NOT EXISTS idx_model_usage_run_id ON public.model_usage_logs(run_id);
CREATE INDEX IF NOT EXISTS idx_model_usage_created_at ON public.model_usage_logs(created_at DESC);

-- 7. AI Usage Limits & Quotas Table (D5)
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

-- Enhance signup trigger to also seed initial ai_usage_limits row
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
BEGIN
    -- 1. Create Profile
    INSERT INTO public.profiles (id, display_name, avatar_url, role, usage_tier)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1)),
        NEW.raw_user_meta_data->>'avatar_url',
        'user',
        'free'
    )
    ON CONFLICT (id) DO NOTHING;

    -- 2. Seed Initial AI Usage Limits
    INSERT INTO public.ai_usage_limits (user_id, monthly_token_limit, monthly_cost_limit_usd)
    VALUES (NEW.id, 500000, 5.00)
    ON CONFLICT (user_id) DO NOTHING;

    RETURN NEW;
END;
$$;
