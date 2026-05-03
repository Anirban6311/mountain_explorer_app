import 'package:basic_crud_flutter/features/trek/presentation/cubit/trek_cubit.dart';
import 'package:basic_crud_flutter/features/trek/presentation/cubit/trek_state.dart';
import 'package:basic_crud_flutter/features/trek/presentation/view/widgets/trek_toggle_button.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockTrekCubit extends MockCubit<TrekState> implements TrekCubit {}

class _FakeBuildContext extends Fake implements BuildContext {}

Future<void> _pump(WidgetTester tester, TrekCubit cubit) async {
  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider<TrekCubit>.value(
        value: cubit,
        child: Scaffold(
          appBar: AppBar(actions: const [TrekToggleButton()]),
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(() => registerFallbackValue(_FakeBuildContext()));

  testWidgets('renders Start Trek when idle', (tester) async {
    final cubit = _MockTrekCubit();
    when(() => cubit.state).thenReturn(const TrekIdle());
    await _pump(tester, cubit);
    expect(find.byTooltip('Start Trek'), findsOneWidget);
  });

  testWidgets('renders Stop Trek when active', (tester) async {
    final cubit = _MockTrekCubit();
    when(() => cubit.state).thenReturn(const TrekActive(
      sessionId: 's1',
      breadcrumbCount: 0,
      hasBackgroundPermission: true,
    ));
    await _pump(tester, cubit);
    expect(find.byTooltip('Stop Trek'), findsOneWidget);
  });

  testWidgets('tap when idle invokes start with the BuildContext',
      (tester) async {
    final cubit = _MockTrekCubit();
    when(() => cubit.state).thenReturn(const TrekIdle());
    when(() => cubit.start(any())).thenAnswer((_) async {});
    await _pump(tester, cubit);
    await tester.tap(find.byTooltip('Start Trek'));
    await tester.pump();
    verify(() => cubit.start(any())).called(1);
  });

  testWidgets('tap when active invokes stop', (tester) async {
    final cubit = _MockTrekCubit();
    when(() => cubit.state).thenReturn(const TrekActive(
      sessionId: 's1',
      breadcrumbCount: 0,
      hasBackgroundPermission: true,
    ));
    when(() => cubit.stop()).thenAnswer((_) async {});
    await _pump(tester, cubit);
    await tester.tap(find.byTooltip('Stop Trek'));
    await tester.pump();
    verify(() => cubit.stop()).called(1);
  });
}
