/// A person to call or notify in an emergency.
class EmergencyContact {
  final String name;
  final String relationship;
  final String phone;
  final bool primary; // the first person to call; shown on the Emergency Alert

  const EmergencyContact({
    required this.name,
    required this.relationship,
    required this.phone,
    this.primary = false,
  });

  EmergencyContact copyWith({String? name, String? relationship, String? phone, bool? primary}) {
    return EmergencyContact(
      name: name ?? this.name,
      relationship: relationship ?? this.relationship,
      phone: phone ?? this.phone,
      primary: primary ?? this.primary,
    );
  }
}
