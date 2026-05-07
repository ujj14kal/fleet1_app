import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/shipment_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/session_service.dart';
import '../../../shared/widgets/truck_loader.dart';

class TAssignDriverTab extends StatefulWidget {
  const TAssignDriverTab({super.key});

  @override
  State<TAssignDriverTab> createState() => _TAssignDriverTabState();
}

class _TAssignDriverTabState extends State<TAssignDriverTab> {
  List<Map<String, dynamic>> _assignments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    await SessionService.touch();
    final profile = await AuthService.getCurrentProfile();
    if (profile == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    try {
      final transporter = await Supabase.instance.client
          .from('transporters')
          .select('id')
          .eq('user_id', profile.id)
          .maybeSingle();

      if (transporter == null) {
        _assignments = [];
      } else {
        final assignments = await ShipmentService.getTransporterAssignments(
          transporter['id'] as String,
        );
        _assignments = assignments.where((assignment) {
          final shipment = assignment['shipments'] as Map<String, dynamic>?;
          if (shipment == null) return false;
          final driverId = shipment['driver_id']?.toString().trim() ?? '';
          final driverName = shipment['driver_name']?.toString().trim() ?? '';
          final driverPhone = shipment['driver_phone']?.toString().trim() ?? '';
          final status = shipment['status']?.toString() ?? '';
          return driverId.isEmpty &&
              driverName.isEmpty &&
              driverPhone.isEmpty &&
              status != 'delivered' &&
              status != 'cancelled';
        }).toList();
      }
    } catch (_) {
      _assignments = [];
    }
    if (mounted) setState(() => _loading = false);
  }

  void _showAssignModal(Map<String, dynamic> shipment) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    List<Map<String, dynamic>> matches = [];
    Map<String, dynamic>? selected;
    bool searching = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Assign Driver',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  shipment['shipment_code'] ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.primaryAmber,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    hintText: 'Driver full name',
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: 'Driver phone number',
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.phone_iphone),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        final name = nameCtrl.text.trim();
                        final phone = phoneCtrl.text.trim();
                        if (name.isEmpty && phone.isEmpty) return;
                        setModal(() => searching = true);
                        final res = await ShipmentService.searchDrivers(
                          name: name.isEmpty ? null : name,
                          phone: phone.isEmpty ? null : phone,
                        );
                        setModal(() {
                          searching = false;
                          matches = res;
                          if (matches.isNotEmpty) selected = matches.first;
                        });
                      },
                      icon: const Icon(Icons.search),
                      label: const Text('Search'),
                    ),
                    const SizedBox(width: 12),
                    if (searching)
                      const TruckLoaderCompact(width: 72, height: 32),
                  ],
                ),
                const SizedBox(height: 12),
                if (matches.isNotEmpty) ...[
                  Text(
                    'Matches',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: matches.length > 3
                        ? 180
                        : (matches.length * 56).toDouble(),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: matches.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (_, idx) {
                        final m = matches[idx];
                        final nameText =
                            (m['full_name'] ?? m['fullName'] ?? '—') as String;
                        final phoneText =
                            (m['phone'] ?? m['phoneNumber'] ?? '—') as String;
                        final isSel =
                            selected != null && selected!['id'] == m['id'];
                        return ListTile(
                          selected: isSel,
                          leading: CircleAvatar(
                            child: Text(
                              nameText.isNotEmpty
                                  ? nameText[0].toUpperCase()
                                  : '?',
                            ),
                          ),
                          title: Text(
                            nameText,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: Text(
                            phoneText,
                            style: GoogleFonts.inter(fontSize: 12),
                          ),
                          onTap: () => setModal(() => selected = m),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: selected == null
                        ? null
                        : () async {
                            Navigator.pop(ctx);
                            await ShipmentService.assignDriverToShipment(
                              shipmentId: shipment['id'] as String,
                              driverId: selected!['id'] as String?,
                              driverName:
                                  (selected!['full_name'] ??
                                          selected!['fullName'])
                                      as String?,
                              driverPhone:
                                  (selected!['phone'] ??
                                          selected!['phoneNumber'])
                                      as String?,
                            );
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Driver assigned')),
                            );
                            await _load();
                          },
                    child: const Text('Confirm assignment'),
                  ),
                ] else ...[
                  const SizedBox.shrink(),
                ],
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Assign Driver'),
        backgroundColor: AppColors.primaryNavy,
      ),
      body: _loading
          ? const Center(child: TruckLoader(message: 'Loading shipments...'))
          : RefreshIndicator(
              color: AppColors.primaryAmber,
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _assignments.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (_, i) {
                  final s =
                      _assignments[i]['shipments'] as Map<String, dynamic>?;
                  if (s == null) return const SizedBox.shrink();
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              s['shipment_code'] ??
                                  (s['id'] as String)
                                      .substring(0, 8)
                                      .toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryAmber,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              s['status'] ?? '',
                              style: GoogleFonts.inter(fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${s['pickup_city'] ?? '—'} → ${s['receiver_city'] ?? '—'}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Spacer(),
                            ElevatedButton(
                              onPressed: () => _showAssignModal(s),
                              child: const Text('Assign Driver'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}
