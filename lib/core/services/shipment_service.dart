import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/shipment_model.dart';

class ShipmentService {
  static final _client = Supabase.instance.client;

  // ── Manufacturer: get all shipments ───────────────────────
  static Future<List<ShipmentModel>> getManufacturerShipments(
    String userId,
  ) async {
    final data = await _client
        .from('shipments')
        .select('*')
        .eq('manufacturer_id', userId)
        .order('created_at', ascending: false);
    return (data as List).map((e) => ShipmentModel.fromJson(e)).toList();
  }

  // ── Manufacturer: create shipment ─────────────────────────
  static Future<ShipmentModel?> createShipment(
    Map<String, dynamic> payload,
  ) async {
    final res = await _client
        .from('shipments')
        .insert(payload)
        .select()
        .single();
    return ShipmentModel.fromJson(res);
  }

  // ── Get available truck types with enough capacity ────────
  static Future<List<Map<String, dynamic>>> getAvailableTrucksByCapacity(
    double minCapacityKg,
  ) async {
    try {
      final data = await _client
          .from('trucks')
          .select('truck_type, truck_label, capacity_kg')
          .gte('capacity_kg', minCapacityKg.toInt())
          .order('capacity_kg', ascending: true);
      final seen = <String>{};
      final result = <Map<String, dynamic>>[];
      for (final row in (data as List)) {
        final type = row['truck_type'] as String? ?? '';
        if (type.isNotEmpty && seen.add(type)) {
          result.add(Map<String, dynamic>.from(row as Map));
        }
      }
      return result;
    } catch (_) {
      return [];
    }
  }

  // ── Get status updates for a shipment ─────────────────────
  static Future<List<StatusUpdate>> getStatusUpdates(String shipmentId) async {
    final data = await _client
        .from('shipment_status_updates')
        .select('*')
        .eq('shipment_id', shipmentId)
        .order('created_at', ascending: true);
    return (data as List).map((e) => StatusUpdate.fromJson(e)).toList();
  }

  // ── Transporter: get assigned shipments ───────────────────
  static Future<List<Map<String, dynamic>>> getTransporterAssignments(
    String transporterId,
  ) async {
    final data = await _client
        .from('shipment_assignments')
        .select('*, shipments(*)')
        .eq('transporter_id', transporterId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data as List);
  }

