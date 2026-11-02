import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../core/constants/ad_units.dart';

class AdsService with WidgetsBindingObserver {
  static final AdsService instance = AdsService._();
  AdsService._();

  AppOpenAd? _appOpenAd;
  DateTime? _lastAppOpenShown;
  InterstitialAd? _interstitialAd;
  DateTime? _lastInterstitialShown;
  bool _isShowingAppOpen = false;

  Future<void> initialize() async {
    WidgetsBinding.instance.addObserver(this);
    await MobileAds.instance.initialize();
    _loadAppOpen();
    _loadInterstitial();
  }

  void _loadAppOpen() {
    AppOpenAd.load(
      adUnitId: AdUnits.appOpen,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _appOpenAd = null;
              _isShowingAppOpen = false;
              _loadAppOpen();
            },
            onAdFailedToShowFullScreenContent: (ad, _) {
              ad.dispose();
              _appOpenAd = null;
              _isShowingAppOpen = false;
              _loadAppOpen();
            },
          );
        },
        onAdFailedToLoad: (_) => _appOpenAd = null,
      ),
    );
  }

  void _loadInterstitial() {
    InterstitialAd.load(
      adUnitId: AdUnits.groupTransitionInterstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitialAd = null;
              _loadInterstitial();
            },
            onAdFailedToShowFullScreenContent: (ad, _) {
              ad.dispose();
              _interstitialAd = null;
              _loadInterstitial();
            },
          );
        },
        onAdFailedToLoad: (_) => _interstitialAd = null,
      ),
    );
  }

  void showAppOpenIfAllowed() {
    final ad = _appOpenAd;
    final now = DateTime.now();
    if (ad == null ||
        _isShowingAppOpen ||
        (_lastAppOpenShown != null &&
            now.difference(_lastAppOpenShown!) < const Duration(minutes: 5))) {
      return;
    }
    _isShowingAppOpen = true;
    _lastAppOpenShown = now;
    ad.show();
  }

  void showInterstitialIfAllowed() {
    final ad = _interstitialAd;
    final now = DateTime.now();
    if (ad == null ||
        (_lastInterstitialShown != null &&
            now.difference(_lastInterstitialShown!) <
                const Duration(minutes: 10))) {
      return;
    }
    _lastInterstitialShown = now;
    _interstitialAd = null;
    ad.show();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      showAppOpenIfAllowed();
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _appOpenAd?.dispose();
    _interstitialAd?.dispose();
  }

  static void logAdError(Object error) {
    if (kDebugMode) debugPrint('Ad error: $error');
  }
}
