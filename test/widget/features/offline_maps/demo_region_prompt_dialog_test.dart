import 'package:basic_crud_flutter/features/offline_maps/presentation/view/widgets/demo_region_prompt_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders Kangchenjunga copy with size + zoom range',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: DemoRegionPromptDialog()),
      ),
    );
    expect(find.textContaining('Kangchenjunga'), findsWidgets);
    expect(find.textContaining('40'), findsWidgets); // ~40 MB
    expect(find.textContaining('zoom'), findsOneWidget);
    expect(find.text('Allow'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
  });

  testWidgets('Allow button maps to true via showDialog result',
      (tester) async {
    bool? popped;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                popped = await showDialog<bool>(
                  context: context,
                  builder: (_) => const DemoRegionPromptDialog(),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Allow'));
    await tester.pumpAndSettle();
    expect(popped, isTrue);
  });

  testWidgets('Skip maps to false via showDialog result', (tester) async {
    bool? popped;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                popped = await showDialog<bool>(
                  context: context,
                  builder: (_) => const DemoRegionPromptDialog(),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(popped, isFalse);
  });
}
