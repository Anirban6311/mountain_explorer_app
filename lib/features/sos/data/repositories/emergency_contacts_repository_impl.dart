import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/errors/result.dart';
import '../../domain/entities/emergency_contact.dart';
import '../../domain/repositories/emergency_contacts_repository.dart';
import '../datasources/emergency_contacts_remote_data_source.dart';

class EmergencyContactsRepositoryImpl implements EmergencyContactsRepository {
  EmergencyContactsRepositoryImpl({
    required EmergencyContactsRemoteDataSource ds,
  }) : _ds = ds;

  final EmergencyContactsRemoteDataSource _ds;

  @override
  Stream<List<EmergencyContact>> watch(String uid) => _ds.watch(uid);

  @override
  Future<Result<EmergencyContact>> add({
    required String uid,
    required EmergencyContact draft,
  }) async {
    try {
      final existingCount = await _ds.count(uid);
      // First contact auto-becomes primary so the SOS FAB enables right
      // after the user finishes onboarding their first contact.
      final autoPrimary = existingCount == 0;
      final toAdd = draft.copyWith(
        isPrimary: autoPrimary || draft.isPrimary,
      );
      final inserted = await _ds.add(uid, toAdd);
      return Success<EmergencyContact>(inserted);
    } on FirebaseException catch (e) {
      return Failure<EmergencyContact>(_mapError(e));
    } catch (e) {
      return Failure<EmergencyContact>(
        UnknownError('Failed to add contact.', cause: e),
      );
    }
  }

  @override
  Future<Result<void>> update({
    required String uid,
    required EmergencyContact contact,
  }) async {
    try {
      await _ds.update(uid, contact);
      return const Success<void>(null);
    } on FirebaseException catch (e) {
      return Failure<void>(_mapError(e));
    } catch (e) {
      return Failure<void>(
        UnknownError('Failed to update contact.', cause: e),
      );
    }
  }

  @override
  Future<Result<void>> delete({
    required String uid,
    required String contactId,
  }) async {
    try {
      await _ds.delete(uid, contactId);
      return const Success<void>(null);
    } on FirebaseException catch (e) {
      return Failure<void>(_mapError(e));
    } catch (e) {
      return Failure<void>(
        UnknownError('Failed to delete contact.', cause: e),
      );
    }
  }

  @override
  Future<Result<void>> setPrimary({
    required String uid,
    required String contactId,
  }) async {
    try {
      final current = await _ds.findPrimary(uid);
      await _ds.setPrimary(
        uid,
        newPrimaryId: contactId,
        previousPrimaryId: current?.id,
      );
      return const Success<void>(null);
    } on FirebaseException catch (e) {
      return Failure<void>(_mapError(e));
    } catch (e) {
      return Failure<void>(
        UnknownError('Failed to set primary.', cause: e),
      );
    }
  }

  AppError _mapError(FirebaseException e) {
    if (e.code == 'permission-denied') {
      return PermissionError('Not allowed.', cause: e);
    }
    if (e.code == 'unavailable' || e.code == 'deadline-exceeded') {
      return NetworkError('Network unavailable.', cause: e);
    }
    return UnknownError('Firestore failure.', cause: e);
  }
}
