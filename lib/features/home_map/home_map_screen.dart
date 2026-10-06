import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

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
  static const LatLng _fallback = LatLng(30.3753, 69.3451);

  final MapController _mapController = MapController();
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
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(myLocationProvider, (prev, next) {
      final point = next.value;
      if (point != null && !_centered) {
        _centered = true;
        _mapController.move(
          LatLng(point.latitude, point.longitude),
          15,
        );
      }
    });

    final myPoint = ref.watch(myLocationProvider).value;
    final groupLocations =
        ref.watch(memberLocationsProvider).value ?? const {};
    final selfUid = ref.watch(authStateProvider).value;
    final hasGroup =
        (ref.watch(myGroupsStreamProvider).value ?? const []).isNotEmpty;
    final hasError = ref.watch(locationControllerProvider).hasError;

    final markers = <Marker>[];
    if (myPoint != null) {
      markers.add(Marker(
        point: LatLng(myPoint.latitude, myPoint.longitude),
        width: 44,
        height: 44,
        child: const Icon(
          Icons.person_pin_circle,
          color: Colors.blue,
          size: 44,
        ),
      ));
    }
    groupLocations.forEach((uid, point) {
      if (uid == selfUid) return;
      markers.add(Marker(
        point: LatLng(point.latitude, point.longitude),
        width: 40,
        height: 40,
        child: GestureDetector(
          onTap: () => showMemberSheet(
            context,
            uid: uid,
            point: point,
            myPosition: myPoint == null
                ? null
                : LatLng(myPoint.latitude, myPoint.longitude),
          ),
          child: const Icon(
            Icons.person_pin_circle,
            color: Colors.orange,
            size: 40,
          ),
        ),
      ));
    });

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: _fallback,
              initialZoom: 6,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.mylocator.familylocator',
              ),
              MarkerLayer(markers: markers),
            ],
          ),
          if (hasError)
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Material(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text('${ref.watch(locationControllerProvider).error}'),
                  ),
                ),
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
                    'No group yet — create or join one from the Groups tab.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'center',
        onPressed: _centerOnMe,
        child: const Icon(Icons.my_location),
      ),
    );
  }

  void _centerOnMe() {
    final point = ref.read(myLocationProvider).value;
    if (point == null) return;
    _mapController.move(
      LatLng(point.latitude, point.longitude),
      15,
    );
  }
}
