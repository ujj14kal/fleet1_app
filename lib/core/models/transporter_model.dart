class TransporterModel {
  final String id;
  final String userId;
  final String companyName;
  final String? contactPerson;
  final String? phone;
  final String? operatingFrom;
  final List<String> operatingCities;
  final String? loadType; // 'part_load' | 'full_load' | 'both'
  final String? serviceRoutes;
  final bool isActive;
  final DateTime? createdAt;

  TransporterModel({
    required this.id,
    required this.userId,
    required this.companyName,
    this.contactPerson,
    this.phone,
    this.operatingFrom,
    this.operatingCities = const [],
    this.loadType,
    this.serviceRoutes,
    this.isActive = true,
    this.createdAt,
  });

  factory TransporterModel.fromJson(Map<String, dynamic> json) {
    List<String> cities = [];
    final raw = json['operating_cities'];
    if (raw is List) cities = raw.map((e) => e.toString()).toList();
    return TransporterModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      companyName: json['company_name'] as String? ?? '—',
      contactPerson: json['contact_person'] as String?,
      phone: json['phone'] as String?,
      operatingFrom: json['operating_from'] as String?,
      operatingCities: cities,
      loadType: json['load_type'] as String?,
      serviceRoutes: json['service_routes'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    );
  }

  String get loadTypeLabel {
    switch (loadType) {
      case 'part_load': return 'Part Load';
      case 'full_load': return 'Full Load';
      case 'both': return 'Part & Full Load';
      default: return '—';
    }
  }
}
