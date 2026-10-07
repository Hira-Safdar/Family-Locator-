import 'dart:async';

import 'package:flutter/material.dart';

import 'offline_view.dart';

class LoadingIndicator extends StatefulWidget {
  const LoadingIndicator({
    super.key,
    this.onRetry,
    this.timeout = const Duration(seconds: 10),
  });

  final VoidCallback? onRetry;
  final Duration timeout;

  @override
  State<LoadingIndicator> createState() => _LoadingIndicatorState();
}

class _LoadingIndicatorState extends State<LoadingIndicator> {
  Timer? _timer;
  bool _timedOut = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.timeout, () {
      if (mounted) setState(() => _timedOut = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_timedOut) {
      return const Center(child: CircularProgressIndicator());
    }
    return OfflineView(onRetry: widget.onRetry);
  }
}
