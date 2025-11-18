import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:social_nest/main.dart';

void main() {
  testWidgets('SocialNest app starts with welcome screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SocialNestApp());

    // Verify that the welcome screen is displayed
    expect(find.text('SocialNest'), findsOneWidget);
    expect(find.text('Connect, Share & Grow Together'), findsOneWidget);
    expect(find.text('Join SocialNest'), findsOneWidget);
  });

  testWidgets('Welcome screen has all main elements', (WidgetTester tester) async {
    await tester.pumpWidget(const SocialNestApp());

    // Check for main title
    expect(find.text('SocialNest'), findsOneWidget);
    
    // Check for subtitle
    expect(find.text('Connect, Share & Grow Together'), findsOneWidget);
    
    // Check for buttons
    expect(find.text('Join SocialNest'), findsOneWidget);
    expect(find.text('I Have an Account'), findsOneWidget);
    
    // Check for feature stats
    expect(find.text('50K+'), findsOneWidget);
    expect(find.text('100K+'), findsOneWidget);
    expect(find.text('1M+'), findsOneWidget);
  });
}