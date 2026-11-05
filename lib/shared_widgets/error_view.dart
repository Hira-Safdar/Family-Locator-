import 'package:flutter/material.dart';
import '../data/services/ads_service.dart';
import '../core/constants/app_strings.dart';

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          if (onRetry != null)
            TextButton(
              onPressed: () {
                AdsService.instance.registerInteraction();
                onRetry!();
              },
              child: Text(AppLocalizations.of(context).retry),
            ),
        ],
      ),
    );
  }
}
