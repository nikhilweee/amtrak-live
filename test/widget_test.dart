// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:amtraklive/main.dart';

void main() {
  testWidgets('Amtrak Live app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const AmtrakLiveApp());

    // Verify that the app title is displayed.
    expect(find.text('Amtrak Live'), findsOneWidget);

    // Verify that the train number field is present.
    expect(find.text('Train Number'), findsOneWidget);

    // Verify that the date picker is present.
    expect(find.text('Select departure date'), findsOneWidget);

    // Verify that the search button is present.
    expect(find.text('Search Train Status'), findsOneWidget);
  });
}
