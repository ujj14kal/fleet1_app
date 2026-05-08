import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/shipment_model.dart';

class ShipmentService {
  static final _client = Supabase.instance.client;

  // ── Manufacturer: get all shipments ───────────────────────
  static Future<List<ShipmentModel>> getManufacturerShipments(String userId) async {
    final data = await _client
        .from('shipments')
        .select('*')
        .eq('manufacturer_id', userId)
        .order('created_at', ascending: false);
    return (data as List).map((e) => ShipmentModel.fromJson(e)).toList();
  }

  // ── Manufacturer: create shipment ─────────────────────────
  static Future<ShipmentModel?> createShipment(Map<String, dynamic> payload) async {
    final res = await _client.from('shipments').insert(payload).select().single();
    return ShipmentModel.fromJson(res);
  }

  // ── Get available truck types with enough capacity ────────
  static Future<List<Map<String, dynamic>>> getAvailableTrucksByCapacity(double minCapacityKg) async {
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
  static Future<List<Map<String, dynamic>>> getTransporterAssignments(String transporterId) async {
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
      throw Exception('Shipment already delivered. No further updates allowed.');
    }

    await _client.from('shipment_status_updates').insert({
      'shipment_id': shipmentId,
      'updated_by': updatedBy,
      'status': status,
      'note': note,
      'city': city,
    });
    await _client.from('shipments').update({
      'status': status,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', shipmentId);
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
    await _client.from('shipments').update({
      'status': 'delivered',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', shipmentId);
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
    await _client.from('shipments').update({
      'current_transporter_id': toTransporterId,
      'status': 'handed_to_transporter',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', shipmentId);
  }

  // ── Get all transporters (for handover selection) ─────────
  static Future<List<Map<String, dynamic>>> getAllTransporters() async {
    final data = await _client.from('transporters').select('*').eq('is_active', true);
    return List<Map<String, dynamic>>.from(data as List);
  }

  // ── Get transporter handovers ─────────────────────────────
  static Future<List<Map<String, dynamic>>> getHandovers(String transporterId) async {
    final data = await _client
        .from('handovers')
        .select('*')
        .or('from_transporter_id.eq.$transporterId,to_transporter_id.eq.$transporterId')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data as List);
  }

  // ── Fetch transporter info for a shipment ─────────────────
  static Future<Map<String, dynamic>?> getTransporterById(String? trpId) async {
    if (trpId == null) return null;
    final data = await _client.from('transporters').select().eq('id', trpId).maybeSingle();
    return data;
  }

  // ── Fetch trucks for transporter ──────────────────────────
  static Future<List<Map<String, dynamic>>> getTrucksForTransporter(String transporterId) async {
    final data = await _client.from('trucks').select('*').eq('transporter_id', transporterId);
    return List<Map<String, dynamic>>.from(data as List);
  }

  // ── Search drivers — case-insensitive, matches name OR phone ──
  // Returns list with a 'match_type' key: 'name', 'phone', or 'both'
  static Future<List<Map<String, dynamic>>> searchDrivers({
    String? name,
    String? phone,
    int limit = 30,
  }) async {
    try {
      if ((name == null || name.trim().isEmpty) &&
          (phone == null || phone.trim().isEmpty)) {
        return [];
      }

      final results = <Map<String, dynamic>>[];
      final seenIds = <String>{};

      // ── Phone match (exact, trimmed) ──────────────────────
      if (phone != null && phone.trim().isNotEmpty) {
        final cleanPhone = phone.trim();
        final byPhone = await _client
            .from('drivers')
            .select('id, full_name, phone, age')
            .eq('phone', cleanPhone)
            .limit(limit);
        for (final r in byPhone as List) {
          final map = Map<String, dynamic>.from(r as Map);
          final id = map['id']?.toString() ?? '';
          if (id.isNotEmpty && seenIds.add(id)) {
            map['_match_type'] = 'phone';
            results.add(map);
          }
        }
      }

      // ── Name match (case-insensitive, partial) ────────────
      if (name != null && name.trim().isNotEmpty) {
        final cleanName = name.trim();
        // Use ilike for case-insensitive LIKE
        final byName = await _client
            .from('drivers')
            .select('id, full_name, phone, age')
            .ilike('full_name', '%$cleanName%')
            .limit(limit);
        for (final r in byName as List) {
          final map = Map<String, dynamic>.from(r as Map);
          final id = map['id']?.toString() ?? '';
          if (id.isNotEmpty) {
            if (seenIds.contains(id)) {
              // Already found by phone — upgrade match_type to 'both'
              final idx = results.indexWhere((e) => e['id']?.toString() == id);
              if (idx >= 0) results[idx]['_match_type'] = 'both';
            } else {
              seenIds.add(id);
              map['_match_type'] = 'name';
              results.add(map);
            }
          }
        }
      }

      return results;
    } catch (e) {
      return [];
    }
  }

  // ── Assign driver details to a shipment ───────────────────
  static Future<void> assignDriverToShipment({
    required String shipmentId,
    String? driverId,
    String? driverName,
    String? driverPhone,
  }) async {
    await _client.from('shipments').update({
      'driver_id': driverId,
      'driver_name': driverName,
      'driver_phone': driverPhone,
      'status': 'assigned',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', shipmentId);

    // Insert status update
    await _client.from('shipment_status_updates').insert({
      'shipment_id': shipmentId,
      'updated_by': driverId ?? driverName,
      'status': 'assigned',
      'note': 'Driver assigned: $driverName',
    });

    // Notify driver via driver_notifications table (best-effort)
    try {
      await _client.from('driver_notifications').insert({
        'shipment_id': shipmentId,
        'driver_id': driverId,
        'driver_phone': driverPhone,
        'driver_name': driverName,
        'message': 'You have been assigned a new shipment. Tap to view details.',
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }

  // ── Stream shipment for a driver (real-time) ──────────────
  static Stream<List<Map<String, dynamic>>> streamDriverShipments(String driverId) {
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
        .map((rows) => rows.isEmpty ? null : Map<String, dynamic>.from(rows.first));
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