import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/invite_share.dart';
import '../../shared_widgets/custom_button.dart';

class InviteScreen extends StatelessWidget {
  const InviteScreen({super.key, required this.code, required this.name});

  final String code;
  final String name;

  @override
  Widget build(BuildContext context) {
    final qrCode = QrCode.fromData(
      data: code,
      errorCorrectLevel: QrErrorCorrectLevel.M,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Invite Members')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.check_circle_outline,
                size: 72,
                color: AppColors.success,
              ),
              const SizedBox(height: 12),
              Text(
                'Group created!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(
                name,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Share this code or QR with the people you want to add.',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.textLight),
              ),
              const SizedBox(height: 24),
              Center(
                child: Container(
                  width: 200,
                  height: 200,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.black12, width: 2),
                  ),
                  child: CustomPaint(
                    painter: QrPainter.withQr(qr: qrCode, gapless: true),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: InkWell(
                  onTap: () => copyInviteCode(context, code),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          code,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: AppColors.primary,
                                letterSpacing: 4,
                              ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.copy,
                          size: 18,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  side: const BorderSide(color: AppColors.primary, width: 1.4),
                  foregroundColor: AppColors.primary,
                ),
                onPressed: () => copyInviteCode(context, code),
                icon: const Icon(Icons.copy),
                label: const Text('Copy code'),
              ),
              const SizedBox(height: 12),
              CustomButton(
                label: 'Share invite',
                onPressed: () => shareInvite(groupName: name, inviteCode: code),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go('/home'),
                child: const Text('Done'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
