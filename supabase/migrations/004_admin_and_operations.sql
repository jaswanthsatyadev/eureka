-- ==============================================================================
-- 004_admin_and_operations.sql: Admin Audit Logs & Pipeline Error Tracking
-- ==============================================================================

-- 1. Admin Audit Logs Table (D6)
CREATE TABLE IF NOT EXISTS public.admin_audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
    action VARCHAR(100) NOT NULL, -- e.g. "update_component", "change_user_role", "purge_project"
    target_type VARCHAR(50), -- e.g. "component", "user", "project"
    target_id VARCHAR(100),
    details JSONB DEFAULT '{}'::jsonb,
    ip_address VARCHAR(45),
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

CREATE INDEX IF NOT EXISTS idx_admin_audit_admin_id ON public.admin_audit_logs(admin_id);
CREATE INDEX IF NOT EXISTS idx_admin_audit_created_at ON public.admin_audit_logs(created_at DESC);

-- 2. Failed Generations Table (D6)
CREATE TABLE IF NOT EXISTS public.failed_generations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID REFERENCES public.projects(id) ON DELETE SET NULL,
    run_id UUID REFERENCES public.ai_agent_runs(id) ON DELETE SET NULL,
    stage VARCHAR(100) NOT NULL, -- e.g. "requirement_analysis", "circuit_construction", "validation_repair"
    user_prompt TEXT,
    error_detail TEXT NOT NULL,
    stack_trace TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

CREATE INDEX IF NOT EXISTS idx_failed_gen_created_at ON public.failed_generations(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_failed_gen_stage ON public.failed_generations(stage);
