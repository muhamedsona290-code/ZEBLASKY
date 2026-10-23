class CareReminder {
  final String id;
  final String title;
  final String time; // e.g., "08:00 AM"
  final String category; // 'Medication', 'Meal', 'Routine', 'Check-in'
  final bool isEnabled;
  final String description;

  const CareReminder({
    required this.id,
    required this.title,
    required this.time,
    required this.category,
    this.isEnabled = true,
    this.description = '',
  });

  CareReminder copyWith({
    String? id,
    String? title,
    String? time,
    String? category,
    bool? isEnabled,
    String? description,
  }) {
    return CareReminder(
      id: id ?? this.id,
      title: title ?? this.title,
      time: time ?? this.time,
      category: category ?? this.category,
      isEnabled: isEnabled ?? this.isEnabled,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'time': time,
        'category': category,
        'isEnabled': isEnabled,
        'description': description,
      };

  factory CareReminder.fromJson(Map<String, dynamic> json) => CareReminder(
        id: json['id'] as String,
        title: json['title'] as String,
        time: json['time'] as String,
        category: json['category'] as String,
        isEnabled: json['isEnabled'] as bool? ?? true,
        description: json['description'] as String? ?? '',
      );
}
