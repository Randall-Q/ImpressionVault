class Customer {
  Customer({
    this.id,
    required this.name,
    required this.address,
    required this.email,
    this.birthdate,
    required this.sex,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final String name;
  final String address;
  final String email;
  final DateTime? birthdate;
  final String sex;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'address': address,
      'email': email,
      'birthdate': birthdate?.toIso8601String(),
      'sex': sex,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as int?,
      name: map['name'] as String,
      address: map['address'] as String? ?? '',
      email: map['email'] as String? ?? '',
      birthdate: map['birthdate'] == null
          ? null
          : DateTime.tryParse(map['birthdate'] as String),
      sex: map['sex'] as String? ?? 'Unknown',
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
