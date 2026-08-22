-- ==============================================================================
-- 002_component_catalog.sql: Component Catalog, Pins, Alternatives & Search
-- ==============================================================================

-- Enable pg_trgm for fuzzy string search
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- 1. Component Categories Lookup Table (D3)
CREATE TABLE IF NOT EXISTS public.component_categories (
    id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    sort_order INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

-- 2. Component Definitions Table (D3)
CREATE TABLE IF NOT EXISTS public.component_definitions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(120) NOT NULL,
    category_id VARCHAR(50) NOT NULL REFERENCES public.component_categories(id) ON DELETE RESTRICT,
    purpose TEXT NOT NULL,
    manufacturer VARCHAR(100),
    part_number VARCHAR(100),
    structured_pins JSONB NOT NULL DEFAULT '[]'::jsonb, -- Array of PinDefinitions
    electrical_characteristics JSONB NOT NULL DEFAULT '{}'::jsonb, -- Operating voltages, max current, etc.
    unit_price NUMERIC(10, 4) NOT NULL DEFAULT 0.0000,
    currency VARCHAR(3) NOT NULL DEFAULT 'USD',
    is_available BOOLEAN NOT NULL DEFAULT TRUE,
    asset_key TEXT, -- Cloudflare R2 path to SVG (e.g. "components/sensors/dht22.svg")
    view_box JSONB DEFAULT '{"width": 120, "height": 120}'::jsonb,
    confidence VARCHAR(20) NOT NULL DEFAULT 'verified' CHECK (confidence IN ('verified', 'ai_extracted', 'community')),
    search_vector TSVECTOR GENERATED ALWAYS AS (
        to_tsvector('english', name || ' ' || purpose || ' ' || COALESCE(part_number, '') || ' ' || COALESCE(manufacturer, ''))
    ) STORED,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

-- Indexes for Component Definitions
CREATE INDEX IF NOT EXISTS idx_comp_defs_category ON public.component_definitions(category_id);
CREATE INDEX IF NOT EXISTS idx_comp_defs_is_available ON public.component_definitions(is_available);
CREATE INDEX IF NOT EXISTS idx_comp_defs_name_trgm ON public.component_definitions USING gin (name gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_comp_defs_search ON public.component_definitions USING gin (search_vector);

-- 3. Component Alternatives Table (D3)
-- Bidirectional relationship mapping interchangeable components for cost optimization
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
