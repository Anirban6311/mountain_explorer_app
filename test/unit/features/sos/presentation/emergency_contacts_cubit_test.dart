import 'dart:async';

import 'package:basic_crud_flutter/core/errors/app_error.dart';
import 'package:basic_crud_flutter/core/errors/result.dart';
import 'package:basic_crud_flutter/features/sos/domain/entities/emergency_contact.dart';
import 'package:basic_crud_flutter/features/sos/domain/usecases/add_contact.dart';
import 'package:basic_crud_flutter/features/sos/domain/usecases/delete_contact.dart';
import 'package:basic_crud_flutter/features/sos/domain/usecases/set_primary_contact.dart';
import 'package:basic_crud_flutter/features/sos/domain/usecases/update_contact.dart';
import 'package:basic_crud_flutter/features/sos/domain/usecases/watch_contacts.dart';
import 'package:basic_crud_flutter/features/sos/presentation/cubit/emergency_contacts_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockWatch extends Mock implements WatchContacts {}

class _MockAdd extends Mock implements AddContact {}

class _MockUpdate extends Mock implements UpdateContact {}

class _MockDelete extends Mock implements DeleteContact {}

class _MockSetPrimary extends Mock implements SetPrimaryContact {}

class _FakeContact extends Fake implements EmergencyContact {}

void main() {
  setUpAll(() => registerFallbackValue(_FakeContact()));

  late _MockWatch watch;
  late _MockAdd add;
  late _MockUpdate update;
  late _MockDelete delete;
  late _MockSetPrimary setPrimary;

  EmergencyContactsCubit build() => EmergencyContactsCubit(
        watch: watch,
        addContact: add,
        updateContact: update,
        deleteContact: delete,
        setPrimary: setPrimary,
      );

  setUp(() {
    watch = _MockWatch();
    add = _MockAdd();
    update = _MockUpdate();
    delete = _MockDelete();
    setPrimary = _MockSetPrimary();
  });

  test('subscribe loads contacts from the stream', () async {
    final controller = StreamController<List<EmergencyContact>>();
    when(() => watch(any())).thenAnswer((_) => controller.stream);
    final cubit = build();
    cubit.subscribe('u1');
    controller.add(const [
      EmergencyContact(id: 'c1', name: 'A', phone: '12345678'),
    ]);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(cubit.state.loading, isFalse);
    expect(cubit.state.contacts, hasLength(1));
    await controller.close();
    await cubit.close();
  });

  test('subscribe emits error when stream errors', () async {
    final controller = StreamController<List<EmergencyContact>>();
    when(() => watch(any())).thenAnswer((_) => controller.stream);
    final cubit = build();
    cubit.subscribe('u1');
    controller.addError(Exception('boom'));
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(cubit.state.error, contains('boom'));
    await controller.close();
    await cubit.close();
  });

  test('add() failure sets state.error', () async {
    when(() => watch(any()))
        .thenAnswer((_) => const Stream<List<EmergencyContact>>.empty());
    when(() => add(uid: any(named: 'uid'), draft: any(named: 'draft')))
        .thenAnswer((_) async => const Failure<EmergencyContact>(
              UnknownError('nope'),
            ));
    final cubit = build();
    cubit.subscribe('u1');
    await cubit.add(const EmergencyContact(id: '', name: 'X', phone: '12345678'));
    expect(cubit.state.error, 'nope');
    await cubit.close();
  });
}
