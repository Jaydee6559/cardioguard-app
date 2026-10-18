/// A caregiver account saved on this phone.
class Account {
  final String name;
  final String email;
  final String relationship; // to the wearer, e.g. "Daughter"

  const Account({required this.name, required this.email, required this.relationship});

  /// "MS" for "Maria Santos".
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}
