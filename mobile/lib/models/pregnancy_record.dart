/// Pregnancy Record Model
/// One row per pregnancy. Status tracks lifecycle.
class PregnancyRecord {
  final String id;
  final String userId;
  final DateTime lmpDate;      // Last Menstrual Period
  final DateTime dueDate;      // lmpDate + 280 days
  final String status;         // 'active' | 'completed' | 'archived'
  final String? babyName;
  final String? babyGender;    // 'boy' | 'girl' | 'unknown'
  final DateTime? actualBirthDate;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  PregnancyRecord({
    required this.id,
    required this.userId,
    required this.lmpDate,
    required this.dueDate,
    required this.status,
    this.babyName,
    this.babyGender,
    this.actualBirthDate,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PregnancyRecord.fromJson(Map<String, dynamic> json) {
    return PregnancyRecord(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      lmpDate: DateTime.parse(json['lmp_date'].toString()),
      dueDate: DateTime.parse(json['due_date'].toString()),
      status: json['status']?.toString() ?? 'active',
      babyName: json['baby_name']?.toString(),
      babyGender: json['baby_gender']?.toString(),
      actualBirthDate: json['actual_birth_date'] != null
          ? DateTime.parse(json['actual_birth_date'].toString())
          : null,
      notes: json['notes']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'lmp_date': lmpDate.toIso8601String().split('T')[0],
      'due_date': dueDate.toIso8601String().split('T')[0],
      'status': status,
      'baby_name': babyName,
      'baby_gender': babyGender,
      'actual_birth_date':
          actualBirthDate?.toIso8601String().split('T')[0],
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  PregnancyRecord copyWith({
    String? status,
    String? babyName,
    String? babyGender,
    DateTime? actualBirthDate,
    String? notes,
  }) {
    return PregnancyRecord(
      id: id,
      userId: userId,
      lmpDate: lmpDate,
      dueDate: dueDate,
      status: status ?? this.status,
      babyName: babyName ?? this.babyName,
      babyGender: babyGender ?? this.babyGender,
      actualBirthDate: actualBirthDate ?? this.actualBirthDate,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  // ── Computed properties ────────────────────────────────────────

  /// Current gestational week (1-40+)
  int get currentWeek {
    final today = DateTime.now();
    final days = today.difference(lmpDate).inDays;
    final week = (days / 7).floor() + 1;
    return week.clamp(1, 42);
  }

  /// Days remaining until due date
  int get daysRemaining {
    final today = DateTime.now();
    return dueDate.difference(today).inDays;
  }

  /// Weeks remaining until due date
  int get weeksRemaining => (daysRemaining / 7).ceil().clamp(0, 42);

  /// Current trimester (1, 2, or 3)
  int get trimester {
    if (currentWeek <= 13) return 1;
    if (currentWeek <= 26) return 2;
    return 3;
  }

  /// Human-readable trimester label
  String get trimesterLabel {
    switch (trimester) {
      case 1: return '1st Trimester';
      case 2: return '2nd Trimester';
      default: return '3rd Trimester';
    }
  }

  /// Progress percentage 0.0 → 1.0
  double get progressPercent =>
      ((currentWeek - 1) / 40.0).clamp(0.0, 1.0);

  bool get isActive => status == 'active';
  bool get isCompleted => status == 'completed';
}

/// Pregnancy Daily Log Model
class PregnancyDailyLog {
  final String id;
  final String userId;
  final String pregnancyId;
  final DateTime logDate;
  final int? weekNumber;
  final String? mood;
  final List<String> symptoms;
  final double? weightKg;
  final String? bellyPhotoUrl;
  final String? notes;
  final DateTime createdAt;

  PregnancyDailyLog({
    required this.id,
    required this.userId,
    required this.pregnancyId,
    required this.logDate,
    this.weekNumber,
    this.mood,
    this.symptoms = const [],
    this.weightKg,
    this.bellyPhotoUrl,
    this.notes,
    required this.createdAt,
  });

  factory PregnancyDailyLog.fromJson(Map<String, dynamic> json) {
    List<String> parseList(dynamic raw) {
      if (raw == null) return [];
      if (raw is List) return raw.map((e) => e?.toString() ?? '').toList();
      return [];
    }

    return PregnancyDailyLog(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      pregnancyId: json['pregnancy_id']?.toString() ?? '',
      logDate: DateTime.parse(json['log_date'].toString()),
      weekNumber: json['week_number'] != null
          ? int.tryParse(json['week_number'].toString())
          : null,
      mood: json['mood']?.toString(),
      symptoms: parseList(json['symptoms']),
      weightKg: json['weight_kg'] != null
          ? double.tryParse(json['weight_kg'].toString())
          : null,
      bellyPhotoUrl: json['belly_photo_url']?.toString(),
      notes: json['notes']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'pregnancy_id': pregnancyId,
        'log_date': logDate.toIso8601String().split('T')[0],
        'week_number': weekNumber,
        'mood': mood,
        'symptoms': symptoms,
        'weight_kg': weightKg,
        'belly_photo_url': bellyPhotoUrl,
        'notes': notes,
      };
}

/// Kick Counter Session
class KickLog {
  final String id;
  final String pregnancyId;
  final DateTime sessionDate;
  final int kickCount;
  final int? durationMinutes;
  final DateTime? startedAt;
  final DateTime? completedAt;

  KickLog({
    required this.id,
    required this.pregnancyId,
    required this.sessionDate,
    required this.kickCount,
    this.durationMinutes,
    this.startedAt,
    this.completedAt,
  });

  factory KickLog.fromJson(Map<String, dynamic> json) {
    return KickLog(
      id: json['id']?.toString() ?? '',
      pregnancyId: json['pregnancy_id']?.toString() ?? '',
      sessionDate: DateTime.parse(json['session_date'].toString()),
      kickCount:
          int.tryParse(json['kick_count']?.toString() ?? '0') ?? 0,
      durationMinutes: json['duration_minutes'] != null
          ? int.tryParse(json['duration_minutes'].toString())
          : null,
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'].toString())
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'].toString())
          : null,
    );
  }
}