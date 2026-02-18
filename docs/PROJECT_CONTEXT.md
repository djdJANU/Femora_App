# FEMORA — Project Context

## Overview
Femora is an AI-driven women's wellbeing mobile application.

It helps users:
- Track menstrual cycles
- Track mood and mental health
- Track pregnancy
- Manage wellness data securely

## Tech Stack

### Frontend
- Flutter (mobile app)
- Provider (state management)
- Supabase Flutter SDK

### Backend
- Node.js + Express
- OWASP security best practices
- Rate limiting
- Input validation
- Environment-based secrets

### Database
- Supabase PostgreSQL
- Row Level Security (RLS) enabled
- UUID primary keys

---

## Architecture Rules

- No direct database calls inside UI.
- All API logic goes through service layer.
- Service role key NEVER exposed to frontend.
- All secrets stored in `.env` files.
- Follow clean, modular structure.
- Error messages must not expose sensitive information.

---

## Current Phase

We are implementing:
- Authentication (Signup, Login, Profile setup)
- Secure backend validation
- Splash + onboarding flow