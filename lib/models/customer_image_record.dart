class CustomerImageRecord {
  CustomerImageRecord({
    this.id,
    required this.customerId,
    required this.path,
    required this.createdAt,
  });

  final int? id;
  final int customerId;
  final String path;
  final DateTime createdAt;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'customer_id': customerId,
      'path': path,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory CustomerImageRecord.fromMap(Map<String, dynamic> map) {
    return CustomerImageRecord(
      id: map['id'] as int?,
      customerId: map['customer_id'] as int,
      path: map['path'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
