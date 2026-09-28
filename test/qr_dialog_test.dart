import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';

void main() {
  testWidgets('QrPainter renders inside an AlertDialog', (tester) async {
    final qrCode = QrCode.fromData(
      data: 'EZZ7P2',
      errorCorrectLevel: QrErrorCorrectLevel.M,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Invite QR'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 200,
                            height: 200,
                            child: CustomPaint(
                              painter: QrPainter.withQr(
                                qr: qrCode,
                                gapless: true,
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.all(6),
                            child: Text(
                              'EZZ7P2',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Invite QR'), findsOneWidget);
    expect(find.text('EZZ7P2'), findsOneWidget);
  });
}