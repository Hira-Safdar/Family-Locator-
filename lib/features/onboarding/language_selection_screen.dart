import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/ad_units.dart';
import '../../core/constants/app_strings.dart';
import '../../data/services/ads_service.dart';
import '../../providers/settings_provider.dart';
import '../../shared_widgets/banner_ad_widget.dart';

class LanguageSelectionScreen extends ConsumerStatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  ConsumerState<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState
    extends ConsumerState<LanguageSelectionScreen> {
  String _language = 'English';

  @override
  void initState() {
    super.initState();
    _language = ref.read(settingsProvider).locale.languageCode == 'ur'
        ? 'Urdu'
        : 'English';
  }

  Future<void> _continue() async {
    ref.read(settingsProvider.notifier).setLanguage(_language);
    if (mounted) context.go('/premium');
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.chooseLanguage)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            strings.selectPreferredLanguage,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          RadioGroup<String>(
            groupValue: _language,
            onChanged: (value) {
              AdsService.instance.registerInteraction();
              setState(() => _language = value!);
            },
            child: Column(
              children: [
                for (final language in const ['English', 'Urdu'])
                  RadioListTile<String>(value: language, title: Text(language)),
              ],
            ),
          ),
          FilledButton(
            onPressed: _continue,
            child: Text(strings.continueLabel),
          ),
          const SizedBox(height: 24),
          const BannerAdWidget(adUnitId: AdUnits.languageBanner),
        ],
      ),
    );
  }
}
