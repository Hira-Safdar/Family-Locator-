import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({
    super.key,
    required this.adUnitId,
    this.collapsible = false,
  });

  final String adUnitId;
  final bool collapsible;

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _ad;
  bool _loaded = false;
  bool _loading = false;
  bool _collapsed = false;

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
      if (!mounted) return;
      final adSize = size ?? AdSize.banner;
      if (size == null) {
        debugPrint(
          'Adaptive banner size unavailable for ${widget.adUnitId}; '
          'using standard banner size.',
        );
      }
      final ad = BannerAd(
        size: adSize,
        adUnitId: widget.adUnitId,
        listener: BannerAdListener(
          onAdLoaded: (_) {
            if (mounted) setState(() => _loaded = true);
          },
          onAdFailedToLoad: (failedAd, error) {
            failedAd.dispose();
            debugPrint(
              'Banner ad failed to load (${widget.adUnitId}): '
              '${error.code} ${error.message}',
            );
            if (mounted) {
              setState(() {
                _ad = null;
                _loading = false;
              });
            }
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
      return const SizedBox.shrink();
    }
    if (_collapsed) {
      return Align(
        alignment: Alignment.centerRight,
        child: IconButton(
          tooltip: 'Show ad',
          icon: const Icon(Icons.expand_less),
          onPressed: () => setState(() => _collapsed = false),
        ),
      );
    }
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          SizedBox(
            height: ad.size.height.toDouble(),
            child: Center(
              child: SizedBox(
                width: ad.size.width.toDouble(),
                height: ad.size.height.toDouble(),
                child: AdWidget(ad: ad),
              ),
            ),
          ),
          if (widget.collapsible)
            IconButton(
              tooltip: 'Hide ad',
              icon: const Icon(Icons.expand_more),
              onPressed: () => setState(() => _collapsed = true),
            ),
        ],
      ),
    );
  }
}
