// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
import '../../models/cycle_prediction.dart';
import '../../models/period_cycle.dart';
import '../../models/period_daily_log.dart';
import '../../services/period_repository.dart';
import '../../services/prediction_engine.dart';
import '../../services/phase_calculator.dart';
import '../../services/pdf_report_service.dart';
import 'period_history_screen.dart';

// ── Safe colour constants ────────────────────────────────────────────────────
// Only colours confirmed present in existing source files are used.
// FemoraColors.primary, primaryLight, textPrimary, textSecondary, textLight,
// error, success, lavenderWhisper, lightBackgroundTint  ← all confirmed safe.
const _kSpotting = Color(0xFFFF9500);   // iOS-style amber — used for spotting
const _kHandleBar = Color(0xFFDDDDDD); // bottom-sheet drag handle

/// Period Tab — complete rewrite.
///
/// What changed from the old version:
///
/// 1. PERFORMANCE — Week logs are loaded in ONE batch query.
///    The old code had a FutureBuilder inside each of the 7 day cells, causing
///    7 separate database calls every time the scroller rendered.
///
/// 2. PHASE CIRCLE — Shows a proper "Start Tracking" empty state when no
///    cycle data exists. Never shows "Unknown" again.
///
/// 3. AUTO-FILL — Logging flow on a date auto-creates logs for the next 4 days
///    at progressively lighter flow (like Apple Health). Days that already have
///    a log are never overwritten.
///
/// 4. PERIOD END INPUT — "Mark period ended" button appears while an active
///    (open) cycle exists. Tapping it closes the cycle, calculates bleeding
///    days, and updates predictions immediately.
///
/// 5. DATA CARDS — Each card now shows the actual logged state for the
///    selected date, not just a label and a plus icon.
class PeriodTab extends StatefulWidget {
  const PeriodTab({super.key});

  @override
  State<PeriodTab> createState() => _PeriodTabState();
}

class _PeriodTabState extends State<PeriodTab> {
  // ── Services ────────────────────────────────────────────────────────────
  final _repo = PeriodRepository();
  final _predictionEngine = PredictionEngine();
  final _phaseCalc = PhaseCalculator();
  final _pdfService = PDFReportService();

  // ── State ─────────────────────────────────────────────────────────────
  DateTime _selectedDate = DateTime.now();
  PhaseInfo? _currentPhase;
  PeriodDailyLog? _selectedDayLog;
  CyclePrediction? _prediction;
  PeriodCycle? _activeCycle;

  /// Batch-loaded logs for the visible week — key is 'yyyy-MM-dd'
  final Map<String, PeriodDailyLog> _weekLogs = {};

  bool _isLoading = true;
  bool _isSaving = false;

  // ── Lifecycle ────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  // ── Data helpers ─────────────────────────────────────────────────────

  String _key(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  DateTime _weekStart(DateTime d) =>
      d.subtract(Duration(days: d.weekday - 1));

  bool _isToday(DateTime d) {
    final n = DateTime.now();
    return d.year == n.year && d.month == n.month && d.day == n.day;
  }

  bool _same(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _suffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1: return 'st';
      case 2: return 'nd';
      case 3: return 'rd';
      default: return 'th';
    }
  }

  // ── Load ──────────────────────────────────────────────────────────────

