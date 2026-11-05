import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../core/constants/ad_units.dart';

class AdsService with WidgetsBindingObserver {
  static final AdsService instance = AdsService._();
  static const _interactionAdCooldown = Duration(seconds: 55);
  AdsService._();

  AppOpenAd? _appOpenAd;
  DateTime? _lastAppOpenShown;
  InterstitialAd? _interstitialAd;
  InterstitialAd? _interactionInterstitialAd;
  DateTime? _lastInterstitialShown;
  DateTime? _lastInteractionInterstitialShown;
  DateTime? _lastFullscreenAdClosed;
  int _interactionCount = 0;
  int _interactionTarget = 2;
  final Random _random = Random();
  bool _isShowingAppOpen = false;

  Future<void> initialize() async {
    WidgetsBinding.instance.addObserver(this);
    await MobileAds.instance.initialize();
    _loadAppOpen();
    _loadInterstitial();
    _loadInteractionInterstitial();
  }

  void _loadInteractionInterstitial() {
    InterstitialAd.load(
      adUnitId: AdUnits.interactionInterstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interactionInterstitialAd = ad;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interactionInterstitialAd = null;
              _lastFullscreenAdClosed = DateTime.now();
              _loadInteractionInterstitial();
            },
            onAdFailedToShowFullScreenContent: (ad, _) {
              ad.dispose();
              _interactionInterstitialAd = null;
              _lastFullscreenAdClosed = DateTime.now();
              _loadInteractionInterstitial();
            },
          );
        },
        onAdFailedToLoad: (error) {
          _interactionInterstitialAd = null;
          logAdError(
            'Interaction interstitial failed (${error.code}): '
            '${error.message}',
          );
        },
      ),
    );
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
              _lastFullscreenAdClosed = DateTime.now();
              _loadAppOpen();
            },
            onAdFailedToShowFullScreenContent: (ad, _) {
              ad.dispose();
              _appOpenAd = null;
              _isShowingAppOpen = false;
              _lastFullscreenAdClosed = DateTime.now();
              _loadAppOpen();
            },
          );
        },
        onAdFailedToLoad: (error) {
          _appOpenAd = null;
          logAdError('App-open ad failed (${error.code}): ${error.message}');
        },
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
              _lastFullscreenAdClosed = DateTime.now();
              _loadInterstitial();
            },
            onAdFailedToShowFullScreenContent: (ad, _) {
              ad.dispose();
              _interstitialAd = null;
              _lastFullscreenAdClosed = DateTime.now();
              _loadInterstitial();
            },
          );
        },
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
          logAdError('Interstitial failed (${error.code}): ${error.message}');
        },
      ),
    );
  }

  void showAppOpenIfAllowed() {
    final ad = _appOpenAd;
    final now = DateTime.now();
    if (ad == null ||
        _isShowingAppOpen ||
        (_lastFullscreenAdClosed != null &&
            now.difference(_lastFullscreenAdClosed!) <
                const Duration(seconds: 10)) ||
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

  void registerInteraction() {
    _interactionCount++;
    if (_interactionCount < _interactionTarget) return;
    _interactionCount = 0;
    _interactionTarget = 2 + _random.nextInt(2);
    _showInteractionInterstitialIfAllowed();
  }

  void _showInteractionInterstitialIfAllowed() {
    final ad = _interactionInterstitialAd;
    final now = DateTime.now();
    if (ad == null ||
        (_lastInteractionInterstitialShown != null &&
            now.difference(_lastInteractionInterstitialShown!) <
                _interactionAdCooldown)) {
      return;
    }
    _lastInteractionInterstitialShown = now;
    _interactionInterstitialAd = null;
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
    _interactionInterstitialAd?.dispose();
  }

  static void logAdError(Object error) {
    if (kDebugMode) debugPrint('Ad error: $error');
  }
}
