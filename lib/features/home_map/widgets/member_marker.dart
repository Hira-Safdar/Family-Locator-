import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class MemberMarker extends StatelessWidget {
  const MemberMarker({
    super.key,
    required this.name,
    required this.isMe,
  });

  final String name;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: isMe ? AppColors.primary : AppColors.secondary,
          child: Text(
            _initial,
              style: TextStyle(
              color: isMe ? AppColors.onPrimary : AppColors.onSecondary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
          ),
          child: Text(name, style: const TextStyle(fontSize: 11)),
        ),
      ],
    );
  }

  String get _initial {
    if (name.trim().isEmpty) return '?';
    return name.trim()[0].toUpperCase();
  }
}