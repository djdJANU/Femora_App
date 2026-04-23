// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
import '../../services/pregnancy_repository.dart';

/// Pregnancy Setup Screen — Redesigned
/// ─────────────────────────────────────
/// UI changes (logic untouched):
///   • Removed the full-width purple hero block — replaced with a compact
///     white top area (illustration + text side-by-side, no gradient fill)
///   • Removed all heavy bordered boxes — replaced with lightweight tiles
///   • Button: solid primary (#A66CFF), matches home screen "Get started"
class PregnancySetupScreen extends StatefulWidget {
  final VoidCallback onPregnancyCreated;
  const PregnancySetupScreen({super.key, required this.onPregnancyCreated});

  @override
  State<PregnancySetupScreen> createState() => _PregnancySetupScreenState();
}

class _PregnancySetupScreenState extends State<PregnancySetupScreen>
    with SingleTickerProviderStateMixin {
  final _repo = PregnancyRepository();

  DateTime? _selectedLmp;
  DateTime? _suggestedLmp;
  bool _isSaving = false;
  bool _isLoadingSuggestion = true;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _loadSuggestion();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSuggestion() async {
    try {
      final s = await _repo.suggestLmpFromPeriodHistory();
      if (mounted) {
        setState(() {
          _suggestedLmp = s;
          if (s != null) _selectedLmp = s;
          _isLoadingSuggestion = false;
        });
        _fadeCtrl.forward();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingSuggestion = false);
        _fadeCtrl.forward();
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _selectedLmp ?? DateTime.now().subtract(const Duration(days: 14)),
      firstDate: DateTime.now().subtract(const Duration(days: 280)),
      lastDate: DateTime.now(),
      helpText: 'First day of your last period',
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: FemoraColors.primary,
            onPrimary: FemoraColors.textLight,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedLmp = picked);
  }

  Future<void> _save() async {
    if (_selectedLmp == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select your last period date'),
        backgroundColor: FemoraColors.error,
      ));
      return;
    }
    setState(() => _isSaving = true);
    try {
      await _repo.createPregnancy(lmpDate: _selectedLmp!);
      widget.onPregnancyCreated();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: FemoraColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final due = _selectedLmp?.add(const Duration(days: 280));

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FF),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Compact top area (replaces full-width purple block) ──
            _buildCompactHeader(),

            // ── Form ─────────────────────────────────────────────────
            Transform.translate(
              offset: const Offset(0, -32),
              child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0x1A9C6BFF),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Question heading
                      Text(
                        'When did your\nlast period start?',
                        style: FemoraTextStyles.headlineLarge.copyWith(
                          color: FemoraColors.textPrimary,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'We use this to calculate your due date.',
                        style: FemoraTextStyles.bodyMedium
                            .copyWith(color: FemoraColors.textSecondary),
                      ),

                      const SizedBox(height: 28),

                      // ── Auto-suggestion (no box, just inline row) ────
                      if (!_isLoadingSuggestion && _suggestedLmp != null) ...[
                        _SuggestionRow(date: _suggestedLmp!),
                        const SizedBox(height: 20),
                      ],

                      // ── Date picker tile ─────────────────────────────
                      _DatePickerTile(
                        selectedDate: _selectedLmp,
                        onTap: _pickDate,
                      ),

                      // ── Due date result (inline, not a heavy card) ───
                      if (due != null) ...[
                        const SizedBox(height: 14),
                        _DueDateRow(dueDate: due),
                      ],

                      const SizedBox(height: 36),

                      // ── CTA — solid primary, same as home screen ─────
                      _PrimaryButton(
                        label: 'Begin My Journey',
                        icon: Icons.arrow_forward_rounded,
                        isLoading: _isSaving,
                        onTap: _isSaving ? null : _save,
                      ),

                      const SizedBox(height: 14),
                      Center(
                        child: Text(
                          '🔒  Your data is encrypted and private',
                          style: FemoraTextStyles.caption
                              .copyWith(color: FemoraColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Compact header — illustration + text, no fill block ───────────────────
  Widget _buildCompactHeader() {
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Full-width illustration
          SizedBox(
            width: double.infinity,
            height: 220,
            child: Image.asset(
              'assets/images/pregnancy/mom_pregnancy.png',
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Center(
                child: Text('🤱', style: TextStyle(fontSize: 72)),
              ),
            ),
          ),

          // Text content — left-aligned, 24px horizontal padding
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pill badge — lavender bg, no gradient
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: FemoraColors.lavenderWhisper,
                    borderRadius:
                        BorderRadius.circular(FemoraBorderRadius.circular),
                  ),
                  child: Text(
                    'Femora · Pregnancy',
                    style: FemoraTextStyles.caption.copyWith(
                      color: FemoraColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Welcome to\nMotherhood',
                  style: FemoraTextStyles.displayLarge.copyWith(
                    color: FemoraColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Track every week of your\nbeautiful journey.',
                  style: FemoraTextStyles.bodyMedium.copyWith(
                    color: FemoraColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Inline suggestion row (replaces the bordered lavender box) ────────────────
class _SuggestionRow extends StatelessWidget {
  final DateTime date;
  const _SuggestionRow({required this.date});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: FemoraColors.lavenderWhisper,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.auto_awesome_rounded,
            color: FemoraColors.primary, size: 15),
      ),
      const SizedBox(width: 10),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detected from Period Tracker',
            style: FemoraTextStyles.caption.copyWith(
              color: FemoraColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            DateFormat('MMMM d, yyyy').format(date),
            style: FemoraTextStyles.bodyMedium.copyWith(
              color: FemoraColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ]);
  }
}

// ── Date picker tile — clean, single border on selection ─────────────────────
class _DatePickerTile extends StatelessWidget {
  final DateTime? selectedDate;
  final VoidCallback onTap;
  const _DatePickerTile({required this.selectedDate, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasDate = selectedDate != null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: FemoraColors.lightBackgroundTint,
          borderRadius:
              BorderRadius.circular(FemoraBorderRadius.medium),
          border: hasDate
              ? Border.all(
                  color: FemoraColors.primary.withOpacity(0.45),
                  width: 1.5)
              : Border.all(color: Colors.transparent),
        ),
        child: Row(children: [
          Icon(
            Icons.calendar_today_rounded,
            color: hasDate
                ? FemoraColors.primary
                : FemoraColors.textSecondary,
            size: 20,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              hasDate
                  ? DateFormat('EEEE, MMMM d, yyyy').format(selectedDate!)
                  : 'Select your LMP date',
              style: FemoraTextStyles.bodyLarge.copyWith(
                color: hasDate
                    ? FemoraColors.textPrimary
                    : FemoraColors.textSecondary,
                fontWeight:
                    hasDate ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
          Icon(Icons.chevron_right_rounded,
              color: hasDate
                  ? FemoraColors.primary
                  : FemoraColors.textSecondary,
              size: 20),
        ]),
      ),
    );
  }
}

// ── Due date inline row — replaces the heavy gradient card ───────────────────
class _DueDateRow extends StatelessWidget {
  final DateTime dueDate;
  const _DueDateRow({required this.dueDate});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        // Solid primary fill — same visual weight as home "Get started"
        color: FemoraColors.primary,
        borderRadius: BorderRadius.circular(FemoraBorderRadius.medium),
        boxShadow: [
          BoxShadow(
            color: FemoraColors.primary.withOpacity(0.22),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(children: [
        const Icon(Icons.favorite_rounded, color: Colors.white70, size: 16),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Estimated Due Date',
                style: FemoraTextStyles.caption.copyWith(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                DateFormat('MMMM d, yyyy').format(dueDate),
                style: FemoraTextStyles.headlineMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '40 weeks from your LMP (Naegele\'s Rule)',
                style: FemoraTextStyles.caption
                    .copyWith(color: Colors.white60),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

// ── Solid primary button — exactly matches home screen "Get started" ──────────
class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isLoading;
  final VoidCallback? onTap;

  const _PrimaryButton({
    required this.label,
    this.icon,
    this.isLoading = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          // SOLID primary — same as home screen cards' "Get started" button
          color: FemoraColors.primary,
          borderRadius: BorderRadius.circular(FemoraBorderRadius.medium),
          boxShadow: [
            BoxShadow(
              color: FemoraColors.primary.withOpacity(0.28),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5))
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: FemoraTextStyles.bodyLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                    if (icon != null) ...[
                      const SizedBox(width: 8),
                      Icon(icon, color: Colors.white, size: 20),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}