import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/constants/app_colors.dart';

class MapControls extends StatelessWidget {
  const MapControls({super.key, required this.controller});

  final GoogleMapController? controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _roundButton(
          icon: Icons.add,
          onTap: () => _zoom(1),
        ),
        const SizedBox(height: 8),
        _roundButton(
          icon: Icons.remove,
          onTap: () => _zoom(-1),
        ),
      ],
    );
  }

  void _zoom(int amount) {
    final update = amount > 0
        ? CameraUpdate.zoomIn()
        : CameraUpdate.zoomOut();
    controller?.moveCamera(update);
  }

  Widget _roundButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        child: Icon(icon, color: AppColors.textDark),
      ),
    );
  }
}
