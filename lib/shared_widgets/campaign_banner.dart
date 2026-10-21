import 'dart:async';

import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

class CampaignBanner extends StatefulWidget {
  const CampaignBanner({
    super.key,
    required this.title,
    required this.body,
    required this.onDismiss,
  });

  final String title;
  final String body;
  final VoidCallback onDismiss;

  @override
  State<CampaignBanner> createState() => _CampaignBannerState();
}

class _CampaignBannerState extends State<CampaignBanner> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant CampaignBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.title != widget.title || oldWidget.body != widget.body) {
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 8), widget.onDismiss);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return TweenAnimationBuilder<Offset>(
      tween: Tween(begin: const Offset(0, -1), end: Offset.zero),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      builder: (context, offset, child) {
        return FractionalTranslation(translation: offset, child: child);
      },
      child: Material(
        color: palette.surface,
        elevation: 6,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.campaign_outlined, color: palette.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (widget.body.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(widget.body, style: const TextStyle(fontSize: 14)),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: widget.onDismiss,
                icon: const Icon(Icons.close),
                iconSize: 20,
                tooltip: 'Dismiss',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
