import 'package:flutter_riverpod/flutter_riverpod.dart';

class CampaignBannerState {
  const CampaignBannerState({required this.title, required this.body});

  final String title;
  final String body;
}

class CampaignBannerNotifier extends Notifier<CampaignBannerState?> {
  @override
  CampaignBannerState? build() => null;

  void show({required String title, required String body}) {
    state = CampaignBannerState(title: title, body: body);
  }

  void dismiss() {
    state = null;
  }
}

final campaignBannerProvider =
    NotifierProvider<CampaignBannerNotifier, CampaignBannerState?>(
      CampaignBannerNotifier.new,
    );
