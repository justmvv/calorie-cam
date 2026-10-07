import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The recognition chips on the capture screen: a tap picks (replaces) the dish, a long press
/// adds it alongside. Both gestures must reach the right handler and never both.
void main() {
  testWidgets('tap selects, long press adds — exclusively', (tester) async {
    var taps = 0, longPresses = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: GestureDetector(
              onLongPress: () => longPresses++,
              child: FilterChip(label: const Text('Burger'), selected: false, onSelected: (_) => taps++),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Burger'));
    await tester.pumpAndSettle();
    expect((taps, longPresses), (1, 0));

    await tester.longPress(find.text('Burger'));
    await tester.pumpAndSettle();
    expect((taps, longPresses), (1, 1));
  });
}
