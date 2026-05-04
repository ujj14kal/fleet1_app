class ProfileModel {
  final String id;
  final String? fullName;
  final String? companyName;
  final String? phone;
  final String role; // 'manufacturer' | 'transporter' | 'ops' | 'admin' | 'driver'
  final String? city;
  final String? state;
  final String? pincode;
  final String? street;
  final bool isActive;
  final DateTime? createdAt;

  ProfileModel({
    required this.id,
    this.fullName,
    this.companyName,
    this.phone,
    required this.role,
    this.city,
    this.state,
    this.pincode,
    this.street,
    this.isActive = true,
    this.createdAt,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) => ProfileModel(
    id: json['id'] as String,
    fullName: json['full_name'] as String?,
    companyName: json['company_name'] as String?,
    phone: json['phone'] as String?,
    role: json['role'] as String? ?? 'manufacturer',
    city: json['city'] as String?,
    state: json['state'] as String?,
    pincode: json['pincode'] as String?,
    street: json['street'] as String?,
    isActive: json['is_active'] as bool? ?? true,
    createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'full_name': fullName, 'company_name': companyName, 'phone': phone,
    'role': role, 'city': city, 'state': state, 'pincode': pincode, 'street': street,
    'is_active': isActive,
  };

  String get initials {
    if (fullName == null || fullName!.isEmpty) return '--';
    final parts = fullName!.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return fullName![0].toUpperCase();
  }

  String get displayName => fullName ?? companyName ?? 'User';
}
