import 'package:equatable/equatable.dart';

sealed class TrekState extends Equatable {
  final bool hasBackgroundPermission;

  const TrekState({required this.hasBackgroundPermission});

  @override
  List<Object?> get props => [hasBackgroundPermission];
}

class TrekIdle extends TrekState {
  const TrekIdle({super.hasBackgroundPermission = false});
}

class TrekActive extends TrekState {
  final String sessionId;
  final int breadcrumbCount;

  const TrekActive({
    required this.sessionId,
    required this.breadcrumbCount,
    required super.hasBackgroundPermission,
  });

  TrekActive copyWith({
    String? sessionId,
    int? breadcrumbCount,
    bool? hasBackgroundPermission,
  }) {
    return TrekActive(
      sessionId: sessionId ?? this.sessionId,
      breadcrumbCount: breadcrumbCount ?? this.breadcrumbCount,
      hasBackgroundPermission:
          hasBackgroundPermission ?? this.hasBackgroundPermission,
    );
  }

  @override
  List<Object?> get props => [...super.props, sessionId, breadcrumbCount];
}

class TrekError extends TrekState {
  final String message;
  const TrekError({
    required this.message,
    required super.hasBackgroundPermission,
  });

  @override
  List<Object?> get props => [...super.props, message];
}
