class CareNote {
  final String id;
  final String author;
  final String role;
  final String note;
  final DateTime createdAt;
  final bool isSensitive;

  const CareNote({
    required this.id,
    required this.author,
    required this.role,
    required this.note,
    required this.createdAt,
    this.isSensitive = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'author': author,
        'role': role,
        'note': note,
        'createdAt': createdAt.toIso8601String(),
        'isSensitive': isSensitive,
      };

  factory CareNote.fromJson(Map<String, dynamic> json) => CareNote(
        id: json['id'] as String,
        author: json['author'] as String,
        role: json['role'] as String,
        note: json['note'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        isSensitive: json['isSensitive'] as bool? ?? false,
      );
}
