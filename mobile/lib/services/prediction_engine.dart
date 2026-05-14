import '../models/cycle_prediction.dart';
import 'period_repository.dart';

/// Prediction Engine
/// Calculates cycle predictions using weighted average algorithm
class PredictionEngine {
  final PeriodRepository _repository = PeriodRepository();

  /// Calculate weighted average cycle length
  /// Uses last 6 cycles with weights: [3, 2, 2, 1, 1, 1] for recent to old
  Future<int> calculateWeightedAverageCycleLength() async {
    try {
      final cycles = await _repository.fetchUserCycles(limit: 6);

      if (cycles.isEmpty) {
        return 28; // Default cycle length
      }

      // Filter only confirmed cycles with cycle length in the normal range
      // (21–35 days). Cycles outside this range are treated as irregular
      // and excluded from the average.
      final validCycles = cycles
          .where((c) =>
              c.isConfirmed &&
              c.cycleLength != null &&
              c.cycleLength! >= 21 &&
              c.cycleLength! <= 35)
          .toList();

      if (validCycles.isEmpty) {
        return 28; // Default
      }

      if (validCycles.length == 1) {
        return validCycles.first.cycleLength!;
      }

      // Weights for recent to old cycles [3, 2, 2, 1, 1, 1]
      final weights = [3, 2, 2, 1, 1, 1];
      double totalWeighted = 0;
      double totalWeight = 0;

      for (int i = 0; i < validCycles.length && i < weights.length; i++) {
        final cycleLength = validCycles[i].cycleLength!;
        final weight = weights[i];
        totalWeighted += cycleLength * weight;
        totalWeight += weight;
      }

      return (totalWeighted / totalWeight).round();
    } catch (e) {
      throw Exception('Failed to calculate weighted average: $e');
    }
  }

  /// Generate full cycle prediction
  Future<CyclePrediction?> generatePrediction() async {
    try {
      final cycles = await _repository.fetchUserCycles(limit: 6);

      if (cycles.isEmpty) {
        return null; // No data yet
      }

      // Only use confirmed cycles with cycle_length in the normal
      // range (21–35 days). Anything outside that is treated as
      // unusable data — we will not project a date from it.
      final validCycles = cycles
          .where((c) =>
              c.isConfirmed &&
              c.cycleLength != null &&
              c.cycleLength! >= 21 &&
              c.cycleLength! <= 35)
          .toList();

      if (validCycles.isEmpty) {
        // No reliable cycle to anchor a prediction on — show empty
        // state in the UI rather than a misleading 28-day default.
        return null;
      }

      // Get the most recent valid cycle as the anchor
      final lastCycle = validCycles.first;

      // Calculate average cycle length (falls back to 28 only when no
      // valid cycles exist — which we have already excluded above)
      final avgCycleLength = await calculateWeightedAverageCycleLength();

      // Calculate next period date
      final nextPeriodDate = lastCycle.startDate.add(
        Duration(days: avgCycleLength),
      );

      // Calculate ovulation date (14 days before next period)
      final ovulationDate = nextPeriodDate.subtract(const Duration(days: 14));

      // Calculate fertile window (ovulation ± 3 days)
      final fertileWindowStart = ovulationDate.subtract(
        const Duration(days: 3),
      );
      final fertileWindowEnd = ovulationDate.add(const Duration(days: 3));

      // Determine if cycle is regular
      final isRegular = await _isRegularCycle();

      // Calculate confidence based on data availability and regularity
      final confidence = _calculateConfidence(cycles.length, isRegular);

      return CyclePrediction(
        nextPeriodDate: nextPeriodDate,
        ovulationDate: ovulationDate,
        fertileWindowStart: fertileWindowStart,
        fertileWindowEnd: fertileWindowEnd,
        averageCycleLength: avgCycleLength,
        isRegular: isRegular,
        confidence: confidence,
      );
    } catch (e) {
      throw Exception('Failed to generate prediction: $e');
    }
  }

  /// Check if cycle is regular based on standard deviation
  Future<bool> _isRegularCycle() async {
    try {
      final cycles = await _repository.fetchUserCycles(limit: 6);

      final validCycles = cycles
          .where((c) =>
              c.isConfirmed &&
              c.cycleLength != null &&
              c.cycleLength! >= 21 &&
              c.cycleLength! <= 35)
          .toList();

      if (validCycles.length < 3) {
        return false; // Not enough data
      }

      // Calculate standard deviation
      final lengths = validCycles.map((c) => c.cycleLength!).toList();
      final mean = lengths.reduce((a, b) => a + b) / lengths.length;

      final variance =
          lengths
              .map((length) => (length - mean) * (length - mean))
              .reduce((a, b) => a + b) /
          lengths.length;

      final stdDev = _sqrt(variance);

      // If standard deviation <= 8 days, consider it regular
      return stdDev <= 8.0;
    } catch (e) {
      return false;
    }
  }

  /// Calculate prediction confidence
  double _calculateConfidence(int cycleCount, bool isRegular) {
    if (cycleCount == 0) return 0.0;
    if (cycleCount == 1) return 0.3;
    if (cycleCount == 2) return 0.5;

    // Base confidence on count
    double confidence = 0.5 + (cycleCount * 0.1);

    // Boost if regular
    if (isRegular) {
      confidence += 0.2;
    }

    // Cap at 1.0
    return confidence > 1.0 ? 1.0 : confidence;
  }

  /// Simple square root implementation
  double _sqrt(double value) {
    if (value < 0) return 0;
    if (value == 0) return 0;

    double x = value;
    double y = 1;
    double precision = 0.000001;

    while (x - y > precision) {
      x = (x + y) / 2;
      y = value / x;
    }

    return x;
  }

  /// Predict next N periods
  Future<List<DateTime>> predictNextPeriods(int count) async {
    try {
      final avgCycleLength = await calculateWeightedAverageCycleLength();
      final cycles = await _repository.fetchUserCycles(limit: 1);

      if (cycles.isEmpty) {
        return [];
      }

      final lastCycleStart = cycles.first.startDate;
      final predictions = <DateTime>[];

      for (int i = 1; i <= count; i++) {
        predictions.add(lastCycleStart.add(Duration(days: avgCycleLength * i)));
      }

      return predictions;
    } catch (e) {
      throw Exception('Failed to predict next periods: $e');
    }
  }
}
