import 'dart:convert';

import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.name,
    this.photoUrl,
    this.radius = 20,
  });

  final String name;
  final String? photoUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final image = _image();
    return CircleAvatar(
      radius: radius,
      backgroundColor: context.palette.primaryContainer,
      backgroundImage: image,
      child: image == null
          ? Text(
              name.isEmpty ? '?' : name[0].toUpperCase(),
              style: TextStyle(
                fontSize: radius * 0.8,
                fontWeight: FontWeight.w700,
                color: context.palette.primary,
              ),
            )
          : null,
    );
  }

  ImageProvider? _image() {
    final stored = photoUrl;
    if (stored == null || stored.isEmpty) return null;
    if (stored.startsWith('data:')) {
      final comma = stored.indexOf(',');
      if (comma == -1) return null;
      try {
        return MemoryImage(base64Decode(stored.substring(comma + 1)));
      } catch (_) {
        return null;
      }
    }
    return NetworkImage(stored);
  }
}