  Future<void> _loadAll() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      // All three run in parallel
      await Future.wait([
        _loadWeekBatch(_selectedDate),
        _loadPhase(),
        _loadActiveCycle(),
      ]);
      await _loadPrediction();
    } catch (e) {
      _snack('Error loading data: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// ONE query for the whole visible week — replaces 7 FutureBuilders
  Future<void> _loadWeekBatch(DateTime ref) async {
    final start = _weekStart(ref);
    final end = start.add(const Duration(days: 6));
    final logs = await _repo.fetchDailyLogsForDateRange(
        startDate: start, endDate: end);
    _weekLogs.clear();
    for (final l in logs) {
      _weekLogs[_key(l.logDate)] = l;
    }
    _selectedDayLog = _weekLogs[_key(_selectedDate)];
  }

  Future<void> _loadPhase() async {
    _currentPhase = await _phaseCalc.calculatePhaseForDate(_selectedDate);
  }

  Future<void> _loadActiveCycle() async {
    _activeCycle = await _repo.getCurrentCycle();
  }

  Future<void> _loadPrediction() async {
    _prediction = await _predictionEngine.generatePrediction();
  }

  // ── Date selection ───────────────────────────────────────────────────

  Future<void> _selectDate(DateTime date) async {
    if (_isSaving) return;
    setState(() {
      _selectedDate = date;
      _selectedDayLog = _weekLogs[_key(date)];
    });
    try {
      final phase = await _phaseCalc.calculatePhaseForDate(date);
      if (mounted) setState(() => _currentPhase = phase);
    } catch (_) {}
 
    // ── Re-open check ──────────────────────────────────────────────────────
    // If there's no active cycle AND the user tapped a date within 5 days
    // after the most recent completed cycle's end_date, offer to re-open it.
    if (_activeCycle == null) {
      await _checkReopenCycle(date);
    }
  }

  // ── Core action: log flow + auto-fill next 4 days ────────────────────

  /// Logs flow for [_selectedDate], then silently auto-fills the next
  /// 4 days at progressively lighter flow — exactly like Apple Health.
  /// Days that already have a log entry are NEVER overwritten.
  Future<void> _logFlowAndAutoFill(String flow) async {
    setState(() => _isSaving = true);
    try {
      // Day 0 — the date the user explicitly selected
      await _upsertLog(_selectedDate, flow: flow, autoFill: false);

      // Days 1-4 — auto-fill only if no existing log
      final cascade = [flow, flow, _lighter(flow), _lighter(_lighter(flow))];
      for (int i = 1; i <= 4; i++) {
        final target = _selectedDate.add(Duration(days: i));
        final existing = _weekLogs[_key(target)] ??
            await _repo.getDailyLogForDate(target);
        if (existing == null) {
          await _upsertLog(target, flow: cascade[i - 1], autoFill: true);
        }
      }

      await _loadAll();
      _snack('Period logged ✓  Next 4 days auto-marked');
    } catch (e) {
      _snack('Error saving: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// Create or update a daily log entry.
  /// When [autoFill] is true the call returns early if the log already exists.
  Future<void> _upsertLog(
    DateTime date, {
    String? flow,
    List<String>? symptoms,
    bool? spotting,
    bool autoFill = false,
  }) async {
    final existing = await _repo.getDailyLogForDate(date);
    if (existing == null) {
      await _repo.addDailyLog(
        logDate: date,
        flowLevel: flow,
        symptoms: symptoms,
        hasSpotting: spotting ?? false,
      );
    } else {
      if (autoFill) return; // Never overwrite existing user data with auto-fill
      await _repo.updateDailyLog(
        logId: existing.id,
        flowLevel: flow ?? existing.flowLevel,
        symptoms: symptoms ?? existing.symptoms,
        hasSpotting: spotting ?? existing.hasSpotting,
      );
    }
  }

  String _lighter(String f) {
    if (f == 'high') return 'medium';
    return 'low';
  }

  // ── Period end ───────────────────────────────────────────────────────

  /// User confirms their period ended on [_selectedDate].
  ///
  /// This closes the active cycle, calculates actual bleeding days from
  /// the logged data, and saves both. On the next _loadAll() call the
  /// prediction engine will use this confirmed data to improve accuracy.
  Future<void> _markPeriodEnded() async {
    if (_activeCycle == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark period ended?'),
        content: Text(
          'This will record your period as ending on '
          '${DateFormat('MMMM d').format(_selectedDate)}.\n\n'
          'Your predictions for next month will be updated.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: FemoraColors.primary),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _isSaving = true);
    try {
      // Count logged period days to record accurate bleeding_days
      final logs = await _repo.fetchDailyLogsForCycle(_activeCycle!.id);
      final bleedingDays = logs.where((l) => l.flowLevel != null).length;

      await _repo.updateCycleEnd(
          cycleId: _activeCycle!.id, endDate: _selectedDate);
      await _repo.updateBleedingDays(
          cycleId: _activeCycle!.id,
          bleedingDays: bleedingDays > 0 ? bleedingDays : 1);

      await _loadAll();
      _snack('Period end saved ✓  Predictions updated');
    } catch (e) {
      _snack('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
  // ── 3a. Re-open cycle detection ───────────────────────────────────────────
 
  /// Called after date selection when no active cycle exists.
  /// If [tappedDate] is within 5 days of the last completed cycle's end,
  /// offer the user a chance to re-open that cycle.
  Future<void> _checkReopenCycle(DateTime tappedDate) async {
    try {
      final lastCycle = await _repo.getLastCompletedCycle();
      if (lastCycle == null || lastCycle.endDate == null) return;
 
      final gap = tappedDate.difference(lastCycle.endDate!).inDays;
      if (gap < 0 || gap > 5) return; // too far away — treat as new cycle
 
      if (!mounted) return;
 
      final reopen = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: const Text('Did your period continue? 🩸'),
          content: Text(
            'Your period was marked as ended on '
            '${_fmt(lastCycle.endDate!)}.\n\n'
            'Did it actually continue past that date?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('No, new cycle',
                  style: TextStyle(color: FemoraColors.textSecondary)),
            ),
            TextButton(
              style: TextButton.styleFrom(
                  foregroundColor: FemoraColors.primary),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Yes, re-open it',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
 
      if (reopen != true || !mounted) return;
 
      setState(() => _isSaving = true);
      await _repo.reopenCycle(lastCycle.id);
      await _loadAll();
      _snack('Period re-opened ✓');
    } catch (e) {
      _snack('Could not re-open: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
 
  // ── 3b. Management bottom sheet ───────────────────────────────────────────
 
  /// The main entry point for the settings icon.
  /// Shows different options depending on whether an active cycle exists.
  void _showManagementSheet() {
    if (_activeCycle == null) {
      _snack('No active period to manage');
      return;
    }
 
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: const Color(0xFFDDDDDD),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
 
            Text('Manage Period',
                style: FemoraTextStyles.titleLarge.copyWith(
                    color: FemoraColors.textPrimary,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('Fix any mistakes with your current period',
                style: FemoraTextStyles.bodySmall
                    .copyWith(color: FemoraColors.textSecondary)),
            const SizedBox(height: 20),
 
            // Option A — Fix start date
            _manageTile(
              icon: Icons.edit_calendar_rounded,
              iconColor: FemoraColors.primary,
              title: 'Fix wrong start date',
              subtitle:
                  'Started on ${_fmt(_activeCycle!.startDate)}? Correct it.',
              onTap: () {
                Navigator.pop(ctx);
                _editStartDate();
              },
            ),
 
            const Divider(height: 1),
 
            // Option B — Fix a flow entry
            _manageTile(
              icon: Icons.water_drop_outlined,
              iconColor: const Color(0xFF6B9BF2),
              title: 'Fix a flow entry',
              subtitle: 'Edit the flow level for a specific day',
              onTap: () {
                Navigator.pop(ctx);
                _editFlowEntry();
              },
            ),
 
            const Divider(height: 1),
 
            // Option C — Delete (destructive, red)
            _manageTile(
              icon: Icons.delete_outline_rounded,
              iconColor: FemoraColors.error,
              title: 'Delete this period',
              subtitle: 'Added by mistake? Remove everything',
              titleColor: FemoraColors.error,
              onTap: () {
                Navigator.pop(ctx);
                _deleteActiveCycle();
              },
            ),
          ],
        ),
      ),
    );
  }
 
  /// Builds a single row inside the management bottom sheet.
  Widget _manageTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? titleColor,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 6),
      leading: Container(
        width: 42, height: 42,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title,
          style: FemoraTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: titleColor ?? FemoraColors.textPrimary)),
      subtitle: Text(subtitle,
          style: FemoraTextStyles.bodySmall
              .copyWith(color: FemoraColors.textSecondary)),
      onTap: onTap,
    );
  }
 
  // ── 3c. Edit start date ────────────────────────────────────────────────────
 
  Future<void> _editStartDate() async {
    if (_activeCycle == null) return;
 
    final picked = await showDatePicker(
      context: context,
      helpText: 'When did your period actually start?',
      initialDate: _activeCycle!.startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 60)),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
              primary: FemoraColors.primary),
        ),
        child: child!,
      ),
    );
 
    if (picked == null || !mounted) return;
 
    // Prevent picking the exact same date (no-op)
    if (picked.isAtSameMomentAs(_activeCycle!.startDate)) {
      _snack('That\'s already the start date');
      return;
    }
 
    setState(() => _isSaving = true);
    try {
      await _repo.updateCycleStartDate(
        cycleId: _activeCycle!.id,
        newStartDate: picked,
      );
      await _loadAll();
      _snack('Start date updated to ${_fmt(picked)} ✓');
    } catch (e) {
      _snack('Could not update: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
 
  // ── 3d. Edit flow for a specific logged day ────────────────────────────────
 
  Future<void> _editFlowEntry() async {
    if (_activeCycle == null) return;
 
    // Fetch all logged days for this cycle
    List<PeriodDailyLog> logs;
    try {
      logs = await _repo.fetchDailyLogsForCycle(_activeCycle!.id);
    } catch (e) {
      _snack('Could not load entries: $e', isError: true);
      return;
    }
 
    // Filter to only days that actually have a flow value
    final flowLogs =
        logs.where((l) => l.flowLevel != null && l.flowLevel!.isNotEmpty).toList();
 
    if (flowLogs.isEmpty) {
      _snack('No flow entries to edit yet');
      return;
    }
 
    if (!mounted) return;
 
    // Show a bottom sheet with the list of logged days
    final chosen = await showModalBottomSheet<PeriodDailyLog>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: const Color(0xFFDDDDDD),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text('Which day to fix?',
                style: FemoraTextStyles.titleLarge.copyWith(
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('Tap a day to change its flow level',
                style: FemoraTextStyles.bodySmall
                    .copyWith(color: FemoraColors.textSecondary)),
            const SizedBox(height: 16),
            ...flowLogs.map((log) => ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 2),
              leading: Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: FemoraColors.lavenderWhisper,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.water_drop_rounded,
                    color: FemoraColors.primary, size: 20),
              ),
              title: Text(_fmt(log.logDate),
                  style: FemoraTextStyles.bodyMedium
                      .copyWith(fontWeight: FontWeight.w600)),
              subtitle: Text(
                  'Current: ${log.flowLevel ?? "—"}',
                  style: FemoraTextStyles.bodySmall
                      .copyWith(color: FemoraColors.textSecondary)),
              onTap: () => Navigator.pop(ctx, log),
            )),
          ],
        ),
      ),
    );
 
    if (chosen == null || !mounted) return;
 
    // Now show flow picker for the chosen day
    await _showFlowEditPicker(chosen);
  }
 
  /// Shows a compact bottom sheet to pick a new flow level for [log].
  Future<void> _showFlowEditPicker(PeriodDailyLog log) async {
    const flows = ['Spotting', 'Light', 'Medium', 'High'];
 
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: const Color(0xFFDDDDDD),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text('New flow for ${_fmt(log.logDate)}',
                style: FemoraTextStyles.titleLarge
                    .copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: flows
                  .map((f) => GestureDetector(
                    onTap: () => Navigator.pop(ctx, f),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: log.flowLevel == f
                            ? FemoraColors.primary
                            : FemoraColors.lavenderWhisper,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(f,
                          style: FemoraTextStyles.bodyMedium.copyWith(
                            color: log.flowLevel == f
                                ? FemoraColors.textLight
                                : FemoraColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          )),
                    ),
                  ))
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
 
    if (picked == null || picked == log.flowLevel || !mounted) return;
 
    setState(() => _isSaving = true);
    try {
      await _repo.updateDailyLog(logId: log.id, flowLevel: picked);
      await _loadAll();
      _snack('Flow updated to $picked ✓');
    } catch (e) {
      _snack('Could not update: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
 
  // ── 3e. Delete active cycle (double confirmation) ─────────────────────────
 
  Future<void> _deleteActiveCycle() async {
    if (_activeCycle == null) return;
 
    // Step 1 — First warning
    final step1 = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Icon(Icons.warning_rounded, color: FemoraColors.error, size: 22),
          const SizedBox(width: 8),
          const Text('Delete this period?'),
        ]),
        content: const Text(
          'This will permanently remove this period entry '
          'and all its daily logs.\n\n'
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: TextStyle(color: FemoraColors.textSecondary)),
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
 
    if (step1 != true || !mounted) return;
 
    // Step 2 — Final confirmation
    final step2 = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Are you absolutely sure?'),
        content: const Text(
          'All flow logs, symptom entries, and notes for '
          'this period will be lost forever.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Go Back'),
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
 
    if (step2 != true || !mounted) return;
 
    setState(() => _isSaving = true);
    try {
      await _repo.deleteCycle(_activeCycle!.id);
      if (mounted) {
        setState(() {
          _activeCycle = null;
          _selectedDayLog = null;
          _weekLogs.clear();
          _currentPhase = null;
          _prediction = null;
        });
        await _loadAll();
      }
      _snack('Period deleted');
    } catch (e) {
      _snack('Could not delete: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
 
  // ── 3f. Helper: format a date for display ────────────────────────────────
 
  /// Formats a DateTime to e.g. "Mar 10"
  String _fmt(DateTime d) =>
      '${_monthAbbr(d.month)} ${d.day}';
 
  String _monthAbbr(int m) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return months[m];
  }

  // ── Symptom / spotting updates ──────────────────────────────────────

  Future<void> _saveSymptoms(List<String> symptoms) async {
    setState(() => _isSaving = true);
    try {
      await _upsertLog(_selectedDate, symptoms: symptoms);
      await _loadAll();
    } catch (e) {
      _snack('Error saving symptoms: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _saveSpotting(bool value) async {
    setState(() => _isSaving = true);
    try {
      await _upsertLog(_selectedDate, spotting: value);
      await _loadAll();
    } catch (e) {
      _snack('Error saving spotting: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Feedback ─────────────────────────────────────────────────────────

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor:
          isError ? FemoraColors.error : FemoraColors.success,
      behavior: SnackBarBehavior.floating,
      duration: Duration(seconds: isError ? 4 : 2),
    ));
  }

  // ── BUILD ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FemoraColors.lightBackgroundTint,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                  color: FemoraColors.primary))
          : SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          const SizedBox(height: 12),
                          _buildWeekScroller(),
                          const SizedBox(height: 16),
                          _buildDateLabel(),
                          const SizedBox(height: 20),
                          _buildPhaseCircle(),
                          if (_activeCycle != null) ...[
                            const SizedBox(height: 16),
                            _buildMarkEndedButton(),
                          ],
                          const SizedBox(height: 28),
                          _buildYourData(),
                          const SizedBox(height: 28),
                          if (_prediction != null) _buildPredictionCard(),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Period Tracker',
                    style: FemoraTextStyles.headlineMedium.copyWith(
                        color: FemoraColors.textPrimary,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('Track your cycle',
                    style: FemoraTextStyles.bodyMedium
                        .copyWith(color: FemoraColors.textSecondary)),
              ],
            ),
          ),
          _headerBtn(Icons.tune_rounded, 'Manage period',
              _showManagementSheet),
          _headerBtn(Icons.calendar_month_rounded, 'Pick date', () async {
            final d = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate:
                  DateTime.now().subtract(const Duration(days: 365)),
              lastDate: DateTime.now(),
              builder: (ctx, child) => Theme(
                data: Theme.of(ctx).copyWith(
                  colorScheme: const ColorScheme.light(
                      primary: FemoraColors.primary),
                ),
                child: child!,
              ),
            );
            if (d != null) {
              await _loadWeekBatch(d);
              await _selectDate(d);
            }
          }),
          _headerBtn(Icons.history_rounded, 'History', () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const PeriodHistoryScreen()),
            ).then((_) => _loadAll());
          }),
          _headerBtn(Icons.file_download_rounded, 'Export PDF',
              _isSaving ? null : () async {
            try {
              await _pdfService.generateAndShare();
            } catch (e) {
              _snack('Export failed: $e', isError: true);
            }
          }),
        ],
      ),
    );
  }

  Widget _headerBtn(
      IconData icon, String tooltip, VoidCallback? onTap) {
    return IconButton(
      icon: Icon(icon),
      color: FemoraColors.primary,
      tooltip: tooltip,
      onPressed: onTap,
    );
  }

  // ── Week scroller ─────────────────────────────────────────────────────

  Widget _buildWeekScroller() {
    final start = _weekStart(_selectedDate);
    return SizedBox(
      height: 86,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 7,
        itemBuilder: (ctx, i) {
          final date = start.add(Duration(days: i));
          final isSel = _same(date, _selectedDate);
          final isToday = _isToday(date);
          final log = _weekLogs[_key(date)];
          final hasPeriod = log?.flowLevel != null;
          final hasSpot = log?.hasSpotting ?? false;
          final isPredicted = _isPredictedDay(date);
          return _buildDayCell(
            date: date,
            isSelected: isSel,
            isToday: isToday,
            hasPeriod: hasPeriod,
            hasSpotting: hasSpot,
            isPredicted: isPredicted,
          );
        },
      ),
    );
  }

  bool _isPredictedDay(DateTime d) {
    if (_prediction == null) return false;
    final start = _prediction!.nextPeriodDate;
    final end = start.add(const Duration(days: 5));
    return !d.isBefore(start) && d.isBefore(end);
  }

  Widget _buildDayCell({
    required DateTime date,
    required bool isSelected,
    required bool isToday,
    required bool hasPeriod,
    required bool hasSpotting,
    required bool isPredicted,
  }) {
    Color? dot;
    if (hasPeriod) { dot = FemoraColors.error; }
    else if (hasSpotting) { dot = _kSpotting; }
    else if (isPredicted) { dot = FemoraColors.error.withOpacity(0.35); }

    return GestureDetector(
      onTap: () => _selectDate(date),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 50,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? FemoraColors.primary
              : isToday
                  ? FemoraColors.primary.withOpacity(0.08)
                  : FemoraColors.lavenderWhisper.withOpacity(0.4),
          borderRadius: BorderRadius.circular(16),
          border: isToday && !isSelected
              ? Border.all(color: FemoraColors.primary, width: 1.5)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              DateFormat('E').format(date).substring(0, 1),
              style: FemoraTextStyles.caption.copyWith(
                color: isSelected
                    ? Colors.white70
                    : FemoraColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              '${date.day}',
              style: FemoraTextStyles.titleLarge.copyWith(
                color: isSelected
                    ? Colors.white
                    : FemoraColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            // Indicator dot
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: dot ??
                    (isSelected
                        ? Colors.white30
                        : Colors.transparent),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Date label ────────────────────────────────────────────────────────

  Widget _buildDateLabel() {
    final isToday = _isToday(_selectedDate);
    final label = isToday
        ? 'Today, ${DateFormat('MMMM d').format(_selectedDate)}'
        : DateFormat('EEEE, MMMM d').format(_selectedDate);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Text(label,
              style: FemoraTextStyles.bodyMedium.copyWith(
                  color: FemoraColors.textSecondary,
                  fontWeight: FontWeight.w600)),
          if (_selectedDayLog?.flowLevel != null) ...[
            const SizedBox(width: 8),
            _flowPill(_selectedDayLog!.flowLevel!),
          ],
        ],
      ),
    );
  }

  Widget _flowPill(String flow) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: FemoraColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '${_cap(flow)} flow',
        style: FemoraTextStyles.caption.copyWith(
            color: FemoraColors.error, fontWeight: FontWeight.w700),
      ),
    );
  }

  String _cap(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  // ── Phase circle ──────────────────────────────────────────────────────

  Widget _buildPhaseCircle() {
    final phase = _currentPhase;
    final hasAnyLog =
        _weekLogs.values.any((l) => l.flowLevel != null);

    // No data at all → invite the user to start
    if (phase == null && !hasAnyLog) {
      return _buildEmptyCircle();
    }

    final name = phase?.phaseName ?? 'Tracking';
    final day = phase?.dayOfCycle ?? 1;
    final desc = phase?.description ?? 'Log your period to get started';
    final color = _phaseColor(phase?.phase);

    return Column(
      children: [
        // Outer glow ring
        Container(
          width: 260,
          height: 260,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [
              color.withOpacity(0.18),
              color.withOpacity(0.06),
              Colors.transparent,
            ]),
          ),
          alignment: Alignment.center,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(
                    color: color.withOpacity(0.35),
                    blurRadius: 28,
                    spreadRadius: 4),
              ],
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(name,
                    style: FemoraTextStyles.headlineLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text('Day $day${_suffix(day)}',
                    style: FemoraTextStyles.titleLarge.copyWith(
                        color: Colors.white.withOpacity(0.85))),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(desc,
              textAlign: TextAlign.center,
              style: FemoraTextStyles.bodyMedium
                  .copyWith(color: FemoraColors.textSecondary)),
        ),
      ],
    );
  }

  /// Empty state — shown when the user has no data at all
  Widget _buildEmptyCircle() {
    return Column(
      children: [
        GestureDetector(
          onTap: _showFlowSheet,
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                FemoraColors.lavenderWhisper.withOpacity(0.7),
                FemoraColors.lavenderWhisper.withOpacity(0.2),
                Colors.transparent,
              ]),
            ),
            alignment: Alignment.center,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: FemoraColors.primary.withOpacity(0.12),
                border: Border.all(
                    color: FemoraColors.primary.withOpacity(0.3),
                    width: 2),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_circle_outline_rounded,
                      size: 42,
                      color: FemoraColors.primary.withOpacity(0.7)),
                  const SizedBox(height: 10),
                  Text('Start\nTracking',
                      textAlign: TextAlign.center,
                      style: FemoraTextStyles.headlineMedium.copyWith(
                          color: FemoraColors.primary,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text('Tap the circle or "Period" below to log today',
            textAlign: TextAlign.center,
            style: FemoraTextStyles.bodyMedium
                .copyWith(color: FemoraColors.textSecondary)),
      ],
    );
  }

  Color _phaseColor(CyclePhase? p) {
    switch (p) {
      case CyclePhase.menstrual:   return const Color(0xFFE05C6F);
      case CyclePhase.follicular:  return const Color(0xFF6B9BF2);
      case CyclePhase.ovulation:   return const Color(0xFF5BBFA3);
      case CyclePhase.luteal:      return FemoraColors.primary;
      default:                     return FemoraColors.primary;
    }
  }

  // ── Mark period ended ────────────────────────────────────────────────

  Widget _buildMarkEndedButton() {
    final label = _same(_selectedDate, DateTime.now())
        ? 'My period ended today'
        : 'Period ended on ${DateFormat('MMM d').format(_selectedDate)}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: OutlinedButton.icon(
        onPressed: _isSaving ? null : _markPeriodEnded,
        icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: FemoraColors.error,
          side: const BorderSide(color: FemoraColors.error),
          minimumSize: const Size(double.infinity, 46),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  // ── Your Data cards ───────────────────────────────────────────────────

  Widget _buildYourData() {
    final log = _selectedDayLog;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your Data',
              style: FemoraTextStyles.titleLarge.copyWith(
                  color: FemoraColors.textPrimary,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          _dataCard(
            title: 'Period',
            sub: log?.flowLevel != null
                ? '${_cap(log!.flowLevel!)} flow logged'
                : 'Tap to log flow',
            icon: Icons.water_drop_rounded,
            accent: FemoraColors.error,
            logged: log?.flowLevel != null,
            onTap: _showFlowSheet,
          ),
          const SizedBox(height: 10),
          _dataCard(
            title: 'Symptoms',
            sub: (log?.symptoms.isNotEmpty ?? false)
                ? log!.symptoms.take(2).join(', ') +
                    (log.symptoms.length > 2
                        ? ' +${log.symptoms.length - 2}'
                        : '')
                : 'Tap to add symptoms',
            icon: Icons.healing_rounded,
            accent: FemoraColors.primary,
            logged: log?.symptoms.isNotEmpty ?? false,
            onTap: _showSymptomsSheet,
          ),
          const SizedBox(height: 10),
          _dataCard(
            title: 'Spotting',
            sub: (log?.hasSpotting ?? false)
                ? 'Spotting logged'
                : 'Tap to log spotting',
            icon: Icons.circle_rounded,
            accent: _kSpotting,
            logged: log?.hasSpotting ?? false,
            onTap: _showSpottingSheet,
          ),
        ],
      ),
    );
  }

  Widget _dataCard({
    required String title,
    required String sub,
    required IconData icon,
    required Color accent,
    required bool logged,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: _isSaving ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: logged
              ? Border.all(color: accent.withOpacity(0.4), width: 1.5)
              : null,
          boxShadow: [
            BoxShadow(
                color: FemoraColors.primary.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: accent, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: FemoraTextStyles.bodyLarge.copyWith(
                          color: FemoraColors.textPrimary,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(sub,
                      style: FemoraTextStyles.caption.copyWith(
                          color: logged
                              ? accent
                              : FemoraColors.textSecondary)),
                ],
              ),
            ),
            Icon(
              logged
                  ? Icons.check_circle_rounded
                  : Icons.add_circle_outline_rounded,
              color: logged ? accent : FemoraColors.textSecondary,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  // ── Prediction card ───────────────────────────────────────────────────

  Widget _buildPredictionCard() {
    if (_prediction == null) return const SizedBox.shrink();
    final daysUntil =
        _prediction!.nextPeriodDate.difference(DateTime.now()).inDays;
    final ov =
        _prediction!.ovulationDate.difference(DateTime.now()).inDays;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              FemoraColors.primary.withOpacity(0.88),
              FemoraColors.primaryLight.withOpacity(0.92),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: FemoraColors.primary.withOpacity(0.25),
                blurRadius: 12,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Expanded(
                child: _stat(
                    daysUntil > 0 ? 'In $daysUntil days' : 'Today',
                    'Next Period')),
            _divider(),
            Expanded(
                child: _stat(
                    ov > 0
                        ? 'In $ov days'
                        : ov == 0
                            ? 'Today'
                            : '${-ov}d ago',
                    'Ovulation')),
            _divider(),
            Expanded(
                child: _stat(
                    '${(_prediction!.confidence * 100).toStringAsFixed(0)}%',
                    'Confidence')),
          ],
        ),
      ),
    );
  }

  Widget _stat(String val, String lbl) {
    return Column(
      children: [
        Text(val,
            style: FemoraTextStyles.bodyLarge.copyWith(
                color: Colors.white, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(lbl,
            style: FemoraTextStyles.caption
                .copyWith(color: Colors.white.withOpacity(0.8))),
      ],
    );
  }

  Widget _divider() => Container(
      width: 1,
      height: 38,
      color: Colors.white.withOpacity(0.28));

  // ── Bottom sheets ─────────────────────────────────────────────────────

  void _showFlowSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sheetHandle(),
            const SizedBox(height: 16),
            Text('Period Flow',
                style: FemoraTextStyles.headlineMedium
                    .copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('Next 4 days will be auto-marked at lighter flow',
                style: FemoraTextStyles.caption
                    .copyWith(color: FemoraColors.textSecondary)),
            const SizedBox(height: 16),
            for (final item in [
              ('Heavy', 'high'),
              ('Medium', 'medium'),
              ('Light', 'low'),
            ])
              _flowTile(item.$1, item.$2),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _flowTile(String label, String value) {
    final isSel = _selectedDayLog?.flowLevel == value;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () {
          Navigator.pop(context);
          _logFlowAndAutoFill(value);
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSel
                ? FemoraColors.error.withOpacity(0.1)
                : FemoraColors.lightBackgroundTint,
            borderRadius: BorderRadius.circular(12),
            border: isSel
                ? Border.all(color: FemoraColors.error, width: 1.5)
                : null,
          ),
          child: Row(
            children: [
              Icon(Icons.water_drop_rounded,
                  color: FemoraColors.error, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label,
                    style: FemoraTextStyles.bodyLarge.copyWith(
                        color: FemoraColors.error,
                        fontWeight: isSel
                            ? FontWeight.w700
                            : FontWeight.w400)),
              ),
              if (isSel)
                const Icon(Icons.check_circle_rounded,
                    color: FemoraColors.error, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showSymptomsSheet() {
    final all = [
      'Cramps', 'Headache', 'Fatigue', 'Bloating',
      'Mood Swings', 'Acne', 'Back Pain', 'Nausea',
      'Breast Tenderness', 'Irritability', 'Anxiety', 'Food Cravings',
    ];
    final selected =
        List<String>.from(_selectedDayLog?.symptoms ?? []);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => DraggableScrollableSheet(
          initialChildSize: 0.65,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (_, sc) => Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sheetHandle(),
                const SizedBox(height: 16),
                Text('Symptoms',
                    style: FemoraTextStyles.headlineMedium
                        .copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                Expanded(
                  child: GridView.builder(
                    controller: sc,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 3.0,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: all.length,
                    itemBuilder: (_, i) {
                      final s = all[i];
                      final on = selected.contains(s);
                      return GestureDetector(
                        onTap: () => setSheet(() {
                          on
                              ? selected.remove(s)
                              : selected.add(s);
                        }),
                        child: Container(
                          decoration: BoxDecoration(
                            color: on
                                ? FemoraColors.primary
                                    .withOpacity(0.12)
                                : FemoraColors.lightBackgroundTint,
                            borderRadius:
                                BorderRadius.circular(10),
                            border: on
                                ? Border.all(
                                    color: FemoraColors.primary,
                                    width: 1.5)
                                : null,
                          ),
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8),
                          child: Text(s,
                              textAlign: TextAlign.center,
                              style:
                                  FemoraTextStyles.bodyMedium.copyWith(
                                color: on
                                    ? FemoraColors.primary
                                    : FemoraColors.textSecondary,
                                fontWeight: on
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              )),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: FemoraColors.primary,
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(12))),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _saveSymptoms(selected);
                    },
                    child: Text('Save Symptoms',
                        style: FemoraTextStyles.bodyLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSpottingSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sheetHandle(),
            const SizedBox(height: 16),
            Text('Spotting',
                style: FemoraTextStyles.headlineMedium
                    .copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            _spottingTile(ctx,
                label: 'Yes, spotting today', value: true),
            const SizedBox(height: 8),
            _spottingTile(ctx,
                label: 'No spotting', value: false),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _spottingTile(BuildContext ctx,
      {required String label, required bool value}) {
    final cur = _selectedDayLog?.hasSpotting ?? false;
    final active = value == cur;
    return GestureDetector(
      onTap: () {
        Navigator.pop(ctx);
        _saveSpotting(value);
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: active
              ? _kSpotting.withOpacity(0.1)
              : FemoraColors.lightBackgroundTint,
          borderRadius: BorderRadius.circular(12),
          border: active
              ? Border.all(color: _kSpotting, width: 1.5)
              : null,
        ),
        child: Row(
          children: [
            Icon(
              active
                  ? Icons.check_circle_rounded
                  : Icons.circle_outlined,
              color: _kSpotting,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(label,
                style: FemoraTextStyles.bodyLarge.copyWith(
                    color: FemoraColors.textPrimary,
                    fontWeight: active
                        ? FontWeight.w600
                        : FontWeight.w400)),
          ],
        ),
      ),
    );
  }

  // ── Shared UI helpers ─────────────────────────────────────────────────

  Widget _sheetHandle() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
            color: _kHandleBar,
            borderRadius: BorderRadius.circular(2)),
      ),
    );
  }
}