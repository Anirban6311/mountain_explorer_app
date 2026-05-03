import 'package:basic_crud_flutter/features/mountains/domain/entities/mountain.dart';
import 'package:basic_crud_flutter/features/mountains/presentation/widgets/mountain_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(
  WidgetTester tester, {
  required Mountain mountain,
  required VoidCallback onLongPress,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          height: 400,
          width: 300,
          child: MountainCard(
            mountain: mountain,
            isLiked: false,
            onLongPress: onLongPress,
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('long-press invokes the callback', (tester) async {
    var fired = 0;
    await _pump(
      tester,
      mountain: const Mountain(
        id: 'shimla',
        name: 'Shimla',
        imageUrl: '',
        description: 'd',
        lat: 31.1048,
        lng: 77.1734,
      ),
      onLongPress: () => fired++,
    );
    await tester.longPress(find.byType(MountainCard));
    await tester.pumpAndSettle();
    expect(fired, 1);
  });

  testWidgets('callback is null-safe when not provided', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 400,
            width: 300,
            child: MountainCard(
              mountain: Mountain(
                id: 'm',
                name: 'M',
                imageUrl: '',
                description: '',
              ),
              isLiked: false,
            ),
          ),
        ),
      ),
    );
    // Should not throw even without onLongPress.
    await tester.longPress(find.byType(MountainCard));
    await tester.pumpAndSettle();
    expect(find.byType(MountainCard), findsOneWidget);
  });

  testWidgets('hasCoordinates returns false when lat/lng missing',
      (tester) async {
    const m = Mountain(
      id: 'm',
      name: 'M',
      imageUrl: '',
      description: '',
    );
    expect(m.hasCoordinates, isFalse);
  });

  testWidgets('hasCoordinates returns true when both present',
      (tester) async {
    const m = Mountain(
      id: 'm',
      name: 'M',
      imageUrl: '',
      description: '',
      lat: 30,
      lng: 75,
    );
    expect(m.hasCoordinates, isTrue);
  });
}
