// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../services/mental_repository.dart';

/// Sleep Tracker Screen
/// ─────────────────────
/// Dedicated screen for logging last night's sleep.
/// Shows quality picker (1–5), hours slept input, optional note,
/// and a combined 7-day sleep + mood bar chart.
class SleepTrackerScreen extends StatefulWidget {
  const SleepTrackerScreen({super.key});

  @override
  State<SleepTrackerScreen> createState() => _SleepTrackerScreenState();
}

class _SleepTrackerScreenState extends State<SleepTrackerScreen>
    with SingleTickerProviderStateMixin {
  final _repo = MentalRepository();
  final _hoursCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  int? _selectedQuality; // 1–5
  bool _isSaving = false;
  bool _savedSuccessfully = false;
  Map<String, dynamic>? _todayLog;
  List<Map<String, dynamic>> _weekSleepLogs = [];
  List<Map<String, dynamic>> _weekMoodLogs = [];

  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;

  static const _qualityEmojis = ['😴', '😪', '😐', '😊', '✨'];
  static const _qualityColors = [
    Color(0xFFEF4444),
    Color(0xFFF97316),
    Color(0xFFEAB308),
    Color(0xFF34D399),
    Color(0xFF8B5CF6),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
    _loadData();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _hoursCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final sleepLogs = await _repo.getSleepLogsLast7Days();
      final moodLogs = await _repo.getMoodLogsLast7Days();

      final today = DateTime.now();
      final todayStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final todayLog = sleepLogs
          .where((l) => (l['sleep_date'] as String?) == todayStr)
          .firstOrNull;

      if (mounted) {
        setState(() {
          _weekSleepLogs = sleepLogs;
          _weekMoodLogs = moodLogs;
          _todayLog = todayLog;
          if (todayLog != null) {
            _selectedQuality = (todayLog['sleep_quality'] as num?)?.toInt();
            final hours = todayLog['hours_slept'];
            if (hours != null) _hoursCtrl.text = hours.toString();
            _noteCtrl.text = (todayLog['note'] as String?) ?? '';
          }
        });
      }
    } catch (e) {
      debugPrint('SleepTrackerScreen._loadData error: $e');
    }
  }

  Future<void> _save() async {
    if (_selectedQuality == null || _isSaving) return;
    setState(() => _isSaving = true);
    try {
      final hours = double.tryParse(_hoursCtrl.text.trim());
      await _repo.saveSleepLog(
        sleepDate: DateTime.now(),
        sleepQuality: _selectedQuality!,
        hoursSlept: hours,
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      );
      if (mounted) {
        setState(() {
          _isSaving = false;
          _savedSuccessfully = true;
        });
        await Future.delayed(const Duration(milliseconds: 1200));
        if (mounted) Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Could not save. Please try again.'),
          backgroundColor: FemoraColors.error,
        ));
      }
    }
  }

  int _moodToScore(String mood) {
    switch (mood) {
      case 'happy':
        return 5;
      case 'calm':
        return 4;
      case 'anxious':
        return 3;
      case 'tired':
        return 3;
      case 'sad':
        return 2;
      case 'angry':
        return 1;
      default:
        return 3;
    }
  }

  String _qualityLabel(int q, AppLocalizations l10n) {
    switch (q) {
      case 1:
        return l10n.sleepQuality1;
      case 2:
        return l10n.sleepQuality2;
      case 3:
        return l10n.sleepQuality3;
      case 4:
        return l10n.sleepQuality4;
      case 5:
        return l10n.sleepQuality5;
      default:
        return '';
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
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_todayLog != null) ...[
                        _buildAlreadyLoggedBanner(),
                        const SizedBox(height: 20),
                      ],

                      // Prompt
                      Text(
                        l10n.sleepQualityPrompt,
                        style: FemoraTextStyles.headlineMedium.copyWith(
                          color: FemoraColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Rate your sleep quality and how long you slept.',
                        style: FemoraTextStyles.bodyMedium.copyWith(
                          color: FemoraColors.textSecondary,
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 28),

                      _buildQualitySelector(l10n),

                      const SizedBox(height: 24),

                      _buildHoursInput(l10n),

                      const SizedBox(height: 20),

                      Text(
                        'Notes (optional)',
                        style: FemoraTextStyles.bodyLarge.copyWith(
                          color: FemoraColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _noteCtrl,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: l10n.sleepNoteHint,
                          hintStyle:
                              TextStyle(color: FemoraColors.textSecondary),
                          filled: true,
                          fillColor: FemoraColors.lightBackgroundTint,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: Color(0xFF8B5CF6), width: 1.5),
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // 7-day combined graph
                      _buildCombinedGraph(),

                      const SizedBox(height: 28),

                      // Save button
                      GestureDetector(
                        onTap: _selectedQuality != null ? _save : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: double.infinity,
                          height: 54,
                          decoration: BoxDecoration(
                            color: _savedSuccessfully
                                ? FemoraColors.success
                                : _selectedQuality != null
                                    ? const Color(0xFF8B5CF6)
                                    : FemoraColors.neutralLight,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: _selectedQuality != null
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF8B5CF6)
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
                                        color: Colors.white, strokeWidth: 2.5),
                                  )
                                : _savedSuccessfully
                                    ? Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                              Icons.check_circle_rounded,
                                              color: Colors.white,
                                              size: 20),
                                          const SizedBox(width: 8),
                                          Text(
                                            l10n.sleepSaved,
                                            style: FemoraTextStyles.bodyLarge
                                                .copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      )
                                    : Text(
                                        l10n.saveButton,
                                        style:
                                            FemoraTextStyles.bodyLarge.copyWith(
                                          color: _selectedQuality != null
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
                          '🔒  Your sleep data is private',
                          style: FemoraTextStyles.caption
                              .copyWith(color: FemoraColors.textSecondary),
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

  Widget _buildHeader(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
            bottom:
                BorderSide(color: FemoraColors.lavenderWhisper, width: 1)),
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
            child: const Icon(Icons.arrow_back_rounded,
                color: FemoraColors.textPrimary, size: 18),
          ),
        ),
        const SizedBox(width: 14),
        Text(
          l10n.sleepTitle,
          style: FemoraTextStyles.titleLarge.copyWith(
              color: FemoraColors.textPrimary, fontWeight: FontWeight.w800),
        ),
      ]),
    );
  }

  Widget _buildAlreadyLoggedBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF8B5CF6).withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.25)),
      ),
      child: Row(children: [
        const Icon(Icons.bedtime_rounded,
            color: Color(0xFF8B5CF6), size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            "You've already logged sleep for today. You can update it below.",
            style: FemoraTextStyles.caption.copyWith(
                color: const Color(0xFF8B5CF6),
                fontWeight: FontWeight.w600),
          ),
        ),
      ]),
    );
  }

  Widget _buildQualitySelector(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sleep Quality',
          style: FemoraTextStyles.bodyLarge.copyWith(
              color: FemoraColors.textPrimary, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Row(
          children: List.generate(5, (i) {
            final q = i + 1;
            final selected = _selectedQuality == q;
            final color = _qualityColors[i];
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedQuality = q),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: EdgeInsets.only(right: i < 4 ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: selected
                        ? color.withOpacity(0.12)
                        : FemoraColors.lightBackgroundTint,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: selected ? color : Colors.transparent,
                        width: 2),
                  ),
                  child: Column(children: [
                    AnimatedScale(
                      scale: selected ? 1.2 : 1.0,
                      duration: const Duration(milliseconds: 180),
                      child: Text(_qualityEmojis[i],
                          style: const TextStyle(fontSize: 24)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      q.toString(),
                      style: FemoraTextStyles.caption.copyWith(
                        color: selected ? color : FemoraColors.textSecondary,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 11,
                      ),
                    ),
                  ]),
                ),
              ),
            );
          }),
        ),
        if (_selectedQuality != null) ...[
          const SizedBox(height: 8),
          Center(
            child: Text(
              _qualityLabel(_selectedQuality!, l10n),
              style: FemoraTextStyles.bodyMedium.copyWith(
                color: _qualityColors[_selectedQuality! - 1],
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildHoursInput(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hours Slept',
          style: FemoraTextStyles.bodyLarge.copyWith(
              color: FemoraColors.textPrimary, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _hoursCtrl,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(
                RegExp(r'^\d{0,2}\.?\d{0,1}'))
          ],
          decoration: InputDecoration(
            hintText: l10n.sleepHoursHint,
            hintStyle: TextStyle(color: FemoraColors.textSecondary),
            filled: true,
            fillColor: FemoraColors.lightBackgroundTint,
            suffixText: 'hrs',
            suffixStyle: FemoraTextStyles.bodyMedium
                .copyWith(color: FemoraColors.textSecondary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                  color: Color(0xFF8B5CF6), width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Recommended: 7–9 hrs',
          style: FemoraTextStyles.caption
              .copyWith(color: FemoraColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildCombinedGraph() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FemoraColors.lavenderWhisper),
        boxShadow: [
          BoxShadow(
            color: FemoraColors.primary.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.bar_chart_rounded,
                  color: Color(0xFF8B5CF6), size: 16),
            ),
            const SizedBox(width: 10),
            Text(
              'Last 7 Days',
              style: FemoraTextStyles.bodyLarge.copyWith(
                  color: FemoraColors.textPrimary,
                  fontWeight: FontWeight.w700),
            ),
          ]),
          const SizedBox(height: 8),
          // Legend
          Row(children: [
            _legendDot(const Color(0xFF8B5CF6)),
            const SizedBox(width: 4),
            Text('Sleep',
                style: FemoraTextStyles.caption
                    .copyWith(color: FemoraColors.textSecondary)),
            const SizedBox(width: 14),
            _legendDot(const Color(0xFFFBBF24)),
            const SizedBox(width: 4),
            Text('Mood',
                style: FemoraTextStyles.caption
                    .copyWith(color: FemoraColors.textSecondary)),
          ]),
          const SizedBox(height: 16),
          // Bars
          SizedBox(
            height: 88,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final daysAgo = 6 - i;
                final date =
                    DateTime.now().subtract(Duration(days: daysAgo));
                final dateStr =
                    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                final dayLabel =
                    ['M', 'T', 'W', 'T', 'F', 'S', 'S'][date.weekday - 1];

                final sleepLog = _weekSleepLogs
                    .where((l) =>
                        (l['sleep_date'] as String?) == dateStr)
                    .firstOrNull;
                final sleepQ =
                    (sleepLog?['sleep_quality'] as num?)?.toDouble() ??
                        0;

                final moodLog = _weekMoodLogs.where((m) {
                  final logDate =
                      DateTime.parse(m['logged_at']).toLocal();
                  return logDate.year == date.year &&
                      logDate.month == date.month &&
                      logDate.day == date.day;
                }).firstOrNull;
                final moodScore = moodLog != null
                    ? _moodToScore(moodLog['mood'] as String).toDouble()
                    : 0;

                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i < 6 ? 4 : 0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Sleep bar (purple)
                              Expanded(
                                child: Align(
                                  alignment: Alignment.bottomCenter,
                                  child: AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 600),
                                    height: sleepQ > 0
                                        ? (sleepQ / 5) * 62 + 4
                                        : 3,
                                    decoration: BoxDecoration(
                                      color: sleepQ > 0
                                          ? const Color(0xFF8B5CF6)
                                              .withOpacity(0.8)
                                          : FemoraColors.neutralLight,
                                      borderRadius:
                                          BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 2),
                              // Mood bar (amber)
                              Expanded(
                                child: Align(
                                  alignment: Alignment.bottomCenter,
                                  child: AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 600),
                                    height: moodScore > 0
                                        ? (moodScore / 5) * 62 + 4
                                        : 3,
                                    decoration: BoxDecoration(
                                      color: moodScore > 0
                                          ? const Color(0xFFFBBF24)
                                              .withOpacity(0.85)
                                          : FemoraColors.neutralLight,
                                      borderRadius:
                                          BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          dayLabel,
                          style: FemoraTextStyles.caption.copyWith(
                              color: FemoraColors.textSecondary,
                              fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
