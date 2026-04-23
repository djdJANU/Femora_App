import 'period_repository.dart';

/// Irregularity Analyzer
/// Analyzes cycle patterns and detects irregularities
class IrregularityAnalyzer {
  final PeriodRepository _repository = PeriodRepository();

  /// Analyze if cycles are irregular
  /// Returns true if standard deviation > 8 days for 3+ cycles
  Future<IrregularityReport> analyzeCycles() async {
    try {
      final cycles = await _repository.fetchUserCycles(limit: 6);

      final validCycles = cycles
          .where((c) => c.isConfirmed && c.cycleLength != null)
          .toList();

      if (validCycles.length < 3) {
        return IrregularityReport(
          isIrregular: false,
          standardDeviation: 0.0,
          averageLength: validCycles.isNotEmpty
              ? validCycles.first.cycleLength!.toDouble()
              : 28.0,
          cycleCount: validCycles.length,
          message: 'Not enough data to analyze regularity',
        );
      }

      // Calculate statistics
      final lengths = validCycles.map((c) => c.cycleLength!).toList();
      final mean = lengths.reduce((a, b) => a + b) / lengths.length;

      final variance =
          lengths
              .map((length) => (length - mean) * (length - mean))
              .reduce((a, b) => a + b) /
          lengths.length;

      final stdDev = _sqrt(variance);

      // Check if irregular
      final isIrregular = stdDev > 8.0 && validCycles.length >= 3;

      String message;
      if (isIrregular) {
        message =
            'Your cycles show irregular patterns. '
            'Consider consulting a healthcare provider.';
      } else if (stdDev > 5.0) {
        message = 'Your cycles show some variation but are generally regular.';
      } else {
        message = 'Your cycles are very regular!';
      }

      return IrregularityReport(
        isIrregular: isIrregular,
        standardDeviation: stdDev,
        averageLength: mean,
        cycleCount: validCycles.length,
        message: message,
        minLength: lengths.reduce((a, b) => a < b ? a : b),
        maxLength: lengths.reduce((a, b) => a > b ? a : b),
      );
    } catch (e) {
      throw Exception('Failed to analyze cycles: $e');
    }
  }

  /// Detect unusual patterns
  Future<List<String>> detectPatterns() async {
    try {
      final report = await analyzeCycles();
      final patterns = <String>[];

      if (report.isIrregular) {
        patterns.add('Irregular cycle pattern detected');
      }

      if (report.minLength != null && report.minLength! < 21) {
        patterns.add('Some cycles shorter than 21 days');
      }

      if (report.maxLength != null && report.maxLength! > 35) {
        patterns.add('Some cycles longer than 35 days');
      }

      final lengthRange = (report.maxLength ?? 28) - (report.minLength ?? 28);
      if (lengthRange > 15) {
        patterns.add('High variation in cycle length');
      }

      return patterns;
    } catch (e) {
      throw Exception('Failed to detect patterns: $e');
    }
  }

  /// Check if a specific cycle is an outlier
  bool isCycleOutlier(int cycleLength, double averageLength, double stdDev) {
    final deviation = (cycleLength - averageLength).abs();
    return deviation > (2 * stdDev); // More than 2 standard deviations
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
}

/// Irregularity Report Model
class IrregularityReport {
  final bool isIrregular;
  final double standardDeviation;
  final double averageLength;
  final int cycleCount;
  final String message;
  final int? minLength;
  final int? maxLength;

  IrregularityReport({
    required this.isIrregular,
    required this.standardDeviation,
    required this.averageLength,
    required this.cycleCount,
    required this.message,
    this.minLength,
    this.maxLength,
  });

  Map<String, dynamic> toJson() {
    return {
      'is_irregular': isIrregular,
      'standard_deviation': standardDeviation,
      'average_length': averageLength,
      'cycle_count': cycleCount,
      'message': message,
      'min_length': minLength,
      'max_length': maxLength,
    };
  }
}
