# Problems Fixes

Date: 2026-03-12

## What I changed

1. Added `FemoraTextStyles.bodySmall` in `mobile/lib/config/app_theme.dart`.
2. Added `bodySmall` to the app `TextTheme` mapping in `mobile/lib/config/app_theme.dart`.
3. Removed the unused `_PregnancyPlaceholder` widget from `mobile/lib/screens/reproductive/reproductive_health_screen.dart`.
4. Removed the unused `period_cycle.dart` import from `mobile/lib/services/phase_calculator.dart`.

## Why

- `period_tab.dart` was referencing `FemoraTextStyles.bodySmall`, but that getter did not exist.
- The other two issues were analyzer warnings shown in Problems and did not affect runtime logic.

## Logic impact

No application logic was changed.

- The period and pregnancy flows remain the same.
- The fix only adds a missing typography token and removes unused code/imports.

## Result

These changes are intended to clear the Problems entries related to:

- Missing `FemoraTextStyles.bodySmall`
- Unused private widget declaration
- Unused import in `phase_calculator.dart`