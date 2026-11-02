import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key, required this.adUnitId});

  final String adUnitId;

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  static const _reservedHeight = 100.0;

  BannerAd? _ad;
  bool _loaded = false;
  bool _loading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ad != null || _loading) return;
    _loading = true;
    final width = MediaQuery.sizeOf(context).width.truncate();
    AdSize.getLargeAnchoredAdaptiveBannerAdSizeWithOrientation(
      Orientation.portrait,
      width,
    ).then((size) {
      if (!mounted || size == null) return;
      final ad = BannerAd(
        size: size,
        adUnitId: widget.adUnitId,
        listener: BannerAdListener(
          onAdLoaded: (_) {
            if (mounted) setState(() => _loaded = true);
          },
        ),
        request: const AdRequest(),
      );
      _ad = ad;
      ad.load();
    });
  }

  @override
  void didUpdateWidget(covariant BannerAdWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.adUnitId == widget.adUnitId) return;
    _ad?.dispose();
    _ad = null;
    _loaded = false;
    _loading = false;
    didChangeDependencies();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (!_loaded || ad == null) {
      return const SizedBox(height: _reservedHeight);
    }
    return SizedBox(
      height: _reservedHeight,
      child: Center(
        child: SizedBox(
          width: ad.size.width.toDouble(),
          height: ad.size.height.toDouble(),
          child: AdWidget(ad: ad),
        ),
      ),
    );
  }
}
