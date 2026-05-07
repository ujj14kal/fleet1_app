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
  /// Returns unique truck_type rows from the trucks table where
  /// capacity_kg >= [minCapacityKg], sorted ascending by capacity.
  static Future<List<Map<String, dynamic>>> getAvailableTrucksByCapacity(double minCapacityKg) async {
    try {
      final data = await _client
          .from('trucks')
          .select('truck_type, truck_label, capacity_kg')
          .gte('capacity_kg', minCapacityKg.toInt())
          .order('capacity_kg', ascending: true);
      // Deduplicate by truck_type, keep one row per type
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

  // ── Update shipment status (Transporter) ──────────────────
  static Future<void> updateShipmentStatus({
    required String shipmentId,
    required String status,
    required String updatedBy,
    String? note,
    String? city,
  }) async {
    await _client.from('shipment_status_updates').insert({
      'shipment_id': shipmentId, 'updated_by': updatedBy,
      'status': status, 'note': note, 'city': city,
    });
    await _client.from('shipments').update({
      'status': status, 'updated_at': DateTime.now().toIso8601String(),
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

  // ── Find driver record by name or phone (search trucks/drivers records) ──
  static Future<Map<String, dynamic>?> findDriverByNameOrPhone({String? name, String? phone}) async {
    try {
      if ((name == null || name.isEmpty) && (phone == null || phone.isEmpty)) return null;
      // Prefer exact phone match when provided
      if (phone != null && phone.isNotEmpty) {
        final byPhone = await _client.from('drivers').select().eq('phone', phone).maybeSingle();
        if (byPhone != null) return Map<String, dynamic>.from(byPhone as Map);
      }
      // Fallback to name search (case-insensitive) against drivers.full_name
      if (name != null && name.isNotEmpty) {
        final rows = await _client.from('drivers').select().ilike('full_name', '%${name.replaceAll('%', '\%')}%').limit(10);
        if (rows != null && (rows as List).isNotEmpty) return Map<String, dynamic>.from(rows.first as Map);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // ── Search drivers by name or phone, returning multiple matches ──
  static Future<List<Map<String, dynamic>>> searchDrivers({String? name, String? phone, int limit = 20}) async {
    try {
      final results = <Map<String, dynamic>>[];
      if (phone != null && phone.isNotEmpty) {
        final byPhone = await _client.from('drivers').select().eq('phone', phone).maybeSingle();
        if (byPhone != null) results.add(Map<String, dynamic>.from(byPhone as Map));
      }
      if (name != null && name.isNotEmpty) {
        final rows = await _client.from('drivers').select().ilike('full_name', '%${name.replaceAll('%', '\%')}%').limit(limit);
        if (rows != null) {
          for (final r in rows as List) {
            final map = Map<String, dynamic>.from(r as Map);
            // avoid duplicate if same phone matched earlier
            if (!results.any((e) => e['id'] == map['id'])) results.add(map);
          }
        }
      }
      return results;
    } catch (_) {
      return [];
    }
  }

  // ── Assign driver details to a shipment and notify driver via DB insert ──
  static Future<void> assignDriverToShipment({
    required String shipmentId,
    String? driverId,
    String? driverName,
    String? driverPhone,
  }) async {
    // Update shipment with driver details
    await _client.from('shipments').update({
      'driver_id': driverId,
      'driver_name': driverName,
      'driver_phone': driverPhone,
      'status': 'assigned_to_driver',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', shipmentId);

    // Try inserting a notification row for drivers to pick up (best-effort)
    try {
      await _client.from('driver_notifications').insert({
        'shipment_id': shipmentId,
        'driver_id': driverId,
        'driver_phone': driverPhone,
        'driver_name': driverName,
        'message': 'You have been assigned a shipment',
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {
      // ignore if notifications table doesn't exist
    }
  }
}
