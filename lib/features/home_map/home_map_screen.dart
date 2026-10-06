import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
    final hasGroup =
        (ref.watch(myGroupsStreamProvider).value ?? const []).isNotEmpty;
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
            initialCameraPosition: CameraPosition(
              target: _fallback,
              zoom: 6,
            ),
            onMapCreated: (controller) => _mapController = controller,
            markers: markers,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: true,
            scrollGesturesEnabled: true,
            zoomGesturesEnabled: true,
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
