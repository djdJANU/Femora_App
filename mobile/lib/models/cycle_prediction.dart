/// Cycle Prediction Model
/// Contains predicted cycle information
class CyclePrediction {
  final DateTime nextPeriodDate;
  final DateTime ovulationDate;
  final DateTime fertileWindowStart;
  final DateTime fertileWindowEnd;
  final int averageCycleLength;
  final bool isRegular;
  final double confidence; // 0.0 to 1.0

  CyclePrediction({
    required this.nextPeriodDate,
    required this.ovulationDate,
    required this.fertileWindowStart,
    required this.fertileWindowEnd,
    required this.averageCycleLength,
    required this.isRegular,
    this.confidence = 0.0,
  });

  Map<String, dynamic> toJson() {
    return {
      'next_period_date': nextPeriodDate.toIso8601String(),
      'ovulation_date': ovulationDate.toIso8601String(),
      'fertile_window_start': fertileWindowStart.toIso8601String(),
      'fertile_window_end': fertileWindowEnd.toIso8601String(),
      'average_cycle_length': averageCycleLength,
      'is_regular': isRegular,
      'confidence': confidence,
    };
  }
}

/// Current Phase Information
enum CyclePhase { menstrual, follicular, ovulation, luteal }

class PhaseInfo {
  final CyclePhase phase;
  final int dayOfCycle;
  final String phaseName;
  final String description;

  PhaseInfo({
    required this.phase,
    required this.dayOfCycle,
    required this.phaseName,
    required this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'phase': phase.name,
      'day_of_cycle': dayOfCycle,
      'phase_name': phaseName,
      'description': description,
    };
  }
}
