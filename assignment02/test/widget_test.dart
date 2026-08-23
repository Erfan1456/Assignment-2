import 'package:assignment02/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows broadcast receiver selection on launch', (tester) async {
    await tester.pumpWidget(const Assignment02App());

    expect(find.text('App'), findsOneWidget);
    expect(find.text('Select a broadcast type'), findsOneWidget);
    expect(find.text('Custom broadcast receiver'), findsOneWidget);
    expect(find.text('Proceed'), findsOneWidget);
  });

  testWidgets('drawer lists the four menu options', (tester) async {
    await tester.pumpWidget(const Assignment02App());

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    expect(find.text('Broadcast Receiver'), findsOneWidget);
    expect(find.text('Image Scale'), findsOneWidget);
    expect(find.text('Video'), findsOneWidget);
    expect(find.text('Audio'), findsOneWidget);
  });
}