  // ── Update shipment status (Transporter — NOT delivered) ──
  // Transporters can update status but CANNOT mark as delivered.
  // Only drivers can mark as delivered.
  static Future<void> updateShipmentStatus({
    required String shipmentId,
    required String status,
    required String updatedBy,
    String? note,
    String? city,
  }) async {
    // Guard: transporters cannot mark delivered
    if (status == 'delivered') {
      throw Exception('Only drivers can mark a shipment as delivered.');
    }

    // Check if already delivered — no further updates allowed
    final current = await _client
        .from('shipments')
        .select('status')
        .eq('id', shipmentId)
        .maybeSingle();
    if (current != null && current['status'] == 'delivered') {
      throw Exception(
        'Shipment already delivered. No further updates allowed.',
      );
    }

    await _client.from('shipment_status_updates').insert({
      'shipment_id': shipmentId,
      'updated_by': updatedBy,
      'status': status,
      'note': note,
      'city': city,
    });
    await _client
        .from('shipments')
        .update({
          'status': status,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', shipmentId);
  }

  // ── Mark shipment as delivered (DRIVER ONLY) ──────────────
  static Future<void> markDeliveredByDriver({
    required String shipmentId,
    required String driverId,
  }) async {
    // Verify shipment not already delivered
    final current = await _client
        .from('shipments')
        .select('status, driver_id')
        .eq('id', shipmentId)
        .maybeSingle();

    if (current == null) throw Exception('Shipment not found.');
    if (current['status'] == 'delivered') {
      throw Exception('Shipment already marked as delivered.');
    }

    // Insert status update
    await _client.from('shipment_status_updates').insert({
      'shipment_id': shipmentId,
      'updated_by': driverId,
      'status': 'delivered',
      'note': 'Marked delivered by driver',
    });

    // Update shipment
    await _client
        .from('shipments')
        .update({
          'status': 'delivered',
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', shipmentId);
  }

  // ── Create handover ───────────────────────────────────────
  static Future<void> createHandover({
    required String shipmentId,
    required String fromTransporterId,
    required String toTransporterId,
    String? handoverLocation,
    String? goodsCondition,
    String? remarks,
  }) async {
    await _client.from('handovers').insert({
      'shipment_id': shipmentId,
      'from_transporter_id': fromTransporterId,
      'to_transporter_id': toTransporterId,
      'handover_location': handoverLocation,
      'goods_condition': goodsCondition,
      'remarks': remarks,
    });
    await _client
        .from('shipments')
        .update({
          'current_transporter_id': toTransporterId,
          'status': 'handed_to_transporter',
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', shipmentId);
  }

  // ── Get all transporters (for handover selection) ─────────
  static Future<List<Map<String, dynamic>>> getAllTransporters() async {
    final data = await _client
        .from('transporters')
        .select('*')
        .eq('is_active', true);
    return List<Map<String, dynamic>>.from(data as List);
  }

  // ── Get transporter handovers ─────────────────────────────
  static Future<List<Map<String, dynamic>>> getHandovers(
    String transporterId,
  ) async {
    final data = await _client
        .from('handovers')
        .select('*')
        .or(
          'from_transporter_id.eq.$transporterId,to_transporter_id.eq.$transporterId',
        )
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data as List);
  }

  // ── Fetch transporter info for a shipment ─────────────────
  static Future<Map<String, dynamic>?> getTransporterById(String? trpId) async {
    if (trpId == null) return null;
    final data = await _client
        .from('transporters')
        .select()
        .eq('id', trpId)
        .maybeSingle();
    return data;
  }

  // ── Fetch trucks for transporter ──────────────────────────
  static Future<List<Map<String, dynamic>>> getTrucksForTransporter(
    String transporterId,
  ) async {
    final data = await _client
        .from('trucks')
        .select('*')
        .eq('transporter_id', transporterId);
    return List<Map<String, dynamic>>.from(data as List);
  }

  static Future<String?> getCurrentTransporterId() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final transporter = await _client
        .from('transporters')
        .select('id')
        .eq('user_id', user.id)
        .maybeSingle();
    return transporter?['id']?.toString();
  }

  // ── Search drivers — case-insensitive name, normalized phone ──
  // Returns list with '_match_type' and '_phone_exact_match' UI helpers.
  static Future<List<Map<String, dynamic>>> searchDrivers({
    String? name,
    String? phone,
    int limit = 30,
  }) async {
    if ((name == null || name.trim().isEmpty) &&
        (phone == null || phone.trim().isEmpty)) {
      return [];
    }

    final cleanName = name?.trim().toLowerCase();
    final cleanPhone = phone?.trim();
    final normalizedPhone = _digitsOnly(cleanPhone ?? '');

    final rowsById = <String, Map<String, dynamic>>{};
    final driverRows = await _client.from('drivers').select('*').limit(250);
    for (final row in driverRows as List) {
      final driver = Map<String, dynamic>.from(row as Map);
      final id = driver['id']?.toString() ?? '';
      if (id.isNotEmpty) rowsById[id] = driver;
    }

    final profileRows = await _client
        .from('profiles')
        .select('*')
        .eq('role', 'driver')
        .limit(250);
    for (final row in profileRows as List) {
      final profile = Map<String, dynamic>.from(row as Map);
      final id = profile['id']?.toString() ?? '';
      if (id.isEmpty) continue;
      rowsById[id] = {
        ...profile,
        ...?rowsById[id],
        'id': id,
        'full_name': rowsById[id]?['full_name'] ?? profile['full_name'],
        'phone': rowsById[id]?['phone'] ?? profile['phone'],
      };
    }

    final results = rowsById.values.where((driver) {
      final driverName = _driverName(driver).toLowerCase();
      final driverPhone = _digitsOnly(_driverPhone(driver));
      final nameMatches =
          cleanName != null &&
          cleanName.isNotEmpty &&
          driverName.contains(cleanName);
      final phoneMatches =
          normalizedPhone.isNotEmpty && driverPhone == normalizedPhone;
      final phonePartialMatches =
          normalizedPhone.isNotEmpty &&
          driverPhone.isNotEmpty &&
          (driverPhone.contains(normalizedPhone) ||
              normalizedPhone.contains(driverPhone));

      if (!nameMatches && !phoneMatches && !phonePartialMatches) {
        return false;
      }

      driver['_match_type'] =
          nameMatches && (phoneMatches || phonePartialMatches)
          ? 'both'
          : nameMatches
          ? 'name'
          : 'phone';
      driver['_phone_exact_match'] = phoneMatches;
      return true;
    }).toList();

    results.sort((a, b) {
      final aPhone = a['_phone_exact_match'] == true ? 0 : 1;
      final bPhone = b['_phone_exact_match'] == true ? 0 : 1;
      if (aPhone != bPhone) return aPhone.compareTo(bPhone);

      final aBoth = a['_match_type'] == 'both' ? 0 : 1;
      final bBoth = b['_match_type'] == 'both' ? 0 : 1;
      if (aBoth != bBoth) return aBoth.compareTo(bBoth);

      return _driverName(
        a,
      ).toLowerCase().compareTo(_driverName(b).toLowerCase());
    });
    return results.take(limit).toList();
  }

  // ── Assign driver details to a shipment ───────────────────
  static Future<void> assignDriverToShipment({
    required String shipmentId,
    String? driverId,
    String? driverName,
    String? driverPhone,
  }) async {
    if (driverId == null || driverId.trim().isEmpty) {
      throw Exception('Select a valid driver before assigning this shipment.');
    }

    await _client
        .from('shipments')
        .update({
          'driver_id': driverId.trim(),
          'driver_name': driverName?.trim(),
          'driver_phone': driverPhone?.trim(),
          'status': 'assigned',
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', shipmentId);

    // Insert status update
    await _client.from('shipment_status_updates').insert({
      'shipment_id': shipmentId,
      'updated_by': driverId.trim(),
      'status': 'assigned',
      'note': 'Driver assigned: ${driverName?.trim() ?? driverId.trim()}',
    });

    // The driver app reads assigned rides directly from shipments.
  }

  static Future<void> saveDriverToTransporterList({
    required String driverId,
    required String transporterId,
  }) async {
    final driver = await _client
        .from('drivers')
        .select('id, transporter_id')
        .eq('id', driverId)
        .maybeSingle();

    if (driver == null) {
      throw Exception('Driver record not found.');
    }

    final currentTransporterId = driver['transporter_id']?.toString().trim();
    if (currentTransporterId != null && currentTransporterId.isNotEmpty) {
      if (currentTransporterId == transporterId) return;
      throw Exception('This driver is already saved by another transporter.');
    }

    await _client
        .from('drivers')
        .update({'transporter_id': transporterId})
        .eq('id', driverId);
  }

  static String _digitsOnly(String value) =>
      value.replaceAll(RegExp(r'\D'), '');

  static String _driverName(Map<String, dynamic> driver) =>
      (driver['full_name'] ??
              driver['fullName'] ??
              driver['name'] ??
              driver['driver_name'] ??
              '')
          .toString()
          .trim();

  static String _driverPhone(Map<String, dynamic> driver) =>
      (driver['phone'] ??
              driver['phone_number'] ??
              driver['phoneNumber'] ??
              driver['driver_phone'] ??
              '')
          .toString()
          .trim();

  // ── Stream shipment for a driver (real-time) ──────────────
  static Stream<List<Map<String, dynamic>>> streamDriverShipments(
    String driverId,
  ) {
    if (driverId.isEmpty) return const Stream.empty();
    return _client
        .from('shipments')
        .stream(primaryKey: ['id'])
        .eq('driver_id', driverId)
        .map((rows) => List<Map<String, dynamic>>.from(rows));
  }

  // ── Stream single shipment (real-time updates) ────────────
  static Stream<Map<String, dynamic>?> streamShipment(String shipmentId) {
    return _client
        .from('shipments')
        .stream(primaryKey: ['id'])
        .eq('id', shipmentId)
        .map(
          (rows) => rows.isEmpty ? null : Map<String, dynamic>.from(rows.first),
        );
  }

  // ── Find driver by ID (for navigation details) ───────────
  static Future<Map<String, dynamic>?> getDriverById(String driverId) async {
    try {
      return await _client
          .from('drivers')
          .select('id, full_name, phone, age')
          .eq('id', driverId)
          .maybeSingle();
    } catch (_) {
      return null;
    }
  }
}
