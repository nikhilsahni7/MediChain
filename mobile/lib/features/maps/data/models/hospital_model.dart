class Hospital {
  final String id;
  final String? name;
  final String email;
  final String walletAddress;
  final double? latitude;
  final double? longitude;
  final int reputation;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double? distance;

  Hospital({
    required this.id,
    this.name,
    required this.email,
    required this.walletAddress,
    this.latitude,
    this.longitude,
    required this.reputation,
    required this.createdAt,
    required this.updatedAt,
    this.distance,
  });

  factory Hospital.fromJson(Map<String, dynamic> json) {
    return Hospital(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      walletAddress: json['walletAddress'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      reputation: json['reputation'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      distance: json['distance']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'walletAddress': walletAddress,
      'latitude': latitude,
      'longitude': longitude,
      'reputation': reputation,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'distance': distance,
    };
  }
}
