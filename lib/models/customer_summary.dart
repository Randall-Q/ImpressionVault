class CustomerSummary {
  CustomerSummary({
    required this.id,
    required this.name,
    required this.email,
    required this.sex,
    this.birthdate,
    required this.imageCount,
  });

  final int id;
  final String name;
  final String email;
  final String sex;
  final DateTime? birthdate;
  final int imageCount;

  factory CustomerSummary.fromMap(Map<String, dynamic> map) {
    return CustomerSummary(
      id: map['id'] as int,
      name: map['name'] as String,
      email: map['email'] as String? ?? '',
      sex: map['sex'] as String? ?? 'Unknown',
      birthdate: map['birthdate'] == null
          ? null
          : DateTime.tryParse(map['birthdate'] as String),
      imageCount: (map['image_count'] as num?)?.toInt() ?? 0,
    );
  }
}
