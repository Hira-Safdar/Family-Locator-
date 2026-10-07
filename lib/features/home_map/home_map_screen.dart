import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../core/errors/failure.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/distance_calculator.dart';
import '../../data/models/group_model.dart';
import '../../data/models/location_point.dart';
import '../../providers/auth_provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/member_locations_provider.dart';
import '../../shared_widgets/loading_indicator.dart';
import '../../shared_widgets/offline_view.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static final LatLng _fallback = LatLng(30.3753, 69.3451);

  GoogleMapController? _mapController;
  bool _centered = false;
  String? _selectedUid;
  LocationPoint? _selectedPoint;

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

  void _nextGroup(List<GroupModel> groups) {
    if (groups.isEmpty) return;
    final currentId = ref.read(selectedGroupIdProvider);
    final index = groups.indexWhere((g) => g.id == currentId);
    final next = groups[(index + 1) % groups.length];
    setState(() {
      _selectedUid = null;
      _selectedPoint = null;
    });
    ref.read(selectedGroupIdProvider.notifier).select(next.id);
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
    final locationsAsync = ref.watch(memberLocationsProvider);
    final groupLocations = locationsAsync.value ?? const {};
    final selfUid = ref.watch(authStateProvider).value;
    final groupsAsync = ref.watch(myGroupsStreamProvider);
    final groups = groupsAsync.value ?? const <GroupModel>[];
    final hasGroup = groups.isNotEmpty;
    final locationError = ref.watch(locationControllerProvider);
    final hasError = locationError.hasError || locationsAsync.hasError;
    final selectedGroupId = ref.watch(selectedGroupIdProvider);

    GroupModel? activeGroup;
    if (hasGroup) {
      activeGroup = groups.firstWhere(
        (g) => g.id == selectedGroupId,
        orElse: () => groups.first,
      );
    }

    final placed = <LatLng>[
      if (myPoint != null) LatLng(myPoint.latitude, myPoint.longitude),
    ];
    final markers = <Marker>{};
    if (myPoint != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('me'),
          position: placed.first,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
          zIndexInt: 1,
        ),
      );
    }
    groupLocations.forEach((uid, point) {
      if (uid == selfUid) return;
      final selected = uid == _selectedUid;
      final position = _spread(
        LatLng(point.latitude, point.longitude),
        placed,
      );
      placed.add(position);
      markers.add(
        Marker(
          markerId: MarkerId(uid),
          position: position,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            selected ? BitmapDescriptor.hueRed : BitmapDescriptor.hueOrange,
          ),
          zIndexInt: selected ? 3 : 2,
          onTap: () => setState(() {
            _selectedUid = uid;
            _selectedPoint = point;
          }),
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
                    Text(
                      'Live Tracking',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
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
                      locationError.hasError
                          ? (locationError.error is Failure
                              ? (locationError.error as Failure).message
                              : 'Something went wrong. Please check your internet connection and try again.')
                          : 'Could not load member locations. Please check your internet connection and try again.',
                    ),
                  ),
                ),
              ),
            ),

          if (groupsAsync.isLoading)
            Align(
              alignment: Alignment.center,
              child: LoadingIndicator(
                onRetry: () => ref.invalidate(myGroupsStreamProvider),
              ),
            )
          else if (groupsAsync.hasError)
            Align(
              alignment: Alignment.center,
              child: OfflineView(
                onRetry: () => ref.invalidate(myGroupsStreamProvider),
              ),
            )
          else if (!hasGroup)
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

          if (activeGroup != null)
            Positioned(
              left: 12,
              right: 68,
              bottom: 16,
              child: _selectedUid != null && _selectedPoint != null
                  ? _memberBox(groups, _selectedUid!, _selectedPoint!, myPoint)
                  : _groupBox(groups, activeGroup, myPoint),
            ),

          Positioned(
            right: 12,
            bottom: 16,
            child: FloatingActionButton(
              heroTag: 'center',
              mini: true,
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.textDark,
              tooltip: 'My location',
              onPressed: _centerOnMe,
              child: const Icon(Icons.my_location),
            ),
          ),
        ],
      ),
    );
  }

  void _centerOnMe() {
    final controller = _mapController;
    if (controller == null) return;
    final myPoint = ref.read(myLocationProvider).value;
    if (myPoint == null) return;
    controller.moveCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(myPoint.latitude, myPoint.longitude),
          zoom: 15,
        ),
      ),
    );
  }

  static const List<Offset> _ring = [
    Offset(0.0005, 0),
    Offset(-0.0005, 0),
    Offset(0, 0.0005),
    Offset(0, -0.0005),
    Offset(0.0005, 0.0005),
    Offset(-0.0005, -0.0005),
    Offset(0.0005, -0.0005),
    Offset(-0.0005, 0.0005),
  ];

  LatLng _spread(LatLng base, List<LatLng> placed) {
    if (!_hits(base, placed)) return base;
    for (final off in _ring) {
      final cand = LatLng(base.latitude + off.dx, base.longitude + off.dy);
      if (!_hits(cand, placed)) return cand;
    }
    return base;
  }

  bool _hits(LatLng point, List<LatLng> placed) {
    for (final other in placed) {
      final meters = DistanceCalculator.metersBetween(
        point.latitude,
        point.longitude,
        other.latitude,
        other.longitude,
      );
      if (meters < 45) return true;
    }
    return false;
  }

  Widget _groupBox(
    List<GroupModel> groups,
    GroupModel active,
    LocationPoint? myPoint,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primaryContainer,
                child: Icon(Icons.group, size: 20, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      active.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '${active.memberIds.length} '
                      'member${active.memberIds.length == 1 ? '' : 's'}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Next group',
                icon: const Icon(Icons.chevron_right, size: 30),
                color: AppColors.primary,
                onPressed: () => _nextGroup(groups),
              ),
            ],
          ),
          if (myPoint != null) ...[
            const SizedBox(height: 10),
            const Divider(height: 1, color: AppColors.background),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.person, size: 18, color: AppColors.textLight),
                const SizedBox(width: 8),
                const Text(
                  'You',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                const Spacer(),
                Text(
                  'Updated ${DateFormatter.lastSeen(myPoint.timestamp)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _memberBox(
    List<GroupModel> groups,
    String uid,
    LocationPoint point,
    LocationPoint? myPoint,
  ) {
    final shortId = uid.substring(uid.length - 4).toUpperCase();
    final name = ref.watch(userNameProvider(uid)).value ?? 'Member $shortId';
    final memberGroups =
        ref.watch(memberGroupsProvider(uid)).value ?? const <GroupModel>[];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 260),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 18,
                    child: Icon(Icons.person, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Next group',
                    icon: const Icon(Icons.chevron_right, size: 30),
                    color: AppColors.primary,
                    onPressed: () => _nextGroup(groups),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              _infoRow(
                Icons.schedule,
                'Last seen',
                DateFormatter.lastSeen(point.timestamp),
              ),
              if (myPoint != null)
                _infoRow(
                  Icons.straighten,
                  'Distance',
                  DistanceCalculator.labelBetween(
                    myPoint.latitude,
                    myPoint.longitude,
                    point.latitude,
                    point.longitude,
                  ),
                ),
              if (point.accuracy != null)
                _infoRow(
                  Icons.gps_fixed,
                  'Accuracy',
                  '${point.accuracy!.round()} m',
                ),
              if (point.batteryLevel != null)
                _infoRow(
                  Icons.battery_std,
                  'Battery',
                  '${point.batteryLevel}%',
                ),
              const SizedBox(height: 10),
              const Divider(height: 1, color: AppColors.background),
              const SizedBox(height: 10),
              const Text(
                'MEMBER OF',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textLight,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 6),
              if (memberGroups.isEmpty)
                const Text(
                  'No groups found',
                  style: TextStyle(fontSize: 13, color: AppColors.textLight),
                ),
              for (final g in memberGroups)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.group_outlined,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          g.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      Text(
                        '${g.memberIds.length} '
                        'member${g.memberIds.length == 1 ? '' : 's'}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppColors.textLight),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration get _cardDecoration => BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      );
}
