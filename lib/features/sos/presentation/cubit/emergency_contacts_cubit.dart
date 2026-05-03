import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/result.dart';
import '../../domain/entities/emergency_contact.dart';
import '../../domain/usecases/add_contact.dart';
import '../../domain/usecases/delete_contact.dart';
import '../../domain/usecases/set_primary_contact.dart';
import '../../domain/usecases/update_contact.dart';
import '../../domain/usecases/watch_contacts.dart';
import 'emergency_contacts_state.dart';

class EmergencyContactsCubit extends Cubit<EmergencyContactsState> {
  EmergencyContactsCubit({
    required WatchContacts watch,
    required AddContact addContact,
    required UpdateContact updateContact,
    required DeleteContact deleteContact,
    required SetPrimaryContact setPrimary,
  })  : _watch = watch,
        _add = addContact,
        _update = updateContact,
        _delete = deleteContact,
        _setPrimary = setPrimary,
        super(const EmergencyContactsState());

  final WatchContacts _watch;
  final AddContact _add;
  final UpdateContact _update;
  final DeleteContact _delete;
  final SetPrimaryContact _setPrimary;

  StreamSubscription<List<EmergencyContact>>? _sub;
  String _uid = '';

  void subscribe(String uid) {
    if (isClosed) return;
    if (uid.isEmpty) return;
    if (uid == _uid && _sub != null) return;
    _uid = uid;
    _sub?.cancel();
    emit(state.copyWith(loading: true, clearError: true));
    _sub = _watch(uid).listen(
      (contacts) {
        if (isClosed) return;
        emit(state.copyWith(contacts: contacts, loading: false));
      },
      onError: (Object e) {
        if (isClosed) return;
        emit(state.copyWith(loading: false, error: e.toString()));
      },
    );
  }

  Future<void> add(EmergencyContact draft) async {
    final result = await _add(uid: _uid, draft: draft);
    if (result is Failure<EmergencyContact>) {
      emit(state.copyWith(error: result.error.message));
    }
  }

  Future<void> update(EmergencyContact contact) async {
    final result = await _update(uid: _uid, contact: contact);
    if (result is Failure<void>) {
      emit(state.copyWith(error: result.error.message));
    }
  }

  Future<void> delete(String contactId) async {
    final result = await _delete(uid: _uid, contactId: contactId);
    if (result is Failure<void>) {
      emit(state.copyWith(error: result.error.message));
    }
  }

  Future<void> setPrimary(String contactId) async {
    final result = await _setPrimary(uid: _uid, contactId: contactId);
    if (result is Failure<void>) {
      emit(state.copyWith(error: result.error.message));
    }
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
