import 'package:basic_crud_flutter/core/consent/background_location_disclosure_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(
  WidgetTester tester, {
  required ValueChanged<bool?> onPopped,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async {
                final result = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => const BackgroundLocationDisclosurePage(),
                  ),
                );
                onPopped(result);
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
}

void main() {
  testWidgets('renders required Play-policy disclosure copy',
      (tester) async {
    await _pump(tester, onPopped: (_) {});
    expect(find.textContaining('background location'), findsWidgets);
    expect(find.textContaining('emergency contacts'), findsWidgets);
    expect(find.textContaining('latitude'), findsOneWidget);
    expect(find.textContaining('battery'), findsOneWidget);
    expect(find.textContaining('SMS'), findsOneWidget);
    expect(find.textContaining('Firebase'), findsOneWidget);
    expect(find.textContaining('Settings'), findsOneWidget);
    expect(find.text('Allow background location'), findsOneWidget);
    expect(find.text('Not now'), findsOneWidget);
  });

  testWidgets('Allow pops with true', (tester) async {
    bool? result;
    await _pump(tester, onPopped: (v) => result = v);
    await tester.tap(find.text('Allow background location'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });

  testWidgets('Not now pops with false', (tester) async {
    bool? result;
    await _pump(tester, onPopped: (v) => result = v);
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    expect(result, isFalse);
  });

  testWidgets('system back gesture pops with false, not null',
      (tester) async {
    bool? result;
    var popCalled = false;
    await _pump(tester, onPopped: (v) {
      popCalled = true;
      result = v;
    });
    final popped = await tester
        .state<NavigatorState>(find.byType(Navigator).last)
        .maybePop();
    await tester.pumpAndSettle();
    expect(popped, isTrue);
    expect(popCalled, isTrue);
    expect(result, isFalse);
  });
}
