import 'package:flutter_test/flutter_test.dart';         
import 'package:familylocator/main.dart';                
import 'package:flutter/material.dart';                  
import 'package:flutter_riverpod/flutter_riverpod.dart'; 

void main() {
  testWidgets('App builds without crashing', (WidgetTester tester) async {
    // FamilyApp providers use karta hai, is liye ProviderScope wrap zaroori
    await tester.pumpWidget(const ProviderScope(child: FamilyApp()));
    expect(find.byType(MaterialApp), findsOneWidget);    // MaterialApp ek hona chahiye
  });
}