import 'package:basic_crud_flutter/features/home/presentation/cubit/home_cubit.dart';
import 'package:basic_crud_flutter/features/home/presentation/cubit/home_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('initial state is tab 0', () {
    final cubit = HomeCubit();
    expect(cubit.state.tabIndex, 0);
    cubit.close();
  });

  blocTest<HomeCubit, HomeState>(
    'selectTab updates the index',
    build: HomeCubit.new,
    act: (c) => c.selectTab(2),
    expect: () => [const HomeState(tabIndex: 2)],
  );

  blocTest<HomeCubit, HomeState>(
    'selecting the same tab emits nothing',
    build: HomeCubit.new,
    seed: () => const HomeState(tabIndex: 1),
    act: (c) => c.selectTab(1),
    expect: () => <HomeState>[],
  );

  blocTest<HomeCubit, HomeState>(
    'out-of-range index is clamped to the valid range',
    build: HomeCubit.new,
    seed: () => const HomeState(tabIndex: 2),
    act: (c) {
      c.selectTab(-1);
      c.selectTab(99);
    },
    expect: () => [
      const HomeState(tabIndex: 0),
      const HomeState(tabIndex: HomeCubit.tabCount - 1),
    ],
  );
}
