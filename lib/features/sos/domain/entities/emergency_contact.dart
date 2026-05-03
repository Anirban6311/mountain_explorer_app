import 'package:equatable/equatable.dart';

class EmergencyContact extends Equatable {
  final String id;
  final String name;
  final String phone;
  final String? relationship;
  final bool isPrimary;
  final DateTime? createdAt;

  const EmergencyContact({
    required this.id,
    required this.name,
    required this.phone,
    this.relationship,
    this.isPrimary = false,
    this.createdAt,
  });

  EmergencyContact copyWith({
    String? id,
    String? name,
    String? phone,
    String? relationship,
    bool? isPrimary,
    DateTime? createdAt,
  }) {
    return EmergencyContact(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      relationship: relationship ?? this.relationship,
      isPrimary: isPrimary ?? this.isPrimary,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props =>
      [id, name, phone, relationship, isPrimary, createdAt];
}
