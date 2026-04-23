// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/locale_provider.dart';

/// Language Selection Screen
/// Shown ONCE on first launch, before authentication.
class LanguageSelectionScreen extends StatefulWidget {
  final VoidCallback onLanguageSelected;

  const LanguageSelectionScreen({
    super.key,
    required this.onLanguageSelected,
  });

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen>
    with SingleTickerProviderStateMixin {
  String? _selectedCode;
  bool _isSaving = false;

  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  static const _languages = [
    _LangOption(
      code: 'en',
      flag: '🇬🇧',
      nativeName: 'English',
      subtitle: 'Continue in English',
    ),
    _LangOption(
      code: 'si',
      flag: '🇱🇰',
      nativeName: 'සිංහල',
      subtitle: 'සිංහලෙන් ඉදිරිපත් කරන්න',
    ),
    _LangOption(
      code: 'ta',
      flag: '🇱🇰',
      nativeName: 'தமிழ்',
      subtitle: 'தமிழில் தொடரவும்',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
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

  Future<void> _confirm() async {
    if (_selectedCode == null) return;
    setState(() => _isSaving = true);
    await context.read<LocaleProvider>().setLocale(Locale(_selectedCode!));
    if (mounted) widget.onLanguageSelected();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 48),

                  // ── Logo + app name ──────────────────────────────
                  Row(children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: FemoraColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          'F',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Femora',
                      style: FemoraTextStyles.headlineMedium.copyWith(
                        color: FemoraColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ]),

                  const SizedBox(height: 44),

                  // ── Heading ──────────────────────────────────────
                  Text(
                    'Welcome',
                    style: FemoraTextStyles.displayLarge.copyWith(
                      color: FemoraColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose the language you\'re\nmost comfortable with.',
                    style: FemoraTextStyles.bodyLarge.copyWith(
                      color: FemoraColors.textSecondary,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 36),

                  // ── Language cards ───────────────────────────────
                  ..._languages.map((lang) {
                    final selected = _selectedCode == lang.code;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _LanguageCard(
                        option: lang,
                        isSelected: selected,
                        onTap: () =>
                            setState(() => _selectedCode = lang.code),
                      ),
                    );
                  }),

                  const Spacer(),

                  // ── Helper text ──────────────────────────────────
                  if (_selectedCode == null)
                    Center(
                      child: Text(
                        'Tap a language to select it',
                        style: FemoraTextStyles.caption.copyWith(
                          color: FemoraColors.textSecondary,
                        ),
                      ),
                    ),

                  const SizedBox(height: 14),

                  // ── Continue button ──────────────────────────────
                  GestureDetector(
                    onTap: (_selectedCode != null && !_isSaving)
                        ? _confirm
                        : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: double.infinity,
                      height: 54,
                      decoration: BoxDecoration(
                        color: _selectedCode != null
                            ? FemoraColors.primary
                            : FemoraColors.neutralLight,
                        borderRadius:
                            BorderRadius.circular(FemoraBorderRadius.medium),
                        boxShadow: _selectedCode != null
                            ? [
                                BoxShadow(
                                  color:
                                      FemoraColors.primary.withOpacity(0.28),
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
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Continue',
                                    style: FemoraTextStyles.bodyLarge.copyWith(
                                      color: _selectedCode != null
                                          ? Colors.white
                                          : FemoraColors.textSecondary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    color: _selectedCode != null
                                        ? Colors.white
                                        : FemoraColors.textSecondary,
                                    size: 18,
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Footer note ──────────────────────────────────
                  Center(
                    child: Text(
                      'You can change this anytime in Settings',
                      style: FemoraTextStyles.caption.copyWith(
                        color: FemoraColors.textSecondary,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Language card ─────────────────────────────────────────────────────────────
class _LanguageCard extends StatelessWidget {
  final _LangOption option;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageCard({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? FemoraColors.lavenderWhisper
              : FemoraColors.lightBackgroundTint,
          borderRadius:
              BorderRadius.circular(FemoraBorderRadius.medium),
          border: Border.all(
            color: isSelected
                ? FemoraColors.primary
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(children: [
          // ── Flag ──────────────────────────────────────────
          Text(option.flag, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 14),

          // ── Language name + subtitle ───────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  option.nativeName,
                  style: FemoraTextStyles.bodyLarge.copyWith(
                    color: isSelected
                        ? FemoraColors.primary
                        : FemoraColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  option.subtitle,
                  style: FemoraTextStyles.caption.copyWith(
                    color: FemoraColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // ── Selection indicator ────────────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 22,
            height: 22,
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
                ? const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 13,
                  )
                : null,
          ),
        ]),
      ),
    );
  }
}

// ── Data model ────────────────────────────────────────────────────────────────
class _LangOption {
  final String code;
  final String flag;
  final String nativeName;
  final String subtitle;

  const _LangOption({
    required this.code,
    required this.flag,
    required this.nativeName,
    required this.subtitle,
  });
}
