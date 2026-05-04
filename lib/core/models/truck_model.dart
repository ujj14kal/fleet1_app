class TruckModel {
  final String id;
  final String transporterId;
  final String? truckLabel;
  final String? truckType;
  final String? loadCategory; // 'part_load' | 'full_load'
  final int? capacityKg;
  final String? truckNumber;
  final String? driverName;
  final String? driverPhone;

  TruckModel({
    required this.id,
    required this.transporterId,
    this.truckLabel,
    this.truckType,
    this.loadCategory,
    this.capacityKg,
    this.truckNumber,
    this.driverName,
    this.driverPhone,
  });

  factory TruckModel.fromJson(Map<String, dynamic> json) => TruckModel(
    id: json['id'] as String,
    transporterId: json['transporter_id'] as String,
    truckLabel: json['truck_label'] as String?,
    truckType: json['truck_type'] as String?,
    loadCategory: json['load_category'] as String?,
    capacityKg: (json['capacity_kg'] as num?)?.toInt(),
    truckNumber: json['truck_number'] as String?,
    driverName: json['driver_name'] as String?,
    driverPhone: json['driver_phone'] as String?,
  );

  String get displayName => truckLabel ?? truckType ?? 'Truck';

  String get capacityLabel {
    if (capacityKg == null) return '—';
    if (capacityKg! >= 1000) return '${(capacityKg! / 1000).toStringAsFixed(capacityKg! % 1000 == 0 ? 0 : 1)} ton';
    return '${capacityKg} kg';
  }

  String get imageAsset {
    final t = truckType?.toLowerCase() ?? '';
    if (t.contains('trailer')) return 'assets/images/truck_trailer.png';
    if (t.contains('container')) return 'assets/images/truck_container.png';
    if (t.contains('tata_ace') || t.contains('bolero') || t.contains('10ft') || t.contains('14ft')) {
      return 'assets/images/truck_mini.png';
    }
    return 'assets/images/truck_large.png';
  }
}

class HandoverModel {
  final String id;
  final String shipmentId;
  final String? fromTransporterId;
  final String? toTransporterId;
  final String? handoverLocation;
  final String? goodsCondition;
  final String? remarks;
  final DateTime createdAt;

  HandoverModel({
    required this.id,
    required this.shipmentId,
    this.fromTransporterId,
    this.toTransporterId,
    this.handoverLocation,
    this.goodsCondition,
    this.remarks,
    required this.createdAt,
  });

  factory HandoverModel.fromJson(Map<String, dynamic> json) => HandoverModel(
    id: json['id'] as String,
    shipmentId: json['shipment_id'] as String,
    fromTransporterId: json['from_transporter_id'] as String?,
    toTransporterId: json['to_transporter_id'] as String?,
    handoverLocation: json['handover_location'] as String?,
    goodsCondition: json['goods_condition'] as String?,
    remarks: json['remarks'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}
