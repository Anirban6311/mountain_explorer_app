import 'package:equatable/equatable.dart';

import '../../domain/entities/emergency_contact.dart';

class EmergencyContactsState extends Equatable {
  final List<EmergencyContact> contacts;
  final bool loading;
  final String? error;

  const EmergencyContactsState({
    this.contacts = const [],
    this.loading = true,
    this.error,
  });

  EmergencyContactsState copyWith({
    List<EmergencyContact>? contacts,
    bool? loading,
    String? error,
    bool clearError = false,
  }) {
    return EmergencyContactsState(
      contacts: contacts ?? this.contacts,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  EmergencyContact? get primary {
    for (final c in contacts) {
      if (c.isPrimary) return c;
    }
    return null;
  }

  bool get hasPrimary => primary != null;

  @override
  List<Object?> get props => [contacts, loading, error];
}
