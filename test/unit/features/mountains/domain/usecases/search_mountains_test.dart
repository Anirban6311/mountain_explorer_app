import 'package:basic_crud_flutter/features/mountains/domain/entities/mountain.dart';
import 'package:basic_crud_flutter/features/mountains/domain/usecases/search_mountains.dart';
import 'package:flutter_test/flutter_test.dart';

const _list = <Mountain>[
  Mountain(
    id: 'shimla',
    name: 'Shimla',
    imageUrl: 'x',
    description: 'Colonial hill station',
  ),
  Mountain(
    id: 'manali',
    name: 'Manali',
    imageUrl: 'x',
    description: 'Adventure sports and temples',
  ),
  Mountain(
    id: 'ooty',
    name: 'Ooty',
    imageUrl: 'x',
    description: 'Nilgiri queen',
  ),
];

void main() {
  const usecase = SearchMountains();

  test('empty query returns full list', () {
    expect(usecase(_list, ''), _list);
    expect(usecase(_list, '   '), _list);
  });

  test('name match is case-insensitive', () {
    final result = usecase(_list, 'sHiM');
    expect(result.single.id, 'shimla');
  });

  test('matches description', () {
    final result = usecase(_list, 'adventure');
    expect(result.single.id, 'manali');
  });

  test('returns empty list when nothing matches', () {
    expect(usecase(_list, 'everest'), isEmpty);
  });
}
