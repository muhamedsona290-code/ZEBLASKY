class TrustedContact {
  final String id;
  final String name;
  final String relationship; // e.g., 'Son (Primary Caregiver)', 'Next-door Neighbor'
  final String phone;
  final int tier; // 1 = Family, 2 = Neighbors/Doctor, 3 = Emergency
  final String locationNote; // e.g., '2 mins away', 'Ernakulam Clinic'
  final bool isPrimary;
  final bool hasConsented;

  const TrustedContact({
    required this.id,
    required this.name,
    required this.relationship,
    required this.phone,
    required this.tier,
    this.locationNote = '',
    this.isPrimary = false,
    this.hasConsented = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'relationship': relationship,
        'phone': phone,
        'tier': tier,
        'locationNote': locationNote,
        'isPrimary': isPrimary,
        'hasConsented': hasConsented,
      };

  factory TrustedContact.fromJson(Map<String, dynamic> json) => TrustedContact(
        id: json['id'] as String,
        name: json['name'] as String,
        relationship: json['relationship'] as String,
        phone: json['phone'] as String,
        tier: json['tier'] as int? ?? 1,
        locationNote: json['locationNote'] as String? ?? '',
        isPrimary: json['isPrimary'] as bool? ?? false,
        hasConsented: json['hasConsented'] as bool? ?? true,
      );
}
