// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../services/mental_repository.dart';
import 'phq2_screen.dart';
import 'mood_tracker_screen.dart';
import 'breathing_screen.dart';
import 'music_screen.dart';
import 'library_screen.dart';
import 'crisis_screen.dart';
import 'sleep_tracker_screen.dart';

/// Wellbeing Dashboard
/// ────────────────────
/// Main hub for the Mental Wellbeing module.
/// Entry point from bottom nav and home screen.
class WellbeingDashboard extends StatefulWidget {
  const WellbeingDashboard({super.key});

  @override
  State<WellbeingDashboard> createState() => _WellbeingDashboardState();
}

class _WellbeingDashboardState extends State<WellbeingDashboard> {
  final _repo = MentalRepository();

  bool _isLoading = true;
  bool _showPHQ2 = false;
  Map<String, dynamic>? _latestPHQ2;
  Map<String, dynamic>? _todayMood;
  List<Map<String, dynamic>> _weekMoods = [];
  String? _moodInsight;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _repo.shouldShowPHQ2(),
        _repo.getLatestPHQ2Result(),
        _repo.getTodayMoodLog(),
        _repo.getMoodLogsLast7Days(),
        _repo.getMoodInsight(),
      ]);

      if (mounted) {
        setState(() {
          _showPHQ2 = results[0] as bool;
          _latestPHQ2 = results[1] as Map<String, dynamic>?;
          _todayMood = results[2] as Map<String, dynamic>?;
          _weekMoods =
              results[3] as List<Map<String, dynamic>>;
          _moodInsight = results[4] as String?;
        });
      }
    } catch (e) {
      debugPrint('Wellbeing dashboard load error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  int get _phq2Score =>
      (_latestPHQ2?['total_score'] as int?) ?? 0;

  // ── Navigation helpers ────────────────────────────────────────────────────

  void _goTo(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    ).then((_) => _load());
  }

  void _openMoodTracker() => _goTo(const MoodTrackerScreen());
  void _openBreathing() => _goTo(const BreathingScreen());
  void _openMusic() => _goTo(const MusicScreen());
  void _openLibrary() => _goTo(const LibraryScreen());
  void _openSleepTracker() => _goTo(const SleepTrackerScreen());
  void _openCrisis() => _goTo(const CrisisScreen());

  void _openPHQ2() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PHQ2Screen(
          onComplete: () {
            Navigator.pop(context);
            _load();
          },
        ),
      ),
    );
  }

  // ── Mood helpers ──────────────────────────────────────────────────────────

  String _moodEmoji(String mood) {
    const map = {
      'happy': '😊',
      'calm': '😌',
      'anxious': '😰',
      'sad': '😢',
      'angry': '😠',
      'tired': '😴',
    };
    return map[mood] ?? '😊';
  }

  Color _moodColor(String mood) {
    const map = {
      'happy': Color(0xFFFBBF24),
      'calm': Color(0xFF34D399),
      'anxious': Color(0xFFF97316),
      'sad': Color(0xFF60A5FA),
      'angry': Color(0xFFEF4444),
      'tired': Color(0xFF8B5CF6),
    };
    return map[mood] ?? FemoraColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: FemoraColors.lightBackgroundTint,
        body: Center(
          child: CircularProgressIndicator(
              color: FemoraColors.primary),
        ),
      );
    }

    // ── First visit or 14 days passed → show PHQ-2 first ─────────────────
    if (_showPHQ2) {
      return PHQ2Screen(
        onComplete: () {
          setState(() => _showPHQ2 = false);
          _load();
        },
      );
    }

    return Scaffold(
      backgroundColor: FemoraColors.lightBackgroundTint,
      body: RefreshIndicator(
        onRefresh: _load,
        color: FemoraColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── Header ──────────────────────────────────────────
            SliverToBoxAdapter(child: _buildHeader(l10n)),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              sliver: SliverList(
                delegate: SliverChildListDelegate([

                  // ── PHQ-2 retake prompt ────────────────────────
                  // (shown only when shouldShowPHQ2 but user
                  //  dismissed it — kept here for future use)

                  // ── Today's mood ───────────────────────────────
                  _buildMoodTile(l10n),
                  const SizedBox(height: 14),

                  // ── 7-day mood strip ───────────────────────────
                  if (_weekMoods.isNotEmpty) ...[
                    _buildMoodStrip(l10n),
                    const SizedBox(height: 14),
                  ],

                  // ── Mood insight ───────────────────────────────
                  if (_moodInsight != null) ...[
                    _buildInsightCard(l10n),
                    const SizedBox(height: 14),
                  ],

                  // ── Feature grid ───────────────────────────────
                  _buildSectionTitle('Tools for You'),
                  const SizedBox(height: 12),
                  _buildFeatureGrid(l10n),
                  const SizedBox(height: 14),

                  // ── Crisis banner (conditional on score) ───────
                  if (_phq2Score >= 3) ...[
                    _buildCrisisBanner(l10n),
                    const SizedBox(height: 14),
                  ],

                  // ── Small support link (always visible) ────────
                  _buildSupportLink(l10n),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(AppLocalizations l10n) {
    final hour = DateTime.now().hour;
    String greeting;
    String greetingEmoji;
    if (hour < 12) {
      greeting = 'Good morning';
      greetingEmoji = '☀️';
    } else if (hour < 17) {
      greeting = 'Good afternoon';
      greetingEmoji = '🌤️';
    } else {
      greeting = 'Good evening';
      greetingEmoji = '🌙';
    }

    return Container(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Text(greetingEmoji,
                              style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 6),
                          Text(
                            greeting,
                            style: FemoraTextStyles.bodyMedium.copyWith(
                              color: FemoraColors.textSecondary,
                            ),
                          ),
                        ]),
                        const SizedBox(height: 2),
                        Text(
                          l10n.wellbeingTabTitle,
                          style:
                              FemoraTextStyles.headlineLarge.copyWith(
                            color: FemoraColors.textPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // PHQ-2 score chip
                  if (_latestPHQ2 != null)
                    GestureDetector(
                      onTap: _openPHQ2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _phq2Score <= 2
                              ? FemoraColors.success.withOpacity(0.1)
                              : _phq2Score <= 4
                                  ? FemoraColors.warning.withOpacity(0.1)
                                  : FemoraColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _phq2Score <= 2
                                ? FemoraColors.success.withOpacity(0.3)
                                : _phq2Score <= 4
                                    ? FemoraColors.warning.withOpacity(0.3)
                                    : FemoraColors.error.withOpacity(0.3),
                          ),
                        ),
                        child: Row(children: [
                          Icon(
                            Icons.favorite_rounded,
                            size: 12,
                            color: _phq2Score <= 2
                                ? FemoraColors.success
                                : _phq2Score <= 4
                                    ? FemoraColors.warning
                                    : FemoraColors.error,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Score $_phq2Score/6',
                            style: FemoraTextStyles.caption.copyWith(
                              color: _phq2Score <= 2
                                  ? FemoraColors.success
                                  : _phq2Score <= 4
                                      ? FemoraColors.warning
                                      : FemoraColors.error,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ]),
                      ),
                    ),
                ],
              ),
            ),
            Container(height: 1, color: FemoraColors.lavenderWhisper),
          ],
        ),
      ),
    );
  }

  // ── Today's mood tile ─────────────────────────────────────────────────────

  Widget _buildMoodTile(AppLocalizations l10n) {
    final logged = _todayMood != null;
    final mood = _todayMood?['mood'] as String?;

    return GestureDetector(
      onTap: _openMoodTracker,
      child: Container(
        margin: const EdgeInsets.only(top: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: logged ? FemoraColors.lavenderWhisper : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: logged
                ? FemoraColors.primary.withOpacity(0.3)
                : FemoraColors.neutralLight,
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
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: logged
                  ? FemoraColors.primary.withOpacity(0.12)
                  : FemoraColors.lightBackgroundTint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                logged ? _moodEmoji(mood!) : '😊',
                style: const TextStyle(fontSize: 22),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  logged
                      ? 'Today\'s mood logged'
                      : l10n.moodTrackerPrompt,
                  style: FemoraTextStyles.bodyLarge.copyWith(
                    color: FemoraColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  logged
                      ? '${_moodEmoji(mood!)}  ${mood[0].toUpperCase()}${mood.substring(1)} · Tap to update'
                      : 'Tap to log how you feel right now',
                  style: FemoraTextStyles.caption.copyWith(
                    color: logged
                        ? FemoraColors.primary
                        : FemoraColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: FemoraColors.textSecondary,
            size: 20,
          ),
        ]),
      ),
    );
  }

  // ── 7-day mood strip ──────────────────────────────────────────────────────

  Widget _buildMoodStrip(AppLocalizations l10n) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(l10n.moodInsightsTitle, Icons.bar_chart_rounded),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final daysAgo = 6 - i;
              final date = DateTime.now()
                  .subtract(Duration(days: daysAgo));
              final dayLabel = ['M','T','W','T','F','S','S']
                  [date.weekday - 1];

              // Find log for this day
              final log = _weekMoods.where((m) {
                final logDate =
                    DateTime.parse(m['logged_at']).toLocal();
                return logDate.year == date.year &&
                    logDate.month == date.month &&
                    logDate.day == date.day;
              }).firstOrNull;

              final mood = log?['mood'] as String?;
              final hasLog = mood != null;

              return Column(children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: hasLog
                        ? _moodColor(mood).withOpacity(0.15)
                        : FemoraColors.lightBackgroundTint,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: hasLog
                          ? _moodColor(mood).withOpacity(0.4)
                          : Colors.transparent,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      hasLog ? _moodEmoji(mood) : '·',
                      style: TextStyle(
                        fontSize: hasLog ? 18 : 20,
                        color: FemoraColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dayLabel,
                  style: FemoraTextStyles.caption.copyWith(
                    color: FemoraColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ]);
            }),
          ),
        ],
      ),
    );
  }

  // ── Mood insight card ─────────────────────────────────────────────────────

  Widget _buildInsightCard(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FemoraColors.lavenderWhisper,
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: FemoraColors.softLilac),
      ),
      child: Row(children: [
        const Text('✨', style: TextStyle(fontSize: 20)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            l10n.moodInsightFrequent(
              '${_moodEmoji(_moodInsight!)} ${_moodInsight![0].toUpperCase()}${_moodInsight!.substring(1)}',
            ),
            style: FemoraTextStyles.bodyMedium.copyWith(
              color: FemoraColors.textPrimary,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ),
      ]),
    );
  }

  // ── Feature grid ──────────────────────────────────────────────────────────

  Widget _buildFeatureGrid(AppLocalizations l10n) {
    final features = [
      _Feature(
        icon: Icons.air_rounded,
        label: l10n.breathingTitle,
        subtitle: l10n.breathingSubtitle,
        color: const Color(0xFF34D399),
        onTap: _openBreathing,
      ),
      _Feature(
        icon: Icons.music_note_rounded,
        label: l10n.musicTitle,
        subtitle: 'Curated playlists',
        color: const Color(0xFF60A5FA),
        onTap: _openMusic,
      ),
      _Feature(
        icon: Icons.menu_book_rounded,
        label: l10n.libraryTitle,
        subtitle: 'Articles & guides',
        color: const Color(0xFFF97316),
        onTap: _openLibrary,
      ),
      _Feature(
        icon: Icons.bedtime_rounded,
        label: l10n.sleepTitle,
        subtitle: 'Track your sleep',
        color: const Color(0xFF8B5CF6),
        onTap: _openSleepTracker,
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: features.map((f) => _buildFeatureTile(f)).toList(),
    );
  }

  Widget _buildFeatureTile(_Feature f) {
    return GestureDetector(
      onTap: f.onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: f.color.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon in a soft colored circle
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: f.color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                f.icon,
                color: f.color,
                size: 22,
              ),
            ),
            const Spacer(),
            Text(
              f.label,
              style: FemoraTextStyles.bodyMedium.copyWith(
                color: FemoraColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              f.subtitle,
              style: FemoraTextStyles.caption.copyWith(
                color: FemoraColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Crisis banner ─────────────────────────────────────────────────────────

  Widget _buildCrisisBanner(AppLocalizations l10n) {
    final isHigh = _phq2Score >= 5;
    return GestureDetector(
      onTap: _openCrisis,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isHigh
              ? FemoraColors.error.withOpacity(0.06)
              : FemoraColors.warning.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isHigh
                ? FemoraColors.error.withOpacity(0.2)
                : FemoraColors.warning.withOpacity(0.2),
          ),
        ),
        child: Row(children: [
          Text(
            isHigh ? '💜' : '🌿',
            style: const TextStyle(fontSize: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isHigh
                      ? l10n.crisisBannerHigh
                      : l10n.crisisBannerMild,
                  style: FemoraTextStyles.bodyMedium.copyWith(
                    color: FemoraColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.crisisBannerLink,
                  style: FemoraTextStyles.caption.copyWith(
                    color: isHigh
                        ? FemoraColors.error
                        : FemoraColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: FemoraColors.textSecondary,
            size: 18,
          ),
        ]),
      ),
    );
  }

  // ── Support link (always visible) ─────────────────────────────────────────

  Widget _buildSupportLink(AppLocalizations l10n) {
    return GestureDetector(
      onTap: _openCrisis,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            '💙  Need to talk to someone?',
            style: FemoraTextStyles.caption.copyWith(
              color: FemoraColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  // ── Section title ─────────────────────────────────────────────────────────

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: FemoraTextStyles.titleLarge.copyWith(
        color: FemoraColors.textPrimary,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  // ── Shared card helpers ───────────────────────────────────────────────────

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: FemoraColors.primary.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _cardHeader(String title, IconData icon) {
    return Row(children: [
      Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: FemoraColors.lavenderWhisper,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: FemoraColors.primary, size: 16),
      ),
      const SizedBox(width: 10),
      Text(
        title,
        style: FemoraTextStyles.bodyLarge.copyWith(
          color: FemoraColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    ]);
  }
}

// ── Feature tile model ────────────────────────────────────────────────────────

class _Feature {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _Feature({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
}
