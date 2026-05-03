import 'package:basic_crud_flutter/core/errors/app_error.dart';
import 'package:basic_crud_flutter/core/errors/result.dart';
import 'package:basic_crud_flutter/features/checklist/data/datasources/checklist_remote_data_source.dart';
import 'package:basic_crud_flutter/features/checklist/data/models/checklist_item_model.dart';
import 'package:basic_crud_flutter/features/checklist/data/repositories/checklist_repository_impl.dart';
import 'package:basic_crud_flutter/features/checklist/domain/entities/checklist_item.dart';
import 'package:basic_crud_flutter/features/checklist/domain/repositories/checklist_repository.dart';
import 'package:basic_crud_flutter/features/checklist/domain/usecases/checklist_usecases.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements ChecklistRepository {}

class _MockDs extends Mock implements ChecklistRemoteDataSource {}

void main() {
  group('UseCases', () {
    late _MockRepo repo;
    setUp(() => repo = _MockRepo());

    test('WatchChecklist forwards stream', () async {
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
      final list = await WatchChecklist(repo)('u1').first;
      expect(list.single.id, 'a');
    });

    test('AddChecklistItem delegates', () async {
      when(() => repo.addItem(uid: any(named: 'uid'), text: any(named: 'text')))
          .thenAnswer((_) async => const Success<void>(null));
      await AddChecklistItem(repo)(uid: 'u1', text: 'hat');
      verify(() => repo.addItem(uid: 'u1', text: 'hat')).called(1);
    });

    test('ToggleChecklistItem delegates', () async {
      when(() => repo.toggleItem(
            uid: any(named: 'uid'),
            itemId: any(named: 'itemId'),
            isDone: any(named: 'isDone'),
          )).thenAnswer((_) async => const Success<void>(null));
      await ToggleChecklistItem(repo)(uid: 'u1', itemId: 'i1', isDone: true);
      verify(() => repo.toggleItem(uid: 'u1', itemId: 'i1', isDone: true))
          .called(1);
    });

    test('DeleteChecklistItem delegates', () async {
      when(() => repo.deleteItem(
            uid: any(named: 'uid'),
            itemId: any(named: 'itemId'),
          )).thenAnswer((_) async => const Success<void>(null));
      await DeleteChecklistItem(repo)(uid: 'u1', itemId: 'i1');
      verify(() => repo.deleteItem(uid: 'u1', itemId: 'i1')).called(1);
    });
  });

  group('ChecklistRepositoryImpl', () {
    late _MockDs ds;
    late ChecklistRepositoryImpl repo;

    setUp(() {
      ds = _MockDs();
      repo = ChecklistRepositoryImpl(ds);
    });

    test('addItem trims + rejects empty', () async {
      final result = await repo.addItem(uid: 'u1', text: '   ');
      expect((result as Failure<void>).error, isA<ValidationError>());
      verifyNever(() =>
          ds.addItem(uid: any(named: 'uid'), text: any(named: 'text')));
    });

    test('addItem rejects > 120 chars', () async {
      final result = await repo.addItem(uid: 'u1', text: 'x' * 121);
      expect((result as Failure<void>).error, isA<ValidationError>());
    });

    test('addItem happy path', () async {
      when(() => ds.addItem(
            uid: any(named: 'uid'),
            text: any(named: 'text'),
          )).thenAnswer((_) async {});
      final result = await repo.addItem(uid: 'u1', text: 'Buy tent');
      expect(result, isA<Success<void>>());
      verify(() => ds.addItem(uid: 'u1', text: 'Buy tent')).called(1);
    });

    test('toggleItem maps permission-denied', () async {
      when(() => ds.toggleItem(
            uid: any(named: 'uid'),
            itemId: any(named: 'itemId'),
            isDone: any(named: 'isDone'),
          )).thenThrow(
        FirebaseException(plugin: 'firestore', code: 'permission-denied'),
      );
      final result =
          await repo.toggleItem(uid: 'u1', itemId: 'i1', isDone: true);
      expect((result as Failure<void>).error, isA<PermissionError>());
    });

    test('deleteItem happy path', () async {
      when(() => ds.deleteItem(
            uid: any(named: 'uid'),
            itemId: any(named: 'itemId'),
          )).thenAnswer((_) async {});
      final result = await repo.deleteItem(uid: 'u1', itemId: 'i1');
      expect(result, isA<Success<void>>());
    });

    test('watchChecklist forwards DS stream', () async {
      final list = [
        ChecklistItemModel(
          id: 'a',
          text: 'x',
          isDone: false,
          createdAt: DateTime(2026),
        ),
      ];
      when(() => ds.watchChecklist(any()))
          .thenAnswer((_) => Stream.value(list));
      expect(await repo.watchChecklist('u1').first, list);
    });
  });
}
