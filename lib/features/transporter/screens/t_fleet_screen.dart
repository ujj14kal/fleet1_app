import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/truck_model.dart';
import '../../../core/models/profile_model.dart';
import '../../../core/models/transporter_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/shipment_service.dart';
import '../../../shared/widgets/truck_asset_image.dart';

class TFleetTab extends StatefulWidget {
  const TFleetTab({super.key});
  @override
  State<TFleetTab> createState() => _TFleetTabState();
}

class _TFleetTabState extends State<TFleetTab> {
  ProfileModel? _profile;
  TransporterModel? _transporter;
  List<TruckModel> _trucks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _profile = await AuthService.getCurrentProfile();
    if (_profile == null) return;
    final trpData = await Supabase.instance.client
        .from('transporters')
        .select()
        .eq('user_id', _profile!.id)
        .maybeSingle();
    if (trpData != null) _transporter = TransporterModel.fromJson(trpData);
    if (_transporter != null) {
      final data = await ShipmentService.getTrucksForTransporter(
        _transporter!.id,
      );
      if (mounted)
        setState(() {
          _trucks = data.map((t) => TruckModel.fromJson(t)).toList();
          _loading = false;
        });
    } else {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryNavy,
        elevation: 0,
        title: Text(
          'My Fleet',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: AppColors.primaryAmber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                '${_trucks.length} Trucks',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryAmber,
                ),
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryAmber),
            )
          : _trucks.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.local_shipping_outlined,
                    size: 48,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No trucks registered',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Contact ops to add trucks to your fleet',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              color: AppColors.primaryAmber,
              onRefresh: _load,
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _trucks.length,
                itemBuilder: (_, i) => _TruckCard(truck: _trucks[i]),
              ),
            ),
    );
  }
}

class _TruckCard extends StatelessWidget {
  final TruckModel truck;
  const _TruckCard({required this.truck});

  @override
  Widget build(BuildContext context) {
    final isPartLoad = truck.loadCategory == 'part_load';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Truck image
          Expanded(
            child: Center(
              child: TruckAssetImage(
                asset: truck.imageAsset,
                scale: 1.32,
                fallbackSize: 54,
                fallbackColor: AppColors.primaryNavy,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            truck.displayName,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isPartLoad
                      ? AppColors.navyLight
                      : AppColors.greenLight,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  isPartLoad ? 'Part Load' : 'Full Load',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: isPartLoad
                        ? AppColors.primaryNavy
                        : AppColors.supportGreen,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                truck.capacityLabel,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (truck.truckNumber != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.numbers_rounded,
                  size: 11,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  truck.truckNumber!,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
