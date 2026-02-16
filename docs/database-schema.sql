-- ============================================
-- FEMORA DATABASE SCHEMA
-- Initial Setup Script
-- ============================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE TRIGGER set_updated_at_period_cycles
BEFORE UPDATE ON public.period_cycles
FOR EACH ROW
EXECUTE FUNCTION public.handle_updated_at();