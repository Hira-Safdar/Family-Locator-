import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/invite_share.dart';
import '../../core/constants/app_strings.dart';
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
    final strings = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(strings.inviteMembers)),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 680;
            final qrSize = compact ? 148.0 : 176.0;
            final gap = compact ? 6.0 : 10.0;
            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 16 : 24,
                vertical: compact ? 8 : 16,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: compact ? 52 : 64,
                    color: context.palette.success,
                  ),
                  SizedBox(height: gap),
                  Text(
                    strings.groupCreated,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  SizedBox(height: gap / 2),
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  SizedBox(height: gap),
                  Text(
                    strings.shareCode,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: context.palette.textLight,
                    ),
                  ),
                  SizedBox(height: compact ? 10 : 18),
                  Center(
                    child: Container(
                      width: qrSize,
                      height: qrSize,
                      padding: const EdgeInsets.all(8),
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
                  SizedBox(height: compact ? 8 : 14),
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
                          color: context.palette.primaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              code,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: context.palette.primary,
                                    letterSpacing: 4,
                                  ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.copy,
                              size: 18,
                              color: context.palette.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: compact ? 10 : 18),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: Size.fromHeight(compact ? 44 : 48),
                      side: BorderSide(
                        color: context.palette.primary,
                        width: 1.4,
                      ),
                      foregroundColor: context.palette.primary,
                    ),
                    onPressed: () => copyInviteCode(context, code),
                    icon: const Icon(Icons.copy),
                    label: Text(strings.copyCode),
                  ),
                  SizedBox(height: gap),
                  CustomButton(
                    label: strings.shareInvite,
                    onPressed: () =>
                        shareInvite(groupName: name, inviteCode: code),
                  ),
                  SizedBox(height: gap),
                  TextButton(
                    style: TextButton.styleFrom(
                      minimumSize: Size.fromHeight(compact ? 32 : 40),
                    ),
                    onPressed: () => context.go('/home'),
                    child: Text(strings.done),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
