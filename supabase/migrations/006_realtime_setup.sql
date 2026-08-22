-- ==============================================================================
-- 006_realtime_setup.sql: Realtime Synchronization Configuration (D8)
-- ==============================================================================

-- Enable full replication identity on project_live_state so update events send complete rows
ALTER TABLE public.project_live_state REPLICA IDENTITY FULL;

-- Add project_live_state selectively to Supabase Realtime publication
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime'
    ) THEN
        -- Check if already added
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
