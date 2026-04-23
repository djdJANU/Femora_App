/// Period Cycle Model
/// Represents a complete menstrual cycle
class PeriodCycle {
  final String id;
  final String userId;
  final DateTime startDate;
  final DateTime? endDate;
  final int? cycleLength;
  final int? bleedingDays;
  final bool isConfirmed;
  final bool isPredicted;
  final DateTime createdAt;
  final DateTime updatedAt;

  PeriodCycle({
    required this.id,
    required this.userId,
    required this.startDate,
    this.endDate,
    this.cycleLength,
    this.bleedingDays,
    required this.isConfirmed,
    this.isPredicted = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PeriodCycle.fromJson(Map<String, dynamic> json) {
    // NEVER use hard casts like json['id'] as String on DB data.
    // Supabase can return null for any field. Use null-safe operators throughout.
    return PeriodCycle(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      startDate: DateTime.parse(json['start_date'].toString()),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'].toString())
          : null,
      cycleLength: json['cycle_length'] != null
          ? int.tryParse(json['cycle_length'].toString())
          : null,
      bleedingDays: json['bleeding_days'] != null
          ? int.tryParse(json['bleeding_days'].toString())
          : null,
      isConfirmed: json['is_confirmed'] as bool? ?? false,
      isPredicted: json['is_predicted'] as bool? ?? false,
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
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate?.toIso8601String().split('T')[0],
      'cycle_length': cycleLength,
      'bleeding_days': bleedingDays,
      'is_confirmed': isConfirmed,
      'is_predicted': isPredicted,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  PeriodCycle copyWith({
    String? id,
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
    int? cycleLength,
    int? bleedingDays,
    bool? isConfirmed,
    bool? isPredicted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PeriodCycle(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      cycleLength: cycleLength ?? this.cycleLength,
      bleedingDays: bleedingDays ?? this.bleedingDays,
      isConfirmed: isConfirmed ?? this.isConfirmed,
      isPredicted: isPredicted ?? this.isPredicted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}