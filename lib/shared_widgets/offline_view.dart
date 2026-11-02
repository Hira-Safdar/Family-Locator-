import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';

class OfflineView extends StatelessWidget {
  const OfflineView({super.key, this.onRetry, this.title, this.subtitle});

  final VoidCallback? onRetry;
  final String? title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off, size: 64, color: context.palette.textLight),
            const SizedBox(height: 16),
            Text(
              title ?? AppLocalizations.of(context).noInternet,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle ?? AppLocalizations.of(context).checkConnection,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: context.palette.textLight,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: context.palette.primary),
                  foregroundColor: context.palette.primary,
                ),
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(AppLocalizations.of(context).tryAgain),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
