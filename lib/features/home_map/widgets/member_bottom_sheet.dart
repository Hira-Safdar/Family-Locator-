import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng;

import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/distance_calculator.dart';
import '../../../data/models/location_point.dart';

Future<void> showMemberSheet(
  BuildContext context, {
  required String uid,
  required LocationPoint point,
  LatLng? myPosition,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 22,
                    child: Icon(Icons.person),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Member ${uid.substring(uid.length - 4).toUpperCase()}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _InfoRow(
                icon: Icons.schedule,
                label: 'Last seen',
                value: DateFormatter.lastSeen(point.timestamp),
              ),
              if (myPosition != null)
                _InfoRow(
                  icon: Icons.straighten,
                  label: 'Distance',
                  value: DistanceCalculator.labelBetween(
                    myPosition.latitude,
                    myPosition.longitude,
                    point.latitude,
                    point.longitude,
                  ),
                ),
              if (point.accuracy != null)
                _InfoRow(
                  icon: Icons.gps_fixed,
                  label: 'Accuracy',
                  value: '${point.accuracy!.round()} m',
                ),
              if (point.batteryLevel != null)
                _InfoRow(
                  icon: Icons.battery_std,
                  label: 'Battery',
                  value: '${point.batteryLevel}%',
                ),
            ],
          ),
        ),
      );
    },
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 10),
          Text(label),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}