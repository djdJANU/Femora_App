/// Period Daily Log Model
/// Represents daily period tracking data
class PeriodDailyLog {
  final String id;
  final String userId;
  final String? cycleId;
  final DateTime logDate;
  final String? flowLevel; // 'low', 'medium', 'high'
  final int? painLevel;   // 0-10
  final List<String> symptoms;
  final bool hasSpotting;
  final String? notes;
  final String? mood;
  final DateTime createdAt;
  final DateTime? updatedAt;

  PeriodDailyLog({
    required this.id,
    required this.userId,
    this.cycleId,
    required this.logDate,
    this.flowLevel,
    this.painLevel,
    this.symptoms = const [],
    this.hasSpotting = false,
    this.notes,
    this.mood,
    required this.createdAt,
    this.updatedAt,
  });

  factory PeriodDailyLog.fromJson(Map<String, dynamic> json) {
    // Safe symptom list parsing — DB returns PostgreSQL array or null
    List<String> parseSymptoms(dynamic raw) {
      if (raw == null) return [];
      if (raw is List) return raw.map((e) => e?.toString() ?? '').toList();
      return [];
    }

    return PeriodDailyLog(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      cycleId: json['cycle_id']?.toString(),
      logDate: DateTime.parse(json['log_date'].toString()),
      flowLevel: json['flow_level']?.toString(),
      painLevel: json['pain_level'] != null
          ? int.tryParse(json['pain_level'].toString())
          : null,
      symptoms: parseSymptoms(json['symptoms']),
      hasSpotting: json['has_spotting'] as bool? ?? false,
      notes: json['notes']?.toString(),
      mood: json['mood']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'cycle_id': cycleId,
      'log_date': logDate.toIso8601String().split('T')[0],
      'flow_level': flowLevel,
      'pain_level': painLevel,
      'symptoms': symptoms,
      'has_spotting': hasSpotting,
      'notes': notes,
      'mood': mood,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  PeriodDailyLog copyWith({
    String? id,
    String? userId,
    String? cycleId,
    DateTime? logDate,
    String? flowLevel,
    int? painLevel,
    List<String>? symptoms,
    bool? hasSpotting,
    String? notes,
    String? mood,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PeriodDailyLog(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      cycleId: cycleId ?? this.cycleId,
      logDate: logDate ?? this.logDate,
      flowLevel: flowLevel ?? this.flowLevel,
      painLevel: painLevel ?? this.painLevel,
      symptoms: symptoms ?? this.symptoms,
      hasSpotting: hasSpotting ?? this.hasSpotting,
      notes: notes ?? this.notes,
      mood: mood ?? this.mood,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Whether this log has any data entered
  bool get isEmpty =>
      flowLevel == null &&
      painLevel == null &&
      symptoms.isEmpty &&
      !hasSpotting &&
      (notes == null || notes!.isEmpty) &&
      mood == null;
}