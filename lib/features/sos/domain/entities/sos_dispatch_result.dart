import 'package:equatable/equatable.dart';

/// Result of a single SOS dispatch attempt.
///
/// `alertId` is the Firestore document id when [queued] is false;
/// when the network was unavailable the payload was inserted into the
/// local outbox and `alertId` carries the literal `'pending'` so the UI
/// can surface a "queued" badge.
class SosDispatchResult extends Equatable {
  final String alertId;
  final bool queued;
  final int contactsCount;

  const SosDispatchResult({
    required this.alertId,
    required this.queued,
    required this.contactsCount,
  });

  @override
  List<Object?> get props => [alertId, queued, contactsCount];
}
