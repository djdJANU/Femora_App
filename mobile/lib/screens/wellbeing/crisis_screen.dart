// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/app_theme.dart';
import '../../l10n/app_localizations.dart';

/// Crisis Resources Screen
/// ────────────────────────
/// Always accessible. Warm, non-alarming design.
/// Tap to call — uses url_launcher tel: scheme.
/// Fully translated in all 3 languages.
class CrisisScreen extends StatefulWidget {
  const CrisisScreen({super.key});

  @override
  State<CrisisScreen> createState() => _CrisisScreenState();
}

class _CrisisScreenState extends State<CrisisScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim =
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _call(String number) async {
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open dialler. Please call $number manually.'),
            backgroundColor: FemoraColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: Column(
              children: [
                // ── Header ──────────────────────────────────────
                _buildHeader(l10n),

                // ── Content ──────────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                        24, 28, 24, 40),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        // ── Hero message ───────────────────────
                        _buildHeroMessage(l10n),

                        const SizedBox(height: 28),

                        // ── Contact cards ──────────────────────
                        Text(
                          'Helplines',
                          style:
                              FemoraTextStyles.titleLarge.copyWith(
                            color: FemoraColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 14),

                        _buildContactCard(
                          name: l10n.crisisNIMHName,
                          number: l10n.crisisNIMHNumber,
                          description: l10n.crisisNIMHDescription,
                          emoji: '🏥',
                          isHighlighted: true,
                          onCall: () =>
                              _call(l10n.crisisNIMHNumber),
                          l10n: l10n,
                        ),

                        const SizedBox(height: 12),

                        _buildContactCard(
                          name: l10n.crisisSahanayaName,
                          number: l10n.crisisSahanayaNumber,
                          description:
                              l10n.crisisSahanayaDescription,
                          emoji: '🤝',
                          isHighlighted: false,
                          onCall: () =>
                              _call(l10n.crisisSahanayaNumber),
                          l10n: l10n,
                        ),

                        const SizedBox(height: 28),

                        // ── Encouragement ──────────────────────
                        _buildEncouragement(l10n),

                        const SizedBox(height: 28),

                        // ── What to expect ─────────────────────
                        _buildWhatToExpect(l10n),

                        const SizedBox(height: 20),

                        // ── Privacy note ────────────────────────
                        Center(
                          child: Text(
                            '🔒  ${l10n.crisisPrivacyNote}',
                            textAlign: TextAlign.center,
                            style:
                                FemoraTextStyles.caption.copyWith(
                              color: FemoraColors.textSecondary,
                              height: 1.5,
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
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: FemoraColors.lavenderWhisper,
            width: 1,
          ),
        ),
      ),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: FemoraColors.lightBackgroundTint,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: FemoraColors.textPrimary,
              size: 18,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.crisisTitle,
              style: FemoraTextStyles.titleLarge.copyWith(
                color: FemoraColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              'Sri Lanka Mental Health Support',
              style: FemoraTextStyles.caption.copyWith(
                color: FemoraColors.textSecondary,
              ),
            ),
          ],
        ),
      ]),
    );
  }

  // ── Hero message ──────────────────────────────────────────────────────────

  Widget _buildHeroMessage(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: FemoraColors.lavenderWhisper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FemoraColors.softLilac),
      ),
      child: Column(
        children: [
          const Text('💜', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 12),
          Text(
            l10n.crisisSubtitle,
            textAlign: TextAlign.center,
            style: FemoraTextStyles.bodyLarge.copyWith(
              color: FemoraColors.textPrimary,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Reaching out takes courage.\nYou deserve support.',
            textAlign: TextAlign.center,
            style: FemoraTextStyles.bodyMedium.copyWith(
              color: FemoraColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── Contact card ──────────────────────────────────────────────────────────

  Widget _buildContactCard({
    required String name,
    required String number,
    required String description,
    required String emoji,
    required bool isHighlighted,
    required VoidCallback onCall,
    required AppLocalizations l10n,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isHighlighted
            ? FemoraColors.primary.withOpacity(0.04)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHighlighted
              ? FemoraColors.primary.withOpacity(0.2)
              : FemoraColors.neutralLight,
          width: isHighlighted ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: FemoraColors.primary.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(children: [
        // Emoji icon
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isHighlighted
                ? FemoraColors.lavenderWhisper
                : FemoraColors.lightBackgroundTint,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child:
                Text(emoji, style: const TextStyle(fontSize: 22)),
          ),
        ),

        const SizedBox(width: 14),

        // Name + number + description
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: FemoraTextStyles.bodyLarge.copyWith(
                  color: FemoraColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                number,
                style: FemoraTextStyles.headlineMedium.copyWith(
                  color: FemoraColors.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                description,
                style: FemoraTextStyles.caption.copyWith(
                  color: FemoraColors.textSecondary,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 10),

        // Call button
        GestureDetector(
          onTap: onCall,
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: FemoraColors.primary,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: FemoraColors.primary.withOpacity(0.28),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.phone_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ]),
    );
  }

  // ── Encouragement ─────────────────────────────────────────────────────────

  Widget _buildEncouragement(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FemoraColors.success.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: FemoraColors.success.withOpacity(0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🌱', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.crisisEncouragement,
              style: FemoraTextStyles.bodyMedium.copyWith(
                color: FemoraColors.textPrimary,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── What to expect ────────────────────────────────────────────────────────

  Widget _buildWhatToExpect(AppLocalizations l10n) {
    const steps = [
      _Step(
        emoji: '📞',
        title: 'Call the helpline',
        description: 'A trained counsellor will answer.',
      ),
      _Step(
        emoji: '🗣️',
        title: 'Share what you\'re feeling',
        description:
            'There is no right or wrong thing to say.',
      ),
      _Step(
        emoji: '💙',
        title: 'Receive support',
        description:
            'They will listen without judgement and help you find next steps.',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What to expect',
          style: FemoraTextStyles.titleLarge.copyWith(
            color: FemoraColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 14),
        ...steps.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: FemoraColors.lightBackgroundTint,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(s.emoji,
                          style: const TextStyle(fontSize: 18)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.title,
                          style:
                              FemoraTextStyles.bodyMedium.copyWith(
                            color: FemoraColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          s.description,
                          style:
                              FemoraTextStyles.caption.copyWith(
                            color: FemoraColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}

// ── Step model ────────────────────────────────────────────────────────────────

class _Step {
  final String emoji;
  final String title;
  final String description;

  const _Step({
    required this.emoji,
    required this.title,
    required this.description,
  });
}
