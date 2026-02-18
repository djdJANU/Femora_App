# FEMORA — Architecture Guidelines

## Frontend Rules

- UI must not directly call Supabase.
- All authentication calls go through `auth_service.dart`.
- Use Provider for state management.
- Handle loading states properly.
- Show generic authentication errors.
- Follow consistent theming (AppTheme).

## Backend Rules

- Use Helmet for security headers.
- Use express-rate-limit for auth endpoints.
- Validate all incoming requests.
- Reject unexpected fields.
- Use environment variables for secrets.
- Limit payload size to prevent abuse.

## Security Rules

- Never expose service_role key to frontend.
- All tables must have RLS enabled.
- Use UUID for primary keys.
- No sensitive information in error messages.

## Code Quality

- Use meaningful variable names.
- Use modular file structure.
- Follow feature-based folder structure.
- Keep files under 300 lines if possible.