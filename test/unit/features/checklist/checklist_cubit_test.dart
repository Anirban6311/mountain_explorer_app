import 'package:basic_crud_flutter/core/errors/result.dart';
import 'package:basic_crud_flutter/features/checklist/domain/entities/checklist_item.dart';
import 'package:basic_crud_flutter/features/checklist/domain/repositories/checklist_repository.dart';
import 'package:basic_crud_flutter/features/checklist/domain/usecases/checklist_usecases.dart';
import 'package:basic_crud_flutter/features/checklist/presentation/cubit/checklist_cubit.dart';
import 'package:basic_crud_flutter/features/checklist/presentation/cubit/checklist_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements ChecklistRepository {}

ChecklistCubit _build(_MockRepo repo) => ChecklistCubit(
      watchChecklist: WatchChecklist(repo),
      addChecklistItem: AddChecklistItem(repo),
      toggleChecklistItem: ToggleChecklistItem(repo),
      deleteChecklistItem: DeleteChecklistItem(repo),
    );

void main() {
  late _MockRepo repo;
  setUp(() => repo = _MockRepo());

  blocTest<ChecklistCubit, ChecklistState>(
    'subscribe(uid="") keeps Initial',
    build: () => _build(repo),
    act: (c) => c.subscribe(''),
    expect: () => <ChecklistState>[],
  );

  blocTest<ChecklistCubit, ChecklistState>(
    'subscribe emits Loading then Loaded with items',
    build: () {
      when(() => repo.watchChecklist(any())).thenAnswer(
        (_) => Stream.value([
          ChecklistItem(
            id: 'a',
            text: 'x',
            isDone: false,
            createdAt: DateTime(2026),
          ),
        ]),
      );
      return _build(repo);
    },
    act: (c) => c.subscribe('u1'),
    expect: () => [
      isA<ChecklistLoading>(),
      isA<ChecklistLoaded>().having((s) => s.items.length, 'len', 1),
    ],
  );

  blocTest<ChecklistCubit, ChecklistState>(
    'subscribe surfaces stream error as ChecklistError',
    build: () {
      when(() => repo.watchChecklist(any())).thenAnswer(
        (_) => Stream<List<ChecklistItem>>.error(StateError('boom')),
      );
      return _build(repo);
    },
    act: (c) async {
      c.subscribe('u1');
      await Future<void>.delayed(Duration.zero);
    },
    expect: () => [
      isA<ChecklistLoading>(),
      isA<ChecklistError>(),
    ],
  );

  test('addItem delegates with current uid', () async {
    when(() => repo.watchChecklist(any()))
        .thenAnswer((_) => const Stream<List<ChecklistItem>>.empty());
    when(() => repo.addItem(uid: any(named: 'uid'), text: any(named: 'text')))
        .thenAnswer((_) async => const Success<void>(null));

    final cubit = _build(repo);
    cubit.subscribe('u1');
    await cubit.addItem('Buy tent');

    verify(() => repo.addItem(uid: 'u1', text: 'Buy tent')).called(1);
    await cubit.close();
  });

  test('toggle flips isDone', () async {
    when(() => repo.watchChecklist(any()))
        .thenAnswer((_) => const Stream<List<ChecklistItem>>.empty());
    when(() => repo.toggleItem(
          uid: any(named: 'uid'),
          itemId: any(named: 'itemId'),
          isDone: any(named: 'isDone'),
        )).thenAnswer((_) async => const Success<void>(null));

    final cubit = _build(repo);
    cubit.subscribe('u1');
    final item = ChecklistItem(
      id: 'a',
      text: 'x',
      isDone: false,
      createdAt: DateTime(2026),
    );
    await cubit.toggle(item);
    verify(() => repo.toggleItem(uid: 'u1', itemId: 'a', isDone: true))
        .called(1);
    await cubit.close();
  });

  test('delete forwards to repo', () async {
    when(() => repo.watchChecklist(any()))
        .thenAnswer((_) => const Stream<List<ChecklistItem>>.empty());
    when(() => repo.deleteItem(
          uid: any(named: 'uid'),
          itemId: any(named: 'itemId'),
        )).thenAnswer((_) async => const Success<void>(null));

    final cubit = _build(repo);
    cubit.subscribe('u1');
    await cubit.delete(ChecklistItem(
      id: 'a',
      text: 'x',
      isDone: false,
      createdAt: DateTime(2026),
    ));
    verify(() => repo.deleteItem(uid: 'u1', itemId: 'a')).called(1);
    await cubit.close();
  });
}
