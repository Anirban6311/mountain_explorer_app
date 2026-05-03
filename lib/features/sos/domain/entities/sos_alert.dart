import 'package:equatable/equatable.dart';

import '../../../trek/domain/entities/breadcrumb.dart';

class SosAlert extends Equatable {
  final String? id;
  final String uid;
  final DateTime? createdAt;
  final String status; // 'active' | 'cancelled' | 'resolved' | 'timed_out'
  final double lat;
  final double lng;
  final double? accuracy;
  final double? altitude;
  final int? batteryLevel;
  final String userName;
  final String userEmail;
  final List<NotifiedContact> contactsNotified;
  final List<Breadcrumb> trekBreadcrumbs;

  const SosAlert({
    this.id,
    required this.uid,
    this.createdAt,
    this.status = 'active',
    required this.lat,
    required this.lng,
    this.accuracy,
    this.altitude,
    this.batteryLevel,
    required this.userName,
    required this.userEmail,
    required this.contactsNotified,
    this.trekBreadcrumbs = const [],
  });

  @override
  List<Object?> get props => [
        id,
        uid,
        createdAt,
        status,
        lat,
        lng,
        accuracy,
        altitude,
        batteryLevel,
        userName,
        userEmail,
        contactsNotified,
        trekBreadcrumbs,
      ];
}

class NotifiedContact extends Equatable {
  final String name;
  final String phone;
  final bool isPrimary;
  const NotifiedContact({
    required this.name,
    required this.phone,
    required this.isPrimary,
  });

  @override
  List<Object?> get props => [name, phone, isPrimary];
}
