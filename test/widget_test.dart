import 'package:flutter_test/flutter_test.dart';
import 'package:familylocator/main.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('App builds without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const FamilyApp());
    expect(find.byType(MaterialApp), findsOneWidget);

  });
}