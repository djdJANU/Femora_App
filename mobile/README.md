# Femora Mobile App

Flutter client application for Femora — an AI-driven women's wellbeing platform.

## Architecture

This mobile app follows:

- Clean Architecture principles
- Feature-based folder structure
- Supabase for authentication & database
- Provider for state management
- Design Token–based theming
- 8pt spacing system

## Folder Structure

lib/
├── config/        → theme, routes, design tokens  
├── screens/       → feature screens (auth, home, period, etc.)  
├── models/        → domain models  
├── services/      → API & Supabase logic  
├── providers/     → state management  
├── utils/         → helpers & extensions  

assets/
├── fonts/  
├── images/  
├── icons/  

## Design System

See:  
docs/DESIGN_SYSTEM.md  

All UI must use:
- Color tokens
- Typography tokens
- 8pt spacing grid
- Defined animation durations

Hardcoded values are not allowed.

## Environment

The app uses `.env` for Supabase credentials.

Required:
SUPABASE_URL  
SUPABASE_ANON_KEY  

Never commit `.env`.

---

