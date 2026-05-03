import 'package:basic_crud_flutter/features/mountains/domain/entities/mountain.dart';
import 'package:basic_crud_flutter/features/mountains/domain/usecases/search_mountains.dart';
import 'package:basic_crud_flutter/features/mountains/presentation/cubit/mountain_search_cubit.dart';
import 'package:basic_crud_flutter/features/mountains/presentation/cubit/mountain_search_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

const _source = <Mountain>[
  Mountain(id: 'shimla', name: 'Shimla', imageUrl: 'x', description: 'colonial'),
  Mountain(id: 'manali', name: 'Manali', imageUrl: 'x', description: 'adventure'),
];

MountainSearchCubit _build() => MountainSearchCubit(
      searchMountains: const SearchMountains(),
    );

void main() {
  blocTest<MountainSearchCubit, MountainSearchState>(
    'setSource populates results with the full list and empty query',
    build: _build,
    act: (c) => c.setSource(_source),
    expect: () => [
      const MountainSearchState(source: _source, query: '', results: _source),
    ],
  );

  blocTest<MountainSearchCubit, MountainSearchState>(
    'updateQuery filters the source using SearchMountains',
    build: _build,
    seed: () => const MountainSearchState(
      source: _source,
      query: '',
      results: _source,
    ),
    act: (c) => c.updateQuery('adv'),
    expect: () => [
      isA<MountainSearchState>()
          .having((s) => s.query, 'query', 'adv')
          .having((s) => s.results.length, 'len', 1)
          .having((s) => s.results.single.id, 'id', 'manali'),
    ],
  );

  blocTest<MountainSearchCubit, MountainSearchState>(
    'clearing the query restores the full list',
    build: _build,
    seed: () => MountainSearchState(
      source: _source,
      query: 'adv',
      results: [_source[1]],
    ),
    act: (c) => c.updateQuery(''),
    expect: () => [
      isA<MountainSearchState>()
          .having((s) => s.query, 'query', '')
          .having((s) => s.results, 'results', _source),
    ],
  );
}
