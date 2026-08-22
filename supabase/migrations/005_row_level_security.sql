-- ==============================================================================
-- 005_row_level_security.sql: Whole-System Row-Level Security (RLS) Policies
-- ==============================================================================

-- Helper Security Definer Function to check Admin Role
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

-- Helper to check if a user owns a project
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

-- ------------------------------------------------------------------------------
-- 1. Enable RLS on ALL tables
-- ------------------------------------------------------------------------------
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

-- ------------------------------------------------------------------------------
-- 2. Profiles Policies
-- ------------------------------------------------------------------------------
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
CREATE POLICY "Users can view own profile"
    ON public.profiles FOR SELECT
    USING (id = auth.uid() OR public.is_admin());

DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile"
    ON public.profiles FOR UPDATE
    USING (id = auth.uid())
    WITH CHECK (id = auth.uid() AND (role IS NULL OR role = (SELECT role FROM public.profiles WHERE id = auth.uid())));

-- ------------------------------------------------------------------------------
-- 3. Lookup Tables (Project Categories & Component Categories) - Public Read
-- ------------------------------------------------------------------------------
DROP POLICY IF EXISTS "Public read project categories" ON public.project_categories;
CREATE POLICY "Public read project categories"
    ON public.project_categories FOR SELECT
    USING (TRUE);

DROP POLICY IF EXISTS "Public read component categories" ON public.component_categories;
CREATE POLICY "Public read component categories"
    ON public.component_categories FOR SELECT
    USING (TRUE);

-- ------------------------------------------------------------------------------
-- 4. Projects Policies
-- ------------------------------------------------------------------------------
DROP POLICY IF EXISTS "Users can view own projects or shared" ON public.projects;
CREATE POLICY "Users can view own projects or shared"
    ON public.projects FOR SELECT
    USING (
        owner_id = auth.uid() 
        OR share_token IS NOT NULL
        OR public.is_admin()
    );

DROP POLICY IF EXISTS "Users can insert own projects" ON public.projects;
CREATE POLICY "Users can insert own projects"
    ON public.projects FOR INSERT
    WITH CHECK (owner_id = auth.uid());

DROP POLICY IF EXISTS "Users can update own projects" ON public.projects;
CREATE POLICY "Users can update own projects"
    ON public.projects FOR UPDATE
    USING (owner_id = auth.uid() OR public.is_admin())
    WITH CHECK (owner_id = auth.uid() OR public.is_admin());

DROP POLICY IF EXISTS "Users can delete own projects" ON public.projects;
CREATE POLICY "Users can delete own projects"
    ON public.projects FOR DELETE
    USING (owner_id = auth.uid() OR public.is_admin());

-- ------------------------------------------------------------------------------
-- 5. Project Versions & Live State Policies (Owner-Scoped)
-- ------------------------------------------------------------------------------
DROP POLICY IF EXISTS "Owner access project versions" ON public.project_versions;
CREATE POLICY "Owner access project versions"
    ON public.project_versions FOR ALL
    USING (public.is_project_owner(project_id) OR public.is_admin());

DROP POLICY IF EXISTS "Owner access project live state" ON public.project_live_state;
CREATE POLICY "Owner access project live state"
    ON public.project_live_state FOR ALL
    USING (public.is_project_owner(project_id) OR public.is_admin());

-- ------------------------------------------------------------------------------
-- 6. Component Catalog (Public Read, Admin Write)
-- ------------------------------------------------------------------------------
DROP POLICY IF EXISTS "Public read components" ON public.component_definitions;
CREATE POLICY "Public read components"
    ON public.component_definitions FOR SELECT
    USING (TRUE);

DROP POLICY IF EXISTS "Admin write components" ON public.component_definitions;
CREATE POLICY "Admin write components"
    ON public.component_definitions FOR ALL
    USING (public.is_admin());

DROP POLICY IF EXISTS "Public read component alternatives" ON public.component_alternatives;
CREATE POLICY "Public read component alternatives"
    ON public.component_alternatives FOR SELECT
    USING (TRUE);

DROP POLICY IF EXISTS "Admin write component alternatives" ON public.component_alternatives;
CREATE POLICY "Admin write component alternatives"
    ON public.component_alternatives FOR ALL
    USING (public.is_admin());

-- ------------------------------------------------------------------------------
-- 7. Generated Artifacts & Export Jobs
-- ------------------------------------------------------------------------------
DROP POLICY IF EXISTS "Owner access generated artifacts" ON public.generated_artifacts;
CREATE POLICY "Owner access generated artifacts"
    ON public.generated_artifacts FOR ALL
    USING (public.is_project_owner(project_id) OR public.is_admin());

DROP POLICY IF EXISTS "Requester access export jobs" ON public.export_jobs;
CREATE POLICY "Requester access export jobs"
    ON public.export_jobs FOR ALL
    USING (requester_id = auth.uid() OR public.is_admin());

-- ------------------------------------------------------------------------------
-- 8. AI Runs, Action Logs & Conversation Messages
-- ------------------------------------------------------------------------------
DROP POLICY IF EXISTS "Owner access ai agent runs" ON public.ai_agent_runs;
CREATE POLICY "Owner access ai agent runs"
    ON public.ai_agent_runs FOR ALL
    USING (user_id = auth.uid() OR public.is_admin());

DROP POLICY IF EXISTS "Owner access ai action logs" ON public.ai_action_logs;
CREATE POLICY "Owner access ai action logs"
    ON public.ai_action_logs FOR ALL
    USING (public.is_project_owner(project_id) OR public.is_admin());

DROP POLICY IF EXISTS "Owner access ai conversation messages" ON public.ai_conversation_messages;
CREATE POLICY "Owner access ai conversation messages"
    ON public.ai_conversation_messages FOR ALL
    USING (public.is_project_owner(project_id) OR public.is_admin());

DROP POLICY IF EXISTS "Owner view usage limits" ON public.ai_usage_limits;
CREATE POLICY "Owner view usage limits"
    ON public.ai_usage_limits FOR SELECT
    USING (user_id = auth.uid() OR public.is_admin());

-- ------------------------------------------------------------------------------
-- 9. Admin & Telemetry (Admin Only)
-- ------------------------------------------------------------------------------
DROP POLICY IF EXISTS "Admin access model usage logs" ON public.model_usage_logs;
CREATE POLICY "Admin access model usage logs"
    ON public.model_usage_logs FOR ALL
    USING (public.is_admin());

DROP POLICY IF EXISTS "Admin access audit logs" ON public.admin_audit_logs;
CREATE POLICY "Admin access audit logs"
    ON public.admin_audit_logs FOR ALL
    USING (public.is_admin());

DROP POLICY IF EXISTS "Admin access failed generations" ON public.failed_generations;
CREATE POLICY "Admin access failed generations"
    ON public.failed_generations FOR ALL
    USING (public.is_admin());
