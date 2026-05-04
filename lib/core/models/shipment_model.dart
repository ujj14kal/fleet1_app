class ShipmentModel {
  final String id;
  final String? shipmentCode;
  final String? manufacturerId;
  final String? currentTransporterId;
  final String goodsDescription;
  final int? quantity;
  final double? weight;
  final String? pickupAddress;
  final String pickupCity;
  final String? pickupState;
  final String? pickupPincode;
  final String receiverName;
  final String receiverPhone;
  final String? receiverAddress;
  final String receiverCity;
  final String? receiverState;
  final String? receiverPincode;
  final String status;
  final String? loadTypeRequired; // 'part_load' | 'full_load'
  final String? truckTypeRequired;
  final String? currentLocation;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Joined data
  final Map<String, dynamic>? transporter;

  ShipmentModel({
    required this.id,
    this.shipmentCode,
    this.manufacturerId,
    this.currentTransporterId,
    required this.goodsDescription,
    this.quantity,
    this.weight,
    this.pickupAddress,
    required this.pickupCity,
    this.pickupState,
    this.pickupPincode,
    required this.receiverName,
    required this.receiverPhone,
    this.receiverAddress,
    required this.receiverCity,
    this.receiverState,
    this.receiverPincode,
    required this.status,
    this.loadTypeRequired,
    this.truckTypeRequired,
    this.currentLocation,
    required this.createdAt,
    this.updatedAt,
    this.transporter,
  });

  factory ShipmentModel.fromJson(Map<String, dynamic> json) => ShipmentModel(
    id: json['id'] as String,
    shipmentCode: json['shipment_code'] as String?,
    manufacturerId: json['manufacturer_id'] as String?,
    currentTransporterId: json['current_transporter_id'] as String?,
    goodsDescription: json['goods_description'] as String? ?? 'Goods',
    quantity: (json['quantity'] as num?)?.toInt(),
    weight: (json['weight'] as num?)?.toDouble(),
    pickupAddress: json['pickup_address'] as String?,
    pickupCity: json['pickup_city'] as String? ?? '—',
    pickupState: json['pickup_state'] as String?,
    pickupPincode: json['pickup_pincode'] as String?,
    receiverName: json['receiver_name'] as String? ?? '—',
    receiverPhone: json['receiver_phone'] as String? ?? '—',
    receiverAddress: json['receiver_address'] as String?,
    receiverCity: json['receiver_city'] as String? ?? '—',
    receiverState: json['receiver_state'] as String?,
    receiverPincode: json['receiver_pincode'] as String?,
    status: json['status'] as String? ?? 'pending',
    loadTypeRequired: json['load_type_required'] as String?,
    truckTypeRequired: json['truck_type_required'] as String?,
    currentLocation: json['current_location'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: json['updated_at'] != null
        ? DateTime.tryParse(json['updated_at'])
        : null,
  );

  String get displayCode => shipmentCode ?? id.substring(0, 8).toUpperCase();

  String get route => '$pickupCity → $receiverCity';

  bool get isActive => status != 'delivered' && status != 'cancelled';

  bool get isDelivered => status == 'delivered';

  String get loadTypeLabel {
    if (loadTypeRequired == 'part_load') return 'PTL';
    if (loadTypeRequired == 'full_load') return 'FTL';
    return '—';
  }

  String get loadTypeFullLabel {
    if (loadTypeRequired == 'part_load') return 'Part Load';
    if (loadTypeRequired == 'full_load') return 'Full Truck';
    return '—';
  }

  String get truckTypeLabel =>
      truckTypeRequired?.replaceAll('_', ' ').toUpperCase() ?? '—';
}

class StatusUpdate {
  final String id;
  final String shipmentId;
  final String status;
  final String? note;
  final String? city;
  final String? updatedBy;
  final DateTime createdAt;

  StatusUpdate({
    required this.id,
    required this.shipmentId,
    required this.status,
    this.note,
    this.city,
    this.updatedBy,
    required this.createdAt,
  });

  factory StatusUpdate.fromJson(Map<String, dynamic> json) => StatusUpdate(
    id: json['id'] as String,
    shipmentId: json['shipment_id'] as String,
    status: json['status'] as String,
    note: json['note'] as String?,
    city: json['city'] as String?,
    updatedBy: json['updated_by'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}
