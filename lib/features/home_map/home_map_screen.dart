import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/location_point.dart';
import '../../providers/auth_provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/member_locations_provider.dart';
import 'widgets/member_bottom_sheet.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static final LatLng _fallback = LatLng(30.3753, 69.3451);

  GoogleMapController? _mapController;
  bool _centered = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(locationControllerProvider.notifier).start();
    });
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(myLocationProvider, (prev, next) {
      final point = next.value;
      final controller = _mapController;
      if (point != null && !_centered && controller != null) {
        _centered = true;
        controller.moveCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(point.latitude, point.longitude),
              zoom: 15,
            ),
          ),
        );
      }
    });

    final myPoint = ref.watch(myLocationProvider).value;
    final groupLocations =
        ref.watch(memberLocationsProvider).value ?? const {};
    final selfUid = ref.watch(authStateProvider).value;
    final groups = ref.watch(myGroupsStreamProvider).value ?? const [];
    final hasGroup = groups.isNotEmpty;
    final hasError = ref.watch(locationControllerProvider).hasError;

    final markers = <Marker>{};
    if (myPoint != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('me'),
          position: LatLng(myPoint.latitude, myPoint.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
        ),
      );
    }
    groupLocations.forEach((uid, point) {
      if (uid == selfUid) return;
      markers.add(
        Marker(
          markerId: MarkerId(uid),
          position: LatLng(point.latitude, point.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange,
          ),
          onTap: () => showMemberSheet(
            context,
            uid: uid,
            point: point,
            myPosition: myPoint == null
                ? null
                : LatLng(myPoint.latitude, myPoint.longitude),
          ),
        ),
      );
    });

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _fallback, zoom: 6),
            onMapCreated: (controller) => _mapController = controller,
            markers: markers,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: true,
          ),

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                height: 56,
                margin: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.family_restroom,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Live Tracking',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.person_add_alt_1),
                      color: AppColors.primary,
                      onPressed: () => context.go('/create-group'),
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (hasError)
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 84, 12, 12),
                child: Material(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      '${ref.watch(locationControllerProvider).error}',
                    ),
                  ),
                ),
              ),
            ),

          Positioned(
            right: 12,
            top: 100,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _zoomButton(Icons.add, () => _zoom(1)),
                const SizedBox(height: 8),
                _zoomButton(Icons.remove, () => _zoom(-1)),
              ],
            ),
          ),

          Positioned(
            right: 12,
            bottom: 96,
            child: FloatingActionButton(
              heroTag: 'center',
              mini: true,
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.textDark,
              onPressed: _centerOnMe,
              child: const Icon(Icons.my_location),
            ),
          ),

          if (!hasGroup)
            const Align(
              alignment: Alignment.center,
              child: Card(
                margin: EdgeInsets.all(24),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'No group yet - create or join one from the Groups tab.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),

          if (hasGroup && myPoint != null)
            Positioned(
              left: 12,
              right: 72,
              bottom: 84,
              child: _InfoCard(
                groupName: groups.first.name,
                memberCount: groups.first.memberIds.length,
                point: myPoint,
              ),
            ),

          if (hasGroup)
            Positioned(
              left: 12,
              right: 12,
              bottom: 16,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => context.go('/create-group'),
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text(
                  'Invite Members',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _zoom(int amount) {
    final controller = _mapController;
    if (controller == null) return;
    controller.moveCamera(
      amount > 0 ? CameraUpdate.zoomIn() : CameraUpdate.zoomOut(),
    );
  }

  void _centerOnMe() {
    final point = ref.read(myLocationProvider).value;
    final controller = _mapController;
    if (point == null || controller == null) return;
    controller.moveCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(point.latitude, point.longitude),
          zoom: 15,
        ),
      ),
    );
  }
}

Widget _zoomButton(IconData icon, VoidCallback onTap) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Icon(icon, color: AppColors.textDark),
    ),
  );
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.groupName,
    required this.memberCount,
    required this.point,
  });

  final String groupName;
  final int memberCount;
  final LocationPoint point;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primary,
                child: Icon(Icons.person, color: AppColors.onPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'You',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      'Last updated: ${DateFormatter.lastSeen(point.timestamp)}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),
              if (point.batteryLevel != null) _battery(point.batteryLevel!),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.background),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.group,
                size: 18,
                color: AppColors.textLight,
              ),
              const SizedBox(width: 8),
              Text(
                groupName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textDark,
                ),
              ),
              const Spacer(),
              Text(
                '$memberCount member${memberCount == 1 ? '' : 's'}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Widget _battery(int level) {
  final Color color = level > 40 ? AppColors.success : AppColors.error;
  final IconData icon =
      level > 40 ? Icons.battery_std : Icons.battery_alert;
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: color, size: 20),
      const SizedBox(width: 4),
      Text(
        '$level%',
        style: TextStyle(
          fontSize: 13,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );
}
