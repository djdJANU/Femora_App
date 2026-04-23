// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../services/mental_repository.dart';

/// PHQ-2 Screen
/// ─────────────
/// Clinically validated 2-question depression screening tool.
/// Shown on first visit to Mental Wellbeing, then every 14 days.
/// Score 0-2: Low, 3-4: Mild, 5-6: High
class PHQ2Screen extends StatefulWidget {
  final VoidCallback onComplete;

  const PHQ2Screen({super.key, required this.onComplete});

  @override
  State<PHQ2Screen> createState() => _PHQ2ScreenState();
}

class _PHQ2ScreenState extends State<PHQ2Screen>
    with SingleTickerProviderStateMixin {
  final _repo = MentalRepository();

  int? _q1Answer;
  int? _q2Answer;
  bool _isSaving = false;
  bool _showResult = false;
  int _totalScore = 0;

  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  static const _options = [0, 1, 2, 3];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  bool get _canSubmit => _q1Answer != null && _q2Answer != null;

  Future<void> _submit() async {
    if (!_canSubmit || _isSaving) return;
    setState(() => _isSaving = true);
    try {
      await _repo.savePHQ2Result(
        q1Score: _q1Answer!,
        q2Score: _q2Answer!,
      );
      _totalScore = _q1Answer! + _q2Answer!;
      setState(() {
        _isSaving = false;
        _showResult = true;
      });
      _ctrl
        ..reset()
        ..forward();
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error saving. Please try again.'),
          backgroundColor: FemoraColors.error,
        ));
      }
    }
  }

  String _optionLabel(BuildContext context, int value) {
    final l10n = AppLocalizations.of(context)!;
    switch (value) {
      case 0: return l10n.phq2Option0;
      case 1: return l10n.phq2Option1;
      case 2: return l10n.phq2Option2;
      case 3: return l10n.phq2Option3;
      default: return '';
    }
  }

  Color get _resultColor {
    if (_totalScore <= 2) return FemoraColors.success;
    if (_totalScore <= 4) return FemoraColors.warning;
    return FemoraColors.error;
  }

  String _resultText(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_totalScore <= 2) return l10n.phq2ResultLow;
    if (_totalScore <= 4) return l10n.phq2ResultMild;
    return l10n.phq2ResultHigh;
  }

  String get _resultEmoji {
    if (_totalScore <= 2) return '🌸';
    if (_totalScore <= 4) return '🌿';
    return '💜';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _showResult
            ? _buildResult(context, l10n)
            : _buildQuestionnaire(context, l10n),
      ),
    );
  }

  // ── Questionnaire ─────────────────────────────────────────────────────────

  Widget _buildQuestionnaire(BuildContext context, AppLocalizations l10n) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────
            _buildHeader(l10n),

            // ── Questions ─────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 28),

                    // Instruction
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: FemoraColors.lavenderWhisper,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('📋',
                              style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              l10n.phq2Instruction,
                              style: FemoraTextStyles.bodyMedium.copyWith(
                                color: FemoraColors.textPrimary,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Q1
                    _buildQuestion(
                      context: context,
                      l10n: l10n,
                      number: 1,
                      question: l10n.phq2Q1,
                      selected: _q1Answer,
                      onSelect: (v) => setState(() => _q1Answer = v),
                    ),

                    const SizedBox(height: 24),

                    // Q2
                    _buildQuestion(
                      context: context,
                      l10n: l10n,
                      number: 2,
                      question: l10n.phq2Q2,
                      selected: _q2Answer,
                      onSelect: (v) => setState(() => _q2Answer = v),
                    ),

                    const SizedBox(height: 36),

                    // Submit button
                    GestureDetector(
                      onTap: _canSubmit ? _submit : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: double.infinity,
                        height: 54,
                        decoration: BoxDecoration(
                          color: _canSubmit
                              ? FemoraColors.primary
                              : FemoraColors.neutralLight,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: _canSubmit
                              ? [
                                  BoxShadow(
                                    color: FemoraColors.primary
                                        .withOpacity(0.28),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  )
                                ]
                              : [],
                        ),
                        child: Center(
                          child: _isSaving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Text(
                                  l10n.continueButton,
                                  style:
                                      FemoraTextStyles.bodyLarge.copyWith(
                                    color: _canSubmit
                                        ? Colors.white
                                        : FemoraColors.textSecondary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        'Your answers are private and encrypted',
                        style: FemoraTextStyles.caption.copyWith(
                          color: FemoraColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      decoration: BoxDecoration(
        color: FemoraColors.lightBackgroundTint,
        border: Border(
          bottom: BorderSide(
            color: FemoraColors.lavenderWhisper,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress dots
          Row(children: [
            _dot(filled: true),
            const SizedBox(width: 6),
            _dot(filled: true),
            const Spacer(),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: FemoraColors.lavenderWhisper,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                l10n.phq2Badge,
                style: FemoraTextStyles.caption.copyWith(
                  color: FemoraColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ]),
          const SizedBox(height: 14),
          Text(
            l10n.phq2ScreenTitle,
            style: FemoraTextStyles.headlineLarge.copyWith(
              color: FemoraColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'A quick 2-question check-in about how you\'ve been feeling.',
            style: FemoraTextStyles.bodyMedium.copyWith(
              color: FemoraColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot({required bool filled}) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? FemoraColors.primary : FemoraColors.neutralLight,
      ),
    );
  }

  Widget _buildQuestion({
    required BuildContext context,
    required AppLocalizations l10n,
    required int number,
    required String question,
    required int? selected,
    required ValueChanged<int> onSelect,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Question label
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: FemoraColors.primary,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$number',
                  style: FemoraTextStyles.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                question,
                style: FemoraTextStyles.bodyLarge.copyWith(
                  color: FemoraColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Answer options
        ...(_options.map((value) {
          final isSelected = selected == value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: () => onSelect(value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? FemoraColors.lavenderWhisper
                      : FemoraColors.lightBackgroundTint,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? FemoraColors.primary
                        : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Row(children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? FemoraColors.primary
                          : Colors.transparent,
                      border: Border.all(
                        color: isSelected
                            ? FemoraColors.primary
                            : FemoraColors.neutralLight,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check_rounded,
                            color: Colors.white, size: 12)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _optionLabel(context, value),
                      style: FemoraTextStyles.bodyMedium.copyWith(
                        color: isSelected
                            ? FemoraColors.primary
                            : FemoraColors.textPrimary,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          );
        })),
      ],
    );
  }

  // ── Result screen ─────────────────────────────────────────────────────────

  Widget _buildResult(BuildContext context, AppLocalizations l10n) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              const Spacer(),

              // Emoji
              Text(_resultEmoji,
                  style: const TextStyle(fontSize: 72)),
              const SizedBox(height: 24),

              // Score badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _resultColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _resultColor.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  'Score: $_totalScore / 6',
                  style: FemoraTextStyles.bodyMedium.copyWith(
                    color: _resultColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Result message
              Text(
                _resultText(context),
                textAlign: TextAlign.center,
                style: FemoraTextStyles.headlineMedium.copyWith(
                  color: FemoraColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _totalScore >= 5
                    ? 'We\'ve highlighted some resources on your dashboard to support you.'
                    : 'Your wellbeing dashboard is ready with tools to support you.',
                textAlign: TextAlign.center,
                style: FemoraTextStyles.bodyMedium.copyWith(
                  color: FemoraColors.textSecondary,
                  height: 1.5,
                ),
              ),

              const Spacer(),

              // CTA
              GestureDetector(
                onTap: widget.onComplete,
                child: Container(
                  width: double.infinity,
                  height: 54,
                  decoration: BoxDecoration(
                    color: FemoraColors.primary,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: FemoraColors.primary.withOpacity(0.28),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'Go to My Dashboard  →',
                      style: FemoraTextStyles.bodyLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),
              Text(
                '🔒  Your answers are private and encrypted',
                style: FemoraTextStyles.caption.copyWith(
                  color: FemoraColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
