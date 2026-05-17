// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../services/mental_repository.dart';

/// Mood Tracker Screen
/// ────────────────────
/// Six mood options with emoji. Optional note.
/// Saves to mental_mood_logs table.
/// Shows a 7-day pattern graph + Lumi hug for sad/anxious selections.
class MoodTrackerScreen extends StatefulWidget {
  const MoodTrackerScreen({super.key});

  @override
  State<MoodTrackerScreen> createState() => _MoodTrackerScreenState();
}

class _MoodTrackerScreenState extends State<MoodTrackerScreen>
    with SingleTickerProviderStateMixin {
  final _repo = MentalRepository();
  final _noteCtrl = TextEditingController();

  String? _selectedMood;
  bool _isSaving = false;
  bool _savedSuccessfully = false;
  Map<String, dynamic>? _todayLog;
  List<Map<String, dynamic>> _moodLogs = [];

  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;

  static const _moods = [
    _MoodOption(key: 'happy',   emoji: '😊', color: Color(0xFFFBBF24)),
    _MoodOption(key: 'calm',    emoji: '😌', color: Color(0xFF34D399)),
    _MoodOption(key: 'anxious', emoji: '😰', color: Color(0xFFF97316)),
    _MoodOption(key: 'sad',     emoji: '😢', color: Color(0xFF60A5FA)),
    _MoodOption(key: 'angry',   emoji: '😠', color: Color(0xFFEF4444)),
    _MoodOption(key: 'tired',   emoji: '😴', color: Color(0xFF8B5CF6)),
  ];

  static int _moodScore(String mood) {
    switch (mood) {
      case 'happy':   return 5;
      case 'calm':    return 4;
      case 'tired':   return 3;
      case 'anxious': return 3;
      case 'sad':     return 2;
      case 'angry':   return 1;
      default:        return 0;
    }
  }

  static Color _moodColor(String? mood) {
    switch (mood) {
      case 'happy':   return const Color(0xFFFBBF24);
      case 'calm':    return const Color(0xFF34D399);
      case 'anxious': return const Color(0xFFF97316);
      case 'sad':     return const Color(0xFF60A5FA);
      case 'angry':   return const Color(0xFFEF4444);
      case 'tired':   return const Color(0xFF8B5CF6);
      default:        return const Color(0xFFE5E7EB);
    }
  }

  static String _moodEmoji(String mood) {
    switch (mood) {
      case 'happy':   return '😊';
      case 'calm':    return '😌';
      case 'anxious': return '😰';
      case 'sad':     return '😢';
      case 'angry':   return '😠';
      case 'tired':   return '😴';
      default:        return '';
    }
  }

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
    _loadData();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final log = await _repo.getTodayMoodLog();
    final logs = await _repo.getMoodLogsLast7Days();
    if (mounted) {
      setState(() {
        _todayLog = log;
        if (log != null) {
          _selectedMood = log['mood'] as String?;
          _noteCtrl.text = (log['note'] as String?) ?? '';
        }
        _moodLogs = logs;
      });
    }
  }

  void _onMoodTapped(String key) {
    setState(() => _selectedMood = key);
    if (key == 'sad' || key == 'anxious') {
      Future.delayed(const Duration(milliseconds: 120), () {
        if (mounted) {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            isScrollControlled: true,
            builder: (_) => const _LumiHugSheet(),
          );
        }
      });
    }
  }

  Future<void> _save() async {
    if (_selectedMood == null || _isSaving) return;
    setState(() => _isSaving = true);
    try {
      await _repo.saveMoodLog(
        mood: _selectedMood!,
        note: _noteCtrl.text.trim().isEmpty
            ? null
            : _noteCtrl.text.trim(),
      );
      if (mounted) {
        setState(() {
          _isSaving = false;
          _savedSuccessfully = true;
        });
        await Future.delayed(const Duration(milliseconds: 1200));
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Could not save. Please try again.'),
          backgroundColor: FemoraColors.error,
        ));
      }
    }
  }

  String _moodLabel(BuildContext context, String key) {
    final l10n = AppLocalizations.of(context)!;
    switch (key) {
      case 'happy':   return l10n.moodHappy;
      case 'calm':    return l10n.moodCalm;
      case 'anxious': return l10n.moodAnxious;
      case 'sad':     return l10n.moodSad;
      case 'angry':   return l10n.moodAngry;
      case 'tired':   return l10n.moodTired;
      default:        return key;
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
          child: Column(
            children: [
              _buildHeader(l10n),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      if (_todayLog != null) ...[
                        _buildAlreadyLoggedBanner(l10n),
                        const SizedBox(height: 20),
                      ],

                      Text(
                        l10n.moodTrackerPrompt,
                        style: FemoraTextStyles.headlineMedium.copyWith(
                          color: FemoraColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Choose the emoji that best matches\nhow you feel right now.',
                        style: FemoraTextStyles.bodyMedium.copyWith(
                          color: FemoraColors.textSecondary,
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ── Mood grid ────────────────────────────────────────
                      GridView.count(
                        crossAxisCount: 3,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.95,
                        children: _moods.map((m) {
                          final selected = _selectedMood == m.key;
                          return GestureDetector(
                            onTap: () => _onMoodTapped(m.key),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              decoration: BoxDecoration(
                                color: selected
                                    ? m.color.withOpacity(0.12)
                                    : FemoraColors.lightBackgroundTint,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: selected
                                      ? m.color
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  AnimatedScale(
                                    scale: selected ? 1.2 : 1.0,
                                    duration:
                                        const Duration(milliseconds: 180),
                                    child: Text(
                                      m.emoji,
                                      style:
                                          const TextStyle(fontSize: 36),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _moodLabel(context, m.key),
                                    style: FemoraTextStyles.caption.copyWith(
                                      color: selected
                                          ? m.color
                                          : FemoraColors.textSecondary,
                                      fontWeight: selected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 28),

                      // ── 7-day mood pattern graph ──────────────────────────
                      _buildMoodGraph(),

                      const SizedBox(height: 28),

                      // ── Note field ────────────────────────────────────────
                      Text(
                        'Add a note',
                        style: FemoraTextStyles.bodyLarge.copyWith(
                          color: FemoraColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _noteCtrl,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: l10n.moodTrackerNoteHint,
                          hintStyle: TextStyle(
                              color: FemoraColors.textSecondary),
                          filled: true,
                          fillColor: FemoraColors.lightBackgroundTint,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: FemoraColors.primary,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // ── Save button ───────────────────────────────────────
                      GestureDetector(
                        onTap: _selectedMood != null ? _save : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: double.infinity,
                          height: 54,
                          decoration: BoxDecoration(
                            color: _savedSuccessfully
                                ? FemoraColors.success
                                : _selectedMood != null
                                    ? FemoraColors.primary
                                    : FemoraColors.neutralLight,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: _selectedMood != null
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
                                : _savedSuccessfully
                                    ? Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.check_circle_rounded,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            l10n.moodTrackerSaved,
                                            style: FemoraTextStyles
                                                .bodyLarge
                                                .copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      )
                                    : Text(
                                        l10n.saveButton,
                                        style: FemoraTextStyles.bodyLarge
                                            .copyWith(
                                          color: _selectedMood != null
                                              ? Colors.white
                                              : FemoraColors.textSecondary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),
                      Center(
                        child: Text(
                          '🔒  Your mood data is private',
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
      ),
    );
  }

  // ── 7-day mood pattern graph ──────────────────────────────────────────────

  Widget _buildMoodGraph() {
    final now = DateTime.now();

    // Map each of the last 7 days (index 0 = oldest, 6 = today)
    // to the most recent mood logged on that calendar day.
    final dayMoods = <int, Map<String, dynamic>>{};
    for (final log in _moodLogs) {
      final dt = DateTime.tryParse(log['logged_at'] as String? ?? '');
      if (dt == null) continue;
      final dayDiff = DateTime(now.year, now.month, now.day)
          .difference(DateTime(dt.year, dt.month, dt.day))
          .inDays;
      if (dayDiff < 0 || dayDiff >= 7) continue;
      final idx = 6 - dayDiff;
      dayMoods.putIfAbsent(idx, () => log);
    }

    const maxBarH = 72.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F5FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9D8FD)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insights_rounded,
                  color: Color(0xFF8B5CF6), size: 16),
              const SizedBox(width: 6),
              Text(
                'Mood This Week',
                style: FemoraTextStyles.bodyMedium.copyWith(
                  color: FemoraColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (_moodLogs.isEmpty)
                Text(
                  'Log your mood to see patterns',
                  style: FemoraTextStyles.caption.copyWith(
                    color: FemoraColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (i) {
              final date = now.subtract(Duration(days: 6 - i));
              final log = dayMoods[i];
              final mood = log?['mood'] as String?;
              final score = mood != null ? _moodScore(mood) : 0;
              final barH =
                  score > 0 ? (score / 5) * maxBarH : 4.0;
              final barColor = _moodColor(mood);
              final dayAbbr = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri',
                  'Sat', 'Sun'][date.weekday - 1];
              final isToday = date.day == now.day &&
                  date.month == now.month;

              return Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    mood != null ? _moodEmoji(mood) : '',
                    style: const TextStyle(fontSize: 11),
                  ),
                  const SizedBox(height: 3),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 450),
                    curve: Curves.easeOut,
                    width: 28,
                    height: barH,
                    decoration: BoxDecoration(
                      color: barColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    dayAbbr,
                    style: FemoraTextStyles.caption.copyWith(
                      color: isToday
                          ? const Color(0xFF8B5CF6)
                          : FemoraColors.textSecondary,
                      fontWeight: isToday
                          ? FontWeight.w700
                          : FontWeight.w400,
                      fontSize: 10,
                    ),
                  ),
                ],
              );
            }),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              _legendItem(const Color(0xFFFBBF24), '😊 Happy'),
              _legendItem(const Color(0xFF34D399), '😌 Calm'),
              _legendItem(const Color(0xFFF97316), '😰 Anxious'),
              _legendItem(const Color(0xFF60A5FA), '😢 Sad'),
              _legendItem(const Color(0xFFEF4444), '😠 Angry'),
              _legendItem(const Color(0xFF8B5CF6), '😴 Tired'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 4),
      Text(
        label,
        style: FemoraTextStyles.caption.copyWith(
          color: FemoraColors.textSecondary,
          fontSize: 10,
        ),
      ),
    ],
  );

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
        Text(
          l10n.moodTrackerTitle,
          style: FemoraTextStyles.titleLarge.copyWith(
            color: FemoraColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ]),
    );
  }

  // ── Already logged banner ─────────────────────────────────────────────────

  Widget _buildAlreadyLoggedBanner(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: FemoraColors.lavenderWhisper,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FemoraColors.softLilac),
      ),
      child: Row(children: [
        const Icon(Icons.info_outline_rounded,
            color: FemoraColors.primary, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'You\'ve already logged your mood today. You can update it below.',
            style: FemoraTextStyles.caption.copyWith(
              color: FemoraColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Lumi Hug Bottom Sheet ─────────────────────────────────────────────────────

class _LumiHugSheet extends StatelessWidget {
  const _LumiHugSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Lumi caring image
          Image.asset(
            'assets/images/lumi/lumi_caring.png',
            height: 130,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 20),

          const Text(
            'Femi sends you a hug 💜',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1F1235),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            'It\'s okay to not feel okay.\nYou\'re not alone — and you\'re stronger\nthan you think. Take a deep breath. 🌸',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.65,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),

          // Close button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFFD946EF)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withOpacity(0.30),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'Thank you, Femi 💜',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mood option model ──────────────────────────────────────────────────────────

class _MoodOption {
  final String key;
  final String emoji;
  final Color color;

  const _MoodOption({
    required this.key,
    required this.emoji,
    required this.color,
  });
}
