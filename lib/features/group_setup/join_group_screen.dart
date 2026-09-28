import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/constants/app_config.dart';
import '../../core/errors/failure.dart';
import '../../providers/group_provider.dart';
import '../../shared_widgets/custom_button.dart';

class JoinGroupScreen extends ConsumerStatefulWidget {
  const JoinGroupScreen({super.key});

  @override
  ConsumerState<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends ConsumerState<JoinGroupScreen> {
  final _codeController = TextEditingController();
  String? _codeError;
  String? _serverError;

  Future<void> _scanQr() async {
    final scanned = await showDialog<String>(
      context: context,
      builder: (context) => const _ScanQrDialog(),
    );
    if (scanned != null && scanned.isNotEmpty) {
      _codeController.text = scanned;
      setState(() => _codeError = null);
      _submit();
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() {
        _codeError = 'Enter the invite code';
        _serverError = null;
      });
      return;
    }
    if (code.length != AppConfig.inviteCodelength) {
      setState(() {
        _codeError =
            'Code must be ${AppConfig.inviteCodelength} characters';
        _serverError = null;
      });
      return;
    }
    setState(() {
      _codeError = null;
      _serverError = null;
    });
    final controller = ref.read(groupControllerProvider.notifier);
    try {
      await controller.joinGroup(inviteCode: code);
      if (mounted) context.pop();
    } on Failure catch (e) {
      setState(() => _serverError = e.message);
    } catch (_) {
      setState(() => _serverError = 'Something went wrong. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(groupControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Join Group')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.group_add, size: 72),
              const SizedBox(height: 16),
              Text(
                'Ask a family member for their invite code',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _codeController,
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.done,
                maxLength: AppConfig.inviteCodelength,
                decoration: InputDecoration(
                  labelText: 'Invite code',
                  prefixIcon: const Icon(Icons.key),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.qr_code_scanner),
                    onPressed: _scanQr,
                  ),
                  errorText: _codeError,
                ),
                onChanged: (_) {
                  if (_codeError != null) setState(() => _codeError = null);
                },
                onSubmitted: (_) => _submit(),
              ),
              if (_serverError != null) ...[
                const SizedBox(height: 8),
                Text(
                  _serverError!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              CustomButton(
                label: 'Join Group',
                isLoading: state.isLoading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScanQrDialog extends StatefulWidget {
  const _ScanQrDialog();

  @override
  State<_ScanQrDialog> createState() => _ScanQrDialogState();
}

class _ScanQrDialogState extends State<_ScanQrDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: SizedBox(
        width: 300,
        height: 300,
        child: MobileScanner(
          onDetect: (capture) {
            final raw = capture.barcodes.isNotEmpty
                ? capture.barcodes.first.rawValue
                : null;
            if (raw != null && raw.isNotEmpty) {
              Navigator.pop(context, raw);
            }
          },
          errorBuilder: (context, error) {
            final denied =
                error.errorCode == MobileScannerErrorCode.permissionDenied;
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      denied ? Icons.no_photography : Icons.camera_alt,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      denied
                          ? 'Camera permission deny hai.\nPhone Settings > Family Locator > Camera allow karo, phir dobara try karo.'
                          : 'Camera open nahi ho saka (${error.errorCode.name}).',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}