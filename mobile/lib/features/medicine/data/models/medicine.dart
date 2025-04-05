class Medicine {
  final String id;
  final String name;
  final int quantity;
  final DateTime expiry;
  final bool priority;
  final String hospitalId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Medicine({
    required this.id,
    required this.name,
    required this.quantity,
    required this.expiry,
    required this.priority,
    required this.hospitalId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Medicine.fromJson(Map<String, dynamic> json) {
    return Medicine(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      quantity: json['quantity'] ?? 0,
      expiry: json['expiry'] != null
          ? DateTime.parse(json['expiry'])
          : DateTime.now().add(const Duration(days: 30)),
      priority: json['priority'] ?? false,
      hospitalId: json['hospitalId'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'expiry': expiry.toIso8601String(),
      'priority': priority,
      'hospitalId': hospitalId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
