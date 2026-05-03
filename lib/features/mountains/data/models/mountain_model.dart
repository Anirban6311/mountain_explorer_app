import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/mountain.dart';

class MountainModel extends Mountain {
  const MountainModel({
    required super.id,
    required super.name,
    required super.imageUrl,
    required super.description,
    super.region,
    super.lat,
    super.lng,
  });

  factory MountainModel.fromJson(Map<String, dynamic> json, {String? id}) {
    final name = json['name'] as String;
    return MountainModel(
      id: id ?? slugify(name),
      name: name,
      imageUrl: json['imageUrl'] as String? ?? '',
      description: json['description'] as String? ?? '',
      region: json['region'] as String?,
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
    );
  }

  factory MountainModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return MountainModel.fromJson(doc.data() ?? const {}, id: doc.id);
  }

  static String slugify(String s) =>
      s.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
}
