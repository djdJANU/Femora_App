import '../models/cycle_prediction.dart';
import 'period_repository.dart';
import 'prediction_engine.dart';

/// Phase Calculator
/// Determines the menstrual cycle phase for any given date.
///
/// BUG FIXED: The old version called getCurrentCycle() and then calculated
/// dayOfCycle as selectedDate.difference(currentCycle.startDate) BUT used
/// DateTime.now() implicitly in _estimatePhaseFromPrediction().
/// This caused wrong phases when the user selected a past date.
///
/// FIX: All phase calculations now use selectedDate explicitly throughout.
class PhaseCalculator {
  final PeriodRepository _repository = PeriodRepository();
  final PredictionEngine _predictionEngine = PredictionEngine();

  /// Calculate the cycle phase for [selectedDate].
  ///
  /// Priority order:
  /// 1. If an active (open) cycle exists and [selectedDate] falls within it
  ///    → calculate exact day of cycle
  /// 2. If a past closed cycle contains [selectedDate]
  ///    → calculate exact day of that cycle
  /// 3. If no cycle data but a prediction exists
  ///    → estimate phase relative to [selectedDate]
  /// 4. No data at all → return null (shows empty state in UI)
  Future<PhaseInfo?> calculatePhaseForDate(DateTime selectedDate) async {
    try {
      // Normalise to midnight so date comparisons are clean
      final date = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
      );

      // Step 1 — look for an active (open-ended) cycle
      final activeCycle = await _repository.getCurrentCycle();
      if (activeCycle != null) {
        final cycleStart = DateTime(
          activeCycle.startDate.year,
          activeCycle.startDate.month,
          activeCycle.startDate.day,
        );
        // Only use the active cycle if selectedDate is on or after its start
        if (!date.isBefore(cycleStart)) {
          final dayOfCycle = date.difference(cycleStart).inDays + 1;
          final prediction = await _predictionEngine.generatePrediction();
          final cycleLength = prediction?.averageCycleLength ?? 28;
          return _determinePhase(dayOfCycle, cycleLength);
        }
      }

      // Step 2 — look through closed cycles to find one that contains date
      final allCycles = await _repository.fetchUserCycles(limit: 24);
      for (final cycle in allCycles) {
        if (cycle.endDate == null) continue; // skip open cycles

        final start = DateTime(
          cycle.startDate.year,
          cycle.startDate.month,
          cycle.startDate.day,
        );
        final end = DateTime(
          cycle.endDate!.year,
          cycle.endDate!.month,
          cycle.endDate!.day,
        );

        if (!date.isBefore(start) && !date.isAfter(end)) {
          final dayOfCycle = date.difference(start).inDays + 1;
          final cycleLength = cycle.cycleLength ?? 28;
          return _determinePhase(dayOfCycle, cycleLength);
        }
      }

      // Step 3 — no matching cycle; try to estimate from prediction
      final prediction = await _predictionEngine.generatePrediction();
      if (prediction != null) {
        return _estimatePhaseFromPrediction(prediction, date);
      }

      // Step 4 — no data at all
      return null;
    } catch (e) {
      // Never throw from here — return null so UI shows empty state
      return null;
    }
  }

  /// Map [dayOfCycle] to one of the four phases.
  /// Uses standard 28-day model scaled to [cycleLength].
  PhaseInfo _determinePhase(int dayOfCycle, int cycleLength) {
    // Menstrual: days 1–5
    if (dayOfCycle >= 1 && dayOfCycle <= 5) {
      return PhaseInfo(
        phase: CyclePhase.menstrual,
        dayOfCycle: dayOfCycle,
        phaseName: 'Menstrual',
        description: 'Your period is here. Rest and take care of yourself.',
      );
    }

    // Ovulation occurs ~14 days before next period
    final ovulationDay = cycleLength - 14;

    // Follicular: day 6 up to 2 days before ovulation
    if (dayOfCycle > 5 && dayOfCycle < ovulationDay - 1) {
      return PhaseInfo(
        phase: CyclePhase.follicular,
        dayOfCycle: dayOfCycle,
        phaseName: 'Follicular',
        description: 'Energy is rising. Great time for new activities!',
      );
    }

    // Ovulation window: ±1 day around ovulation day
    if (dayOfCycle >= ovulationDay - 1 && dayOfCycle <= ovulationDay + 1) {
      return PhaseInfo(
        phase: CyclePhase.ovulation,
        dayOfCycle: dayOfCycle,
        phaseName: 'Ovulation',
        description: 'Peak fertility. You might feel your best!',
      );
    }

    // Luteal: rest of the cycle
    return PhaseInfo(
      phase: CyclePhase.luteal,
      dayOfCycle: dayOfCycle,
      phaseName: 'Luteal',
      description: 'Wind-down phase. Self-care is important now.',
    );
  }

  /// Estimate phase when no matching cycle exists, using [selectedDate]
  /// relative to prediction dates.
  ///
  /// OLD BUG: Used DateTime.now() here instead of selectedDate.
  /// FIXED: All comparisons now use [selectedDate] explicitly.
  PhaseInfo _estimatePhaseFromPrediction(
    CyclePrediction prediction,
    DateTime selectedDate,
  ) {
    final daysUntilPeriod = prediction.nextPeriodDate
        .difference(selectedDate)
        .inDays;

    // Period is very close or just started (within ±5 days of predicted start)
    if (daysUntilPeriod <= 0 && daysUntilPeriod >= -5) {
      return PhaseInfo(
        phase: CyclePhase.menstrual,
        dayOfCycle: (-daysUntilPeriod) + 1,
        phaseName: 'Menstrual',
        description: 'Your period has started or is starting very soon.',
      );
    }

    // In fertile window
    if (!selectedDate.isBefore(prediction.fertileWindowStart) &&
        !selectedDate.isAfter(prediction.fertileWindowEnd)) {
      final dayOfWindow =
          selectedDate.difference(prediction.fertileWindowStart).inDays + 1;
      return PhaseInfo(
        phase: CyclePhase.ovulation,
        dayOfCycle: prediction.averageCycleLength - 14,
        phaseName: 'Ovulation',
        description: 'You are in your fertile window. Day $dayOfWindow of 7.',
      );
    }

    // Before ovulation
    if (selectedDate.isBefore(prediction.ovulationDate)) {
      final daysSinceLastPeriod =
          prediction.averageCycleLength -
          prediction.nextPeriodDate.difference(selectedDate).inDays;
      return PhaseInfo(
        phase: CyclePhase.follicular,
        dayOfCycle: daysSinceLastPeriod > 0 ? daysSinceLastPeriod : 6,
        phaseName: 'Follicular',
        description: 'Building energy. Oestrogen is rising.',
      );
    }

    // After ovulation → luteal
    final daysSinceOvulation = selectedDate
        .difference(prediction.ovulationDate)
        .inDays;
    return PhaseInfo(
      phase: CyclePhase.luteal,
      dayOfCycle: prediction.averageCycleLength - daysUntilPeriod,
      phaseName: 'Luteal',
      description:
          'Luteal phase. Day $daysSinceOvulation after ovulation. '
          'Period expected in $daysUntilPeriod days.',
    );
  }
}
