-- ============================================
-- FEMORA DATABASE SCHEMA
-- Initial Setup Script
-- ============================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- PERIOD TRACKING TABLES
-- ============================================

-- Period Cycles Table
CREATE TABLE IF NOT EXISTS public.period_cycles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    start_date DATE NOT NULL,
    end_date DATE,
    cycle_length INTEGER,
    bleeding_days INTEGER,
    is_confirmed BOOLEAN DEFAULT TRUE,
    is_predicted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Period Daily Logs Table
CREATE TABLE IF NOT EXISTS public.period_daily_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    cycle_id UUID REFERENCES public.period_cycles(id) ON DELETE SET NULL,
    log_date DATE NOT NULL,
    flow_level TEXT CHECK (flow_level IN ('low', 'medium', 'high')),
    pain_level INTEGER CHECK (pain_level >= 0 AND pain_level <= 10),
    symptoms TEXT[] DEFAULT '{}',
    has_spotting BOOLEAN DEFAULT FALSE,
    notes TEXT,
    mood TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, log_date)
);

-- Predefined Symptoms Table
CREATE TABLE IF NOT EXISTS public.predefined_symptoms (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL UNIQUE,
    category TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Period Symptoms Table (User-specific symptom tracking)
CREATE TABLE IF NOT EXISTS public.period_symptoms (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    daily_log_id UUID REFERENCES public.period_daily_logs(id) ON DELETE CASCADE,
    symptom_name TEXT NOT NULL,
    severity INTEGER CHECK (severity >= 1 AND severity <= 5),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- INDEXES FOR PERFORMANCE
-- ============================================

CREATE INDEX IF NOT EXISTS idx_period_cycles_user_id ON public.period_cycles(user_id);
CREATE INDEX IF NOT EXISTS idx_period_cycles_start_date ON public.period_cycles(start_date DESC);
CREATE INDEX IF NOT EXISTS idx_period_daily_logs_user_id ON public.period_daily_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_period_daily_logs_log_date ON public.period_daily_logs(log_date DESC);
CREATE INDEX IF NOT EXISTS idx_period_daily_logs_cycle_id ON public.period_daily_logs(cycle_id);
CREATE INDEX IF NOT EXISTS idx_period_symptoms_user_id ON public.period_symptoms(user_id);

-- ============================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================

ALTER TABLE public.period_cycles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.period_daily_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.predefined_symptoms ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.period_symptoms ENABLE ROW LEVEL SECURITY;

-- Period Cycles Policies
CREATE POLICY "Users can view their own cycles"
    ON public.period_cycles FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own cycles"
    ON public.period_cycles FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own cycles"
    ON public.period_cycles FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own cycles"
    ON public.period_cycles FOR DELETE
    USING (auth.uid() = user_id);

-- Period Daily Logs Policies
CREATE POLICY "Users can view their own logs"
    ON public.period_daily_logs FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own logs"
    ON public.period_daily_logs FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own logs"
    ON public.period_daily_logs FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own logs"
    ON public.period_daily_logs FOR DELETE
    USING (auth.uid() = user_id);

-- Predefined Symptoms Policies (Read-only for all authenticated users)
CREATE POLICY "Anyone can view predefined symptoms"
    ON public.predefined_symptoms FOR SELECT
    TO authenticated
    USING (true);

-- Period Symptoms Policies
CREATE POLICY "Users can view their own symptoms"
    ON public.period_symptoms FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own symptoms"
    ON public.period_symptoms FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own symptoms"
    ON public.period_symptoms FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own symptoms"
    ON public.period_symptoms FOR DELETE
    USING (auth.uid() = user_id);

-- ============================================
-- TRIGGERS
-- ============================================

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply triggers
CREATE TRIGGER set_updated_at_period_cycles
    BEFORE UPDATE ON public.period_cycles
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER set_updated_at_period_daily_logs
    BEFORE UPDATE ON public.period_daily_logs
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- ============================================
-- SEED DATA - Predefined Symptoms
-- ============================================

INSERT INTO public.predefined_symptoms (name, category, description) VALUES
    ('Cramps', 'pain', 'Abdominal cramping or pain'),
    ('Headache', 'pain', 'Head pain or migraine'),
    ('Back Pain', 'pain', 'Lower back discomfort'),
    ('Breast Tenderness', 'physical', 'Soreness or sensitivity in breasts'),
    ('Bloating', 'physical', 'Abdominal bloating or swelling'),
    ('Fatigue', 'physical', 'Tiredness or low energy'),
    ('Nausea', 'physical', 'Feeling sick or queasy'),
    ('Acne', 'skin', 'Skin breakouts'),
    ('Mood Swings', 'emotional', 'Emotional ups and downs'),
    ('Irritability', 'emotional', 'Feeling easily annoyed'),
    ('Anxiety', 'emotional', 'Nervous or worried feelings'),
    ('Depression', 'emotional', 'Sad or low mood'),
    ('Food Cravings', 'appetite', 'Desire for specific foods'),
    ('Increased Appetite', 'appetite', 'Eating more than usual'),
    ('Insomnia', 'sleep', 'Difficulty sleeping'),
    ('Constipation', 'digestive', 'Difficulty with bowel movements'),
    ('Diarrhea', 'digestive', 'Loose bowel movements'),
    ('Hot Flashes', 'temperature', 'Sudden feeling of warmth'),
    ('Chills', 'temperature', 'Feeling cold or shivering')
ON CONFLICT (name) DO NOTHING;
