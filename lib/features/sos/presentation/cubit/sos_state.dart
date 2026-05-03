import 'package:equatable/equatable.dart';

sealed class SosState extends Equatable {
  final bool hasPrimaryContact;
  final bool locationPermissionGranted;

  const SosState({
    required this.hasPrimaryContact,
    required this.locationPermissionGranted,
  });

  @override
  List<Object?> get props => [hasPrimaryContact, locationPermissionGranted];
}

class SosIdle extends SosState {
  const SosIdle({
    super.hasPrimaryContact = false,
    super.locationPermissionGranted = false,
  });
}

class SosCountdown extends SosState {
  final int remainingSeconds;
  const SosCountdown({
    required this.remainingSeconds,
    required super.hasPrimaryContact,
    required super.locationPermissionGranted,
  });

  @override
  List<Object?> get props => [...super.props, remainingSeconds];
}

class SosDispatching extends SosState {
  const SosDispatching({
    required super.hasPrimaryContact,
    required super.locationPermissionGranted,
  });
}

class SosDispatched extends SosState {
  final String alertId;
  final bool queued;
  final int contactsCount;
  const SosDispatched({
    required this.alertId,
    required this.queued,
    required this.contactsCount,
    required super.hasPrimaryContact,
    required super.locationPermissionGranted,
  });

  @override
  List<Object?> get props =>
      [...super.props, alertId, queued, contactsCount];
}

class SosActive extends SosState {
  final String alertId;
  final int breadcrumbsSent;
  const SosActive({
    required this.alertId,
    this.breadcrumbsSent = 0,
    required super.hasPrimaryContact,
    required super.locationPermissionGranted,
  });

  SosActive copyWith({int? breadcrumbsSent}) => SosActive(
        alertId: alertId,
        breadcrumbsSent: breadcrumbsSent ?? this.breadcrumbsSent,
        hasPrimaryContact: hasPrimaryContact,
        locationPermissionGranted: locationPermissionGranted,
      );

  @override
  List<Object?> get props => [...super.props, alertId, breadcrumbsSent];
}

class SosCancelledState extends SosState {
  final String alertId;
  const SosCancelledState({
    required this.alertId,
    required super.hasPrimaryContact,
    required super.locationPermissionGranted,
  });

  @override
  List<Object?> get props => [...super.props, alertId];
}

class SosTimedOut extends SosState {
  final String alertId;
  const SosTimedOut({
    required this.alertId,
    required super.hasPrimaryContact,
    required super.locationPermissionGranted,
  });

  @override
  List<Object?> get props => [...super.props, alertId];
}

class SosError extends SosState {
  final String message;
  const SosError({
    required this.message,
    required super.hasPrimaryContact,
    required super.locationPermissionGranted,
  });

  @override
  List<Object?> get props => [...super.props, message];
}
