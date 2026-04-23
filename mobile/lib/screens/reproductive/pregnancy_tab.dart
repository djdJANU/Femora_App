// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
import '../../models/pregnancy_record.dart';
import '../../services/pregnancy_repository.dart';
import '../../services/pregnancy_week_data.dart';
import 'pregnancy_setup_screen.dart';

/// Pregnancy Tab — Redesigned
/// ─────────────────────────────────────
/// UI changes (logic 100% untouched):
///   • Removed the large full-screen purple gradient hero — replaced with a
///     compact white header card (illustration + week info side-by-side)
///   • Progress bar moved just below the header, thin and minimal
///   • ALL buttons: solid primary (#A66CFF), no gradients — matches home screen
///   • Cards: white with very light shadow, no heavy borders
class PregnancyTab extends StatefulWidget {
  const PregnancyTab({super.key});

  @override
  State<PregnancyTab> createState() => _PregnancyTabState();
}

class _PregnancyTabState extends State<PregnancyTab>
    with SingleTickerProviderStateMixin {
  final _repo = PregnancyRepository();
  final _weekData = PregnancyWeekDataService.instance;

  PregnancyRecord? _pregnancy;
  PregnancyDailyLog? _todayLog;
  bool _isLoading = true;

  // Kick counter
  int _kickCount = 0;
  DateTime? _kickStart;
  bool _kickActive = false;

  // Entry animation
  late AnimationController _entryCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim =
        CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _slideAnim =
        Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
            .animate(
                CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut));
    _load();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final p = await _repo.getActivePregnancy();
      if (p != null) {
        final log = await _repo.getDailyLog(
            pregnancyId: p.id, date: DateTime.now());
        if (mounted) {
          setState(() {
            _pregnancy = p;
            _todayLog = log;
          });
          _entryCtrl.forward(from: 0);
        }
      } else {
        if (mounted) setState(() => _pregnancy = null);
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Kick counter ──────────────────────────────────────────────────────────

  void _startKick() => setState(() {
        _kickActive = true;
        _kickStart = DateTime.now();
        _kickCount = 0;
      });

  void _tapKick() {
    if (_kickActive) setState(() => _kickCount++);
  }

  Future<void> _stopKick() async {
    if (!_kickActive || _pregnancy == null) return;
    final end = DateTime.now();
    setState(() => _kickActive = false);
    try {
      await _repo.saveKickSession(
          pregnancyId: _pregnancy!.id,
          kickCount: _kickCount,
          startedAt: _kickStart!,
          completedAt: end);
      _snack('$_kickCount kicks saved ✓');
    } catch (_) {}
  }

  // ── Manage sheet ──────────────────────────────────────────────────────────

  void _showManageSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: FemoraColors.neutralLight,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Text('Manage Pregnancy',
                style: FemoraTextStyles.headlineMedium.copyWith(
                    color: FemoraColors.textPrimary,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(
                'Week ${_pregnancy?.currentWeek ?? 0} · '
                '${_pregnancy?.trimesterLabel ?? ""}',
                style: FemoraTextStyles.caption
                    .copyWith(color: FemoraColors.textSecondary)),
            const SizedBox(height: 24),
            _sheetOption(
              icon: Icons.edit_calendar_rounded,
              iconBg: FemoraColors.lavenderWhisper,
              iconColor: FemoraColors.primary,
              title: 'Started on wrong date?',
              subtitle: 'Delete and re-enter your LMP to fix it.',
              onTap: () {
                Navigator.pop(ctx);
                _deletePregnancy();
              },
            ),
            const SizedBox(height: 12),
            _sheetOption(
              icon: Icons.delete_outline_rounded,
              iconBg: FemoraColors.error.withOpacity(0.08),
              iconColor: FemoraColors.error,
              title: 'Remove this pregnancy',
              subtitle: 'Permanently delete all data and logs.',
              isDestructive: true,
              onTap: () {
                Navigator.pop(ctx);
                _deletePregnancy();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _sheetOption({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(FemoraSpacing.md),
        decoration: BoxDecoration(
          color: isDestructive
              ? FemoraColors.error.withOpacity(0.04)
              : FemoraColors.lightBackgroundTint,
          borderRadius:
              BorderRadius.circular(FemoraBorderRadius.medium),
          border: Border.all(
            color: isDestructive
                ? FemoraColors.error.withOpacity(0.2)
                : FemoraColors.neutralLight,
          ),
        ),
        child: Row(children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: FemoraSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: FemoraTextStyles.bodyLarge.copyWith(
                        color: isDestructive
                            ? FemoraColors.error
                            : FemoraColors.textPrimary,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: FemoraTextStyles.caption
                        .copyWith(color: FemoraColors.textSecondary)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded,
              color: isDestructive
                  ? FemoraColors.error.withOpacity(0.5)
                  : FemoraColors.textSecondary,
              size: 20),
        ]),
      ),
    );
  }

  // ── Log sheet ─────────────────────────────────────────────────────────────

  void _openLogSheet() {
    if (_pregnancy == null) return;
    final moods = [
      ('😊', 'Happy'),
      ('😴', 'Tired'),
      ('😰', 'Anxious'),
      ('🥰', 'Excited'),
      ('😢', 'Emotional'),
      ('🤢', 'Nauseous'),
    ];
    final allSymptoms = [
      'Morning Sickness', 'Back Pain', 'Heartburn', 'Swollen Feet',
      'Headache', 'Fatigue', 'Mood Swings', 'Braxton Hicks',
      'Breathlessness', 'Frequent Urination', 'Insomnia', 'Cramps',
    ];
    String? selMood = _todayLog?.mood;
    final selSymptoms = List<String>.from(_todayLog?.symptoms ?? []);
    final weightCtrl = TextEditingController(
        text: _todayLog?.weightKg?.toStringAsFixed(1) ?? '');
    final notesCtrl =
        TextEditingController(text: _todayLog?.notes ?? '');

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) => DraggableScrollableSheet(
          initialChildSize: 0.88,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (_, sc) => Padding(
            padding: EdgeInsets.only(
              left: 22,
              right: 22,
              top: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: ListView(controller: sc, children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: FemoraColors.neutralLight,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Today\'s Log',
                          style: FemoraTextStyles.headlineMedium.copyWith(
                              color: FemoraColors.textPrimary,
                              fontWeight: FontWeight.w800)),
                      Text(
                          'Week ${_pregnancy!.currentWeek} · '
                          '${DateFormat('MMMM d').format(DateTime.now())}',
                          style: FemoraTextStyles.caption.copyWith(
                              color: FemoraColors.textSecondary)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                      color: FemoraColors.lavenderWhisper,
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(_pregnancy!.trimesterLabel,
                      style: FemoraTextStyles.caption.copyWith(
                          color: FemoraColors.primary,
                          fontWeight: FontWeight.w700)),
                ),
              ]),
              const SizedBox(height: 28),

              _sheetLabel('How are you feeling?'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: moods.map((m) {
                  final on = selMood == m.$2.toLowerCase();
                  return GestureDetector(
                    onTap: () => ss(
                        () => selMood = on ? null : m.$2.toLowerCase()),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                          color: on
                              ? FemoraColors.primary
                              : FemoraColors.lightBackgroundTint,
                          borderRadius: BorderRadius.circular(24)),
                      child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(m.$1,
                                style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 6),
                            Text(m.$2,
                                style: TextStyle(
                                  color: on
                                      ? Colors.white
                                      : FemoraColors.textSecondary,
                                  fontWeight: on
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                  fontSize: 13,
                                )),
                          ]),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              _sheetLabel('Symptoms today'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: allSymptoms.map((s) {
                  final on = selSymptoms.contains(s);
                  return GestureDetector(
                    onTap: () => ss(() =>
                        on ? selSymptoms.remove(s) : selSymptoms.add(s)),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                          color: on
                              ? FemoraColors.lavenderWhisper
                              : FemoraColors.lightBackgroundTint,
                          borderRadius: BorderRadius.circular(20),
                          border: on
                              ? Border.all(color: FemoraColors.primary)
                              : null),
                      child: Text(s,
                          style: TextStyle(
                            color: on
                                ? FemoraColors.primary
                                : FemoraColors.textSecondary,
                            fontWeight: on
                                ? FontWeight.w600
                                : FontWeight.w400,
                            fontSize: 13,
                          )),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              _sheetLabel('Weight (kg)'),
              const SizedBox(height: 10),
              TextField(
                controller: weightCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true),
                decoration: InputDecoration(
                  hintText: 'e.g. 62.5',
                  hintStyle:
                      TextStyle(color: FemoraColors.textSecondary),
                  filled: true,
                  fillColor: FemoraColors.lightBackgroundTint,
                  suffixText: 'kg',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 24),

              _sheetLabel('Notes'),
              const SizedBox(height: 10),
              TextField(
                controller: notesCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'How are you feeling today?',
                  hintStyle:
                      TextStyle(color: FemoraColors.textSecondary),
                  filled: true,
                  fillColor: FemoraColors.lightBackgroundTint,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 28),

              // Save button — SOLID primary, no gradient
              GestureDetector(
                onTap: () async {
                  Navigator.pop(ctx);
                  await _saveLog(
                    mood: selMood,
                    symptoms: selSymptoms,
                    weightKg: double.tryParse(weightCtrl.text),
                    notes: notesCtrl.text.trim().isEmpty
                        ? null
                        : notesCtrl.text.trim(),
                  );
                },
                child: Container(
                  height: 54,
                  decoration: BoxDecoration(
                    // SOLID primary — matches home screen
                    color: FemoraColors.primary,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: FemoraColors.primary.withOpacity(0.25),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      )
                    ],
                  ),
                  child: Center(
                    child: Text('Save Log',
                        style: FemoraTextStyles.bodyLarge.copyWith(
                            color: FemoraColors.textLight,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _sheetLabel(String t) => Text(t,
      style: FemoraTextStyles.titleLarge.copyWith(
          color: FemoraColors.textPrimary, fontWeight: FontWeight.w700));

  Future<void> _saveLog(
      {String? mood,
      List<String>? symptoms,
      double? weightKg,
      String? notes}) async {
    if (_pregnancy == null) return;
    try {
      final log = await _repo.addDailyLog(
        pregnancyId: _pregnancy!.id,
        logDate: DateTime.now(),
        weekNumber: _pregnancy!.currentWeek,
        mood: mood,
        symptoms: symptoms,
        weightKg: weightKg,
        notes: notes,
      );
      if (mounted) setState(() => _todayLog = log);
      _snack('Log saved ✓');
    } catch (e) {
      _snack('Error: $e', err: true);
    }
  }

  Future<void> _deletePregnancy() async {
    if (_pregnancy == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Remove Pregnancy?'),
        content: const Text(
          'This will permanently delete your pregnancy record, '
          'all daily logs, and kick sessions.\n\n'
          'You\'ll be taken back to the setup screen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style:
                TextButton.styleFrom(foregroundColor: FemoraColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (!mounted) return;
    final sure = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Are you sure?'),
        content: const Text(
            'This cannot be undone. All data will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Go back'),
          ),
          TextButton(
            style:
                TextButton.styleFrom(foregroundColor: FemoraColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, delete everything',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (sure != true) return;

    try {
      await _repo.deletePregnancy(pregnancyId: _pregnancy!.id);
      if (mounted) {
        setState(() {
          _pregnancy = null;
          _todayLog = null;
          _kickActive = false;
          _kickCount = 0;
        });
        _load();
      }
    } catch (e) {
      _snack('Error: $e', err: true);
    }
  }

  Future<void> _markBorn() async {
    if (_pregnancy == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Baby has arrived? 🎉'),
        content: const Text(
            'Your pregnancy will be archived. '
            'You can start a new journey anytime.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            style: TextButton.styleFrom(
                foregroundColor: FemoraColors.primary),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes!',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _repo.completePregnancy(
          pregnancyId: _pregnancy!.id, birthDate: DateTime.now());
      if (mounted) _load();
      _snack('Congratulations! 🎉');
    } catch (e) {
      _snack('Error: $e', err: true);
    }
  }

  void _snack(String msg, {bool err = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: err ? FemoraColors.error : FemoraColors.success,
      behavior: SnackBarBehavior.floating,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: FemoraColors.lightBackgroundTint,
        body: Center(
            child: CircularProgressIndicator(color: FemoraColors.primary)),
      );
    }
    if (_pregnancy == null) {
      return PregnancySetupScreen(onPregnancyCreated: _load);
    }

    final p = _pregnancy!;
    final week = p.currentWeek;
    final info = _weekData.getWeekInfo(week);

    return Scaffold(
      backgroundColor: FemoraColors.lightBackgroundTint,
      body: Stack(children: [
        CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Compact header ───────────────────────────────────────
            SliverToBoxAdapter(child: _buildCompactHeader(p)),

            // ── Content cards ────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                  FemoraSpacing.md, 0, FemoraSpacing.md, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: Column(children: [
                        _buildBabySizeCard(info, week),
                        const SizedBox(height: FemoraSpacing.md),
                        _buildDevelopmentCard(info),
                        const SizedBox(height: FemoraSpacing.md),
                        _buildMomTipsCard(info),
                        const SizedBox(height: FemoraSpacing.md),
                        if (week >= 18) ...[
                          _buildKickCard(),
                          const SizedBox(height: FemoraSpacing.md),
                        ],
                        _buildLogSummaryTile(p),
                        const SizedBox(height: FemoraSpacing.md),
                        _buildCountdownCard(p),
                        const SizedBox(height: FemoraSpacing.md),
                        _buildMarkBornButton(),
                      ]),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),

        // ── FAB — SOLID primary, no gradient ────────────────────────
        Positioned(
          bottom: FemoraSpacing.md,
          left: FemoraSpacing.md,
          right: FemoraSpacing.md,
          child: GestureDetector(
            onTap: _openLogSheet,
            child: Container(
              height: 54,
              decoration: BoxDecoration(
                // SOLID primary — matches home screen exactly
                color: FemoraColors.primary,
                borderRadius:
                    BorderRadius.circular(FemoraBorderRadius.medium),
                boxShadow: [
                  BoxShadow(
                    color: FemoraColors.primary.withOpacity(0.32),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  )
                ],
              ),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _todayLog != null
                          ? Icons.check_circle_rounded
                          : Icons.add_circle_outline_rounded,
                      color: FemoraColors.textLight,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _todayLog != null
                          ? 'Update Today\'s Log'
                          : 'Log Today',
                      style: FemoraTextStyles.bodyLarge.copyWith(
                          color: FemoraColors.textLight,
                          fontWeight: FontWeight.w700),
                    ),
                  ]),
            ),
          ),
        ),
      ]),
    );
  }

  // ── Compact header — replaces the massive purple gradient block ───────────
  //
  //   Before: Full-screen gradient fill with giant week number, stats row,
  //           progress bar — takes up 50%+ of screen height, feels heavy.
  //
  //   After:  White card, SafeArea padding, illustration (64px circle) on
  //           the left, week/trimester/due-date text on the right, settings
  //           icon top-right, thin progress bar below. Scrolls away naturally.
  Widget _buildCompactHeader(PregnancyRecord p) {
    return Container(
      color: const Color(0xFFF8F5FF),
      child: SafeArea(
        bottom: false,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── Mom illustration — small circle ──────────────
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: FemoraColors.lavenderWhisper,
                    boxShadow: [
                      BoxShadow(
                        color: FemoraColors.primary.withOpacity(0.14),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      )
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/pregnancy/mom_pregnancy.png',
                      fit: BoxFit.cover,
                      colorBlendMode: BlendMode.screen,
                      color: FemoraColors.primaryLight.withOpacity(0.0),
                      errorBuilder: (_, _, _) => const Center(
                          child: Text('🤱',
                              style: TextStyle(fontSize: 26))),
                    ),
                  ),
                ),

                const SizedBox(width: 14),

                // ── Week + trimester + due date ───────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Trimester pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          color: FemoraColors.lavenderWhisper,
                          borderRadius: BorderRadius.circular(
                              FemoraBorderRadius.circular),
                        ),
                        child: Text(
                          p.trimesterLabel,
                          style: FemoraTextStyles.caption.copyWith(
                            color: FemoraColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Week number — bold but not massive
                      RichText(
                        text: TextSpan(children: [
                          TextSpan(
                            text: 'Week ',
                            style: FemoraTextStyles.bodyLarge.copyWith(
                              color: FemoraColors.textSecondary,
                            ),
                          ),
                          TextSpan(
                            text: '${p.currentWeek}',
                            style: FemoraTextStyles.headlineLarge
                                .copyWith(
                              color: FemoraColors.textPrimary,
                              fontWeight: FontWeight.w900,
                              height: 1.0,
                            ),
                          ),
                          TextSpan(
                            text: '  ·  ${p.weeksRemaining} left',
                            style: FemoraTextStyles.bodyMedium.copyWith(
                              color: FemoraColors.textSecondary,
                            ),
                          ),
                        ]),
                      ),

                      const SizedBox(height: 3),
                      Text(
                        'Due ${DateFormat('MMM d, yyyy').format(p.dueDate)}',
                        style: FemoraTextStyles.caption.copyWith(
                            color: FemoraColors.textSecondary),
                      ),
                    ],
                  ),
                ),

                // ── Settings icon ─────────────────────────────────
                GestureDetector(
                  onTap: _showManageSheet,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: FemoraColors.lightBackgroundTint,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.settings_rounded,
                        color: FemoraColors.primary, size: 18),
                  ),
                ),
              ],
            ),
          ),

          // ── Thin progress bar below the row ──────────────────────
          Padding(
            padding:
                const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Row(children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: p.progressPercent,
                    backgroundColor: FemoraColors.lavenderWhisper,
                    valueColor: const AlwaysStoppedAnimation(
                        FemoraColors.primary),
                    minHeight: 5,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${(p.progressPercent * 100).toStringAsFixed(0)}%',
                style: FemoraTextStyles.caption.copyWith(
                  color: FemoraColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ]),
          ),

          // Bottom separator line
          Container(height: 1, color: FemoraColors.lavenderWhisper),
        ]),
      ),
    );
  }

  // ── Baby size card ────────────────────────────────────────────────────────

  Widget _buildBabySizeCard(PregnancyWeekInfo info, int week) {
    String babyAsset;
    if (week <= 12) {
      babyAsset = 'assets/images/pregnancy/baby_early.png';
    } else if (week <= 26) {
      babyAsset = 'assets/images/pregnancy/baby_mid.png';
    } else {
      babyAsset = 'assets/images/pregnancy/baby_late.png';
    }

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader('Your Baby This Week', Icons.child_care_rounded),
          const SizedBox(height: FemoraSpacing.md),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildBabyCircle(babyAsset, info.fruitEmoji),
            const SizedBox(width: FemoraSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(info.sizeCaption,
                      style: FemoraTextStyles.bodyMedium.copyWith(
                          color: FemoraColors.textSecondary,
                          height: 1.4)),
                  const SizedBox(height: 4),
                  Text(info.fruitName,
                      style: FemoraTextStyles.headlineMedium.copyWith(
                          color: FemoraColors.primary,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(info.weekHighlight,
                      style: FemoraTextStyles.caption.copyWith(
                          color: FemoraColors.textSecondary,
                          fontStyle: FontStyle.italic,
                          height: 1.4)),
                ],
              ),
            ),
          ]),
          const SizedBox(height: FemoraSpacing.md),
          Row(children: [
            Expanded(child: _measureChip(
                '📏', 'Length', '${info.lengthCm.toStringAsFixed(1)} cm')),
            const SizedBox(width: FemoraSpacing.sm),
            Expanded(child: _measureChip(
                '⚖️', 'Weight',
                info.weightG >= 1000
                    ? '${(info.weightG / 1000).toStringAsFixed(2)} kg'
                    : '${info.weightG.toStringAsFixed(0)} g')),
          ]),
        ],
      ),
    );
  }

  Widget _buildBabyCircle(String assetPath, String fallbackEmoji) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: FemoraColors.lavenderWhisper,
        border: Border.all(color: FemoraColors.softLilac, width: 2),
        boxShadow: [
          BoxShadow(
            color: FemoraColors.primary.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          assetPath,
          fit: BoxFit.cover,
          color: FemoraColors.primaryLight.withOpacity(0.0),
          colorBlendMode: BlendMode.screen,
          errorBuilder: (_, _, _) => Center(
              child: Text(fallbackEmoji,
                  style: const TextStyle(fontSize: 42))),
        ),
      ),
    );
  }

  Widget _measureChip(String emoji, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(FemoraSpacing.md),
      decoration: BoxDecoration(
        color: FemoraColors.lightBackgroundTint,
        borderRadius:
            BorderRadius.circular(FemoraBorderRadius.medium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 6),
          Text(value,
              style: FemoraTextStyles.titleLarge.copyWith(
                  color: FemoraColors.primary,
                  fontWeight: FontWeight.w800)),
          Text(label,
              style: FemoraTextStyles.caption
                  .copyWith(color: FemoraColors.textSecondary)),
        ],
      ),
    );
  }

  // ── Development card ──────────────────────────────────────────────────────

  Widget _buildDevelopmentCard(PregnancyWeekInfo info) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader('Baby\'s Development', Icons.science_rounded),
          const SizedBox(height: FemoraSpacing.md),
          ...info.babyMilestones.asMap().entries
              .map((e) => _milestoneRow(e.value, e.key + 1)),
        ],
      ),
    );
  }

  Widget _milestoneRow(String text, int n) {
    return Padding(
      padding: const EdgeInsets.only(bottom: FemoraSpacing.sm),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
              color: FemoraColors.lavenderWhisper,
              shape: BoxShape.circle),
          child: Center(
              child: Text('$n',
                  style: FemoraTextStyles.caption.copyWith(
                      color: FemoraColors.primary,
                      fontWeight: FontWeight.w800))),
        ),
        const SizedBox(width: FemoraSpacing.sm),
        Expanded(
            child: Text(text,
                style: FemoraTextStyles.bodyMedium.copyWith(
                    color: FemoraColors.textPrimary, height: 1.5))),
      ]),
    );
  }

  // ── Mom tips card ─────────────────────────────────────────────────────────

  Widget _buildMomTipsCard(PregnancyWeekInfo info) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader('Tips for You', Icons.spa_rounded),
          const SizedBox(height: FemoraSpacing.md),
          ...info.momTips.map((t) => _tipRow(t)),
        ],
      ),
    );
  }

  Widget _tipRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: FemoraSpacing.sm),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(top: 7),
          decoration: const BoxDecoration(
              color: FemoraColors.primary, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
            child: Text(text,
                style: FemoraTextStyles.bodyMedium.copyWith(
                    color: FemoraColors.textPrimary, height: 1.5))),
      ]),
    );
  }

  // ── Kick counter card ─────────────────────────────────────────────────────

  Widget _buildKickCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader('Kick Counter', Icons.touch_app_rounded),
          const SizedBox(height: 4),
          Text('Aim for 10 kicks in 2 hours',
              style: FemoraTextStyles.caption
                  .copyWith(color: FemoraColors.textSecondary)),
          const SizedBox(height: FemoraSpacing.md),
          if (!_kickActive) ...[
            GestureDetector(
              onTap: _startKick,
              child: Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                    color: FemoraColors.lightBackgroundTint,
                    borderRadius: BorderRadius.circular(
                        FemoraBorderRadius.medium),
                    border:
                        Border.all(color: FemoraColors.softLilac)),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.play_circle_outline_rounded,
                          color: FemoraColors.primary, size: 22),
                      const SizedBox(width: 8),
                      Text('Start Counting',
                          style: FemoraTextStyles.bodyLarge.copyWith(
                              color: FemoraColors.primary,
                              fontWeight: FontWeight.w600)),
                    ]),
              ),
            ),
          ] else ...[
            Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: _tapKick,
                  child: Container(
                    height: 84,
                    decoration: BoxDecoration(
                      // SOLID primary on kick tap button
                      color: FemoraColors.primary,
                      borderRadius: BorderRadius.circular(
                          FemoraBorderRadius.medium),
                      boxShadow: [
                        BoxShadow(
                          color: FemoraColors.primary.withOpacity(0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('$_kickCount',
                            style: const TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w900,
                                color: FemoraColors.textLight)),
                        Text('Tap to count',
                            style: FemoraTextStyles.caption.copyWith(
                                color: FemoraColors.textLight
                                    .withOpacity(0.7))),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: FemoraSpacing.sm),
              GestureDetector(
                onTap: _stopKick,
                child: Container(
                  width: 60,
                  height: 84,
                  decoration: BoxDecoration(
                    color: FemoraColors.error.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(
                        FemoraBorderRadius.medium),
                    border: Border.all(
                        color: FemoraColors.error.withOpacity(0.3)),
                  ),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.stop_rounded,
                            color: FemoraColors.error, size: 24),
                        Text('Stop',
                            style: FemoraTextStyles.caption.copyWith(
                                color: FemoraColors.error)),
                      ]),
                ),
              ),
            ]),
            if (_kickCount >= 10) ...[
              const SizedBox(height: FemoraSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                    color: FemoraColors.success.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(
                        FemoraBorderRadius.small)),
                child: Row(children: [
                  const Icon(Icons.check_circle_rounded,
                      color: FemoraColors.success, size: 18),
                  const SizedBox(width: 8),
                  Text('10 kicks reached — baby is active! 💜',
                      style: FemoraTextStyles.caption.copyWith(
                          color: FemoraColors.success,
                          fontWeight: FontWeight.w600)),
                ]),
              ),
            ],
          ],
        ],
      ),
    );
  }

  // ── Log summary tile ──────────────────────────────────────────────────────

  Widget _buildLogSummaryTile(PregnancyRecord p) {
    final logged = _todayLog != null;
    return GestureDetector(
      onTap: _openLogSheet,
      child: Container(
        padding: const EdgeInsets.all(FemoraSpacing.md),
        decoration: BoxDecoration(
          color: logged ? FemoraColors.lavenderWhisper : Colors.white,
          borderRadius:
              BorderRadius.circular(FemoraBorderRadius.medium),
          border: Border.all(
              color: logged
                  ? FemoraColors.softLilac
                  : FemoraColors.neutralLight,
              width: 1.5),
          boxShadow: [
            BoxShadow(
              color: FemoraColors.primary.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: logged
                  ? FemoraColors.primary.withOpacity(0.12)
                  : FemoraColors.lightBackgroundTint,
              borderRadius:
                  BorderRadius.circular(FemoraBorderRadius.small),
            ),
            child: Icon(
              logged ? Icons.check_rounded : Icons.edit_note_rounded,
              color: logged
                  ? FemoraColors.primary
                  : FemoraColors.textSecondary,
              size: 22,
            ),
          ),
          const SizedBox(width: FemoraSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    logged
                        ? 'Today\'s log is complete'
                        : 'How are you today?',
                    style: FemoraTextStyles.bodyLarge.copyWith(
                        color: FemoraColors.textPrimary,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                    logged
                        ? _logSummaryText()
                        : 'Mood · Symptoms · Weight · Notes',
                    style: FemoraTextStyles.caption.copyWith(
                        color: logged
                            ? FemoraColors.primary
                            : FemoraColors.textSecondary)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              color: FemoraColors.textSecondary),
        ]),
      ),
    );
  }

  String _logSummaryText() {
    final log = _todayLog;
    if (log == null) return '';
    final parts = <String>[];
    if (log.mood != null) parts.add('${_moodEmoji(log.mood!)} ${_cap(log.mood!)}');
    if (log.symptoms.isNotEmpty) {
      parts.add('${log.symptoms.length} symptom${log.symptoms.length > 1 ? "s" : ""}');
    }
    if (log.weightKg != null) {
      parts.add('${log.weightKg!.toStringAsFixed(1)} kg');
    }
    return parts.isEmpty ? 'Logged today' : parts.join(' · ');
  }

  String _moodEmoji(String m) => {
        'happy': '😊',
        'tired': '😴',
        'anxious': '😰',
        'excited': '🥰',
        'emotional': '😢',
        'nauseous': '🤢',
      }[m] ??
      '😊';

  String _cap(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  // ── Countdown card — solid primary, no gradient ───────────────────────────

  Widget _buildCountdownCard(PregnancyRecord p) {
    String? nextMsg;
    if (p.trimester == 1) {
      final w = 14 - p.currentWeek;
      if (w > 0) nextMsg = '2nd trimester in $w weeks';
    } else if (p.trimester == 2) {
      final w = 28 - p.currentWeek;
      if (w > 0) nextMsg = '3rd trimester in $w weeks';
    }

    return Container(
      padding: const EdgeInsets.all(FemoraSpacing.lg),
      decoration: BoxDecoration(
        // SOLID primary — same as home screen buttons
        color: FemoraColors.primary,
        borderRadius:
            BorderRadius.circular(FemoraBorderRadius.large),
        boxShadow: [
          BoxShadow(
            color: FemoraColors.primary.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.favorite_rounded,
                color: Colors.white70, size: 14),
            const SizedBox(width: 6),
            Text('Due Date',
                style: FemoraTextStyles.caption.copyWith(
                    color: Colors.white60,
                    fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 6),
          Text(
            DateFormat('MMMM d, yyyy').format(p.dueDate),
            style: FemoraTextStyles.headlineLarge.copyWith(
                color: FemoraColors.textLight,
                fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: FemoraSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(vertical: FemoraSpacing.sm),
            decoration: BoxDecoration(
              color: FemoraColors.textLight.withOpacity(0.1),
              borderRadius:
                  BorderRadius.circular(FemoraBorderRadius.small),
            ),
            child: Row(children: [
              Expanded(
                  child: _countStat('${p.daysRemaining}', 'Days Left')),
              Container(
                  width: 1,
                  height: 36,
                  color: Colors.white.withOpacity(0.2)),
              Expanded(
                  child: _countStat('${p.weeksRemaining}', 'Weeks Left')),
              Container(
                  width: 1,
                  height: 36,
                  color: Colors.white.withOpacity(0.2)),
              Expanded(
                  child: _countStat(
                      '${(p.progressPercent * 100).toStringAsFixed(0)}%',
                      'Complete')),
            ]),
          ),
          if (nextMsg != null) ...[
            const SizedBox(height: FemoraSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: FemoraColors.textLight.withOpacity(0.1),
                borderRadius:
                    BorderRadius.circular(FemoraBorderRadius.small),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.arrow_forward_rounded,
                    color: Colors.white, size: 14),
                const SizedBox(width: 6),
                Text(nextMsg,
                    style: FemoraTextStyles.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600)),
              ]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _countStat(String val, String label) {
    return Column(children: [
      Text(val,
          textAlign: TextAlign.center,
          style: FemoraTextStyles.titleLarge.copyWith(
              color: FemoraColors.textLight, fontWeight: FontWeight.w800)),
      Text(label,
          textAlign: TextAlign.center,
          style: FemoraTextStyles.caption.copyWith(color: Colors.white60)),
    ]);
  }

  // ── Mark born — outline button (light, not competing with FAB) ────────────

  Widget _buildMarkBornButton() {
    return GestureDetector(
      onTap: _markBorn,
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          // Light outline — doesn't compete with the solid primary FAB
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(FemoraBorderRadius.medium),
          border: Border.all(color: FemoraColors.softLilac, width: 1.5),
        ),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              Text(
                'My baby has arrived!',
                style: FemoraTextStyles.bodyLarge.copyWith(
                    color: FemoraColors.primary,
                    fontWeight: FontWeight.w700),
              ),
            ]),
      ),
    );
  }

  // ── Shared card helpers ───────────────────────────────────────────────────

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(FemoraSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(FemoraBorderRadius.medium),
        boxShadow: [
          BoxShadow(
            color: FemoraColors.primary.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: child,
    );
  }

  Widget _cardHeader(String title, IconData icon) {
    return Row(children: [
      Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
            color: FemoraColors.lavenderWhisper,
            borderRadius:
                BorderRadius.circular(FemoraBorderRadius.small)),
        child: Icon(icon, color: FemoraColors.primary, size: 18),
      ),
      const SizedBox(width: FemoraSpacing.sm),
      Text(title,
          style: FemoraTextStyles.titleLarge.copyWith(
              color: FemoraColors.textPrimary,
              fontWeight: FontWeight.w700)),
    ]);
  }
}