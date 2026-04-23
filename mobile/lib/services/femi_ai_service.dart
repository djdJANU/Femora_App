import 'period_repository.dart';
import 'prediction_engine.dart';
import 'phase_calculator.dart';
import 'irregularity_analyzer.dart';

/// FEMI AI Service
/// Provides cycle summary data for AI assistant integration
class FemiAIService {
  final PeriodRepository _repository = PeriodRepository();
  final PredictionEngine _predictionEngine = PredictionEngine();
  final PhaseCalculator _phaseCalculator = PhaseCalculator();
  final IrregularityAnalyzer _analyzer = IrregularityAnalyzer();

  /// Get comprehensive cycle summary for AI
  Future<Map<String, dynamic>> getCycleSummaryForAI() async {
    try {
      // Fetch current phase
      final phaseInfo = await _phaseCalculator.calculatePhaseForDate(DateTime.now());

      // Get prediction
      final prediction = await _predictionEngine.generatePrediction();

      // Get irregularity report
      final irregularityReport = await _analyzer.analyzeCycles();

      // Get recent cycles
      final cycles = await _repository.fetchUserCycles(limit: 3);

      // Get recent logs for symptom patterns
      final DateTime endDate = DateTime.now();
      final DateTime startDate = endDate.subtract(const Duration(days: 90));
      final recentLogs = await _repository.fetchDailyLogsForDateRange(
        startDate: startDate,
        endDate: endDate,
      );

      // Analyze symptom patterns
      final symptomPatterns = _analyzeSymptomPatterns(recentLogs);

      return {
        'current_phase': phaseInfo?.toJson(),
        'prediction': prediction?.toJson(),
        'irregularity': irregularityReport.toJson(),
        'is_irregular': irregularityReport.isIrregular,
        'symptom_patterns': symptomPatterns,
        'recent_cycles_count': cycles.length,
        'average_cycle_length': irregularityReport.averageLength,
        'cycle_regularity_message': irregularityReport.message,
        'last_period_date': cycles.isNotEmpty
            ? cycles.first.startDate.toIso8601String()
            : null,
        'days_since_last_period': cycles.isNotEmpty
            ? DateTime.now().difference(cycles.first.startDate).inDays
            : null,
      };
    } catch (e) {
      throw Exception('Failed to get cycle summary for AI: $e');
    }
  }

  /// Analyze symptom patterns from logs
  Map<String, dynamic> _analyzeSymptomPatterns(List<dynamic> logs) {
    final Map<String, int> symptomFrequency = {};
    int totalSpotting = 0;
    final Map<String, int> flowLevelCount = {};

    for (final log in logs) {
      // Count symptoms
      for (final symptom in log.symptoms) {
        symptomFrequency[symptom] = (symptomFrequency[symptom] ?? 0) + 1;
      }

      // Count spotting
      if (log.hasSpotting) {
        totalSpotting++;
      }

      // Count flow levels
      if (log.flowLevel != null) {
        flowLevelCount[log.flowLevel!] =
            (flowLevelCount[log.flowLevel!] ?? 0) + 1;
      }
    }

    // Sort symptoms by frequency
    final sortedSymptoms = symptomFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return {
      'most_common_symptoms': sortedSymptoms
          .take(5)
          .map((e) => {'symptom': e.key, 'count': e.value})
          .toList(),
      'spotting_frequency': totalSpotting,
      'flow_level_distribution': flowLevelCount,
      'total_logs': logs.length,
    };
  }

  /// Get quick status for AI chat context
  Future<String> getQuickStatusForAI() async {
    try {
      final summary = await getCycleSummaryForAI();

      final phaseInfo = summary['current_phase'];
      final prediction = summary['prediction'];
      final isIrregular = summary['is_irregular'] as bool;

      String status = '';

      if (phaseInfo != null) {
        status +=
            'Current Phase: ${phaseInfo['phase_name']} '
            '(Day ${phaseInfo['day_of_cycle']})\n';
      }

      if (prediction != null) {
        final nextPeriod = DateTime.parse(prediction['next_period_date']);
        final daysUntil = nextPeriod.difference(DateTime.now()).inDays;
        status +=
            'Next Period: ${daysUntil > 0 ? "in $daysUntil days" : "today or overdue"}\n';
      }

      status += 'Cycle Pattern: ${isIrregular ? "Irregular" : "Regular"}\n';

      final avgLength = summary['average_cycle_length'];
      if (avgLength != null) {
        status +=
            'Average Cycle Length: ${avgLength.toStringAsFixed(0)} days\n';
      }

      return status;
    } catch (e) {
      return 'Unable to retrieve cycle status';
    }
  }
}
