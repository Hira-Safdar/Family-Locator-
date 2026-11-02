import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/ad_units.dart';
import '../../core/constants/app_strings.dart';
import '../../shared_widgets/banner_ad_widget.dart';

class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.premiumTitle)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Icon(
            Icons.workspace_premium_outlined,
            size: 72,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 20),
          Text(
            strings.premiumHeadline,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Text(strings.premiumDescription, textAlign: TextAlign.center),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: () => context.go('/login'),
            child: Text(strings.continueFree),
          ),
          const SizedBox(height: 24),
          const BannerAdWidget(adUnitId: AdUnits.premiumBanner),
        ],
      ),
    );
  }
}
