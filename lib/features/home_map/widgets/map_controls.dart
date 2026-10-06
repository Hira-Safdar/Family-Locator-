import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import '../../../../core/constants/app_colors.dart';

class MapControls extends StatelessWidget {
  const MapControls({super.key, required this.controller});


  final MapController controller;

  @override
  Widget build(BuildContext context){
    return Column(
      children: [
        _roundButton(
          icon: Icons.add,
          onTap: () => controller.move(
            controller.camera.center,
            controller.camera.zoom + 1,
          ),
        ),
        const SizedBox(height: 8),
        _roundButton(
          icon: Icons.remove,
          onTap: () => controller.move(
            controller.camera.center,
            controller.camera.zoom -1,
          ),
        ),
        const SizedBox(height: 16),
        _roundButton(
          icon: Icons.navigation,
          onTap: () => controller.rotate(0),
        ),
      ],
    );
  }
  Widget _roundButton({required IconData icon, required VoidCallback onTap}){
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width:44,height: 44,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(color:Colors.black26,blurRadius:4, offset: Offset(0,2)),
          ],
        ),
        child:Icon(icon,color:AppColors.textDark),
      ),
    );
  }
}

