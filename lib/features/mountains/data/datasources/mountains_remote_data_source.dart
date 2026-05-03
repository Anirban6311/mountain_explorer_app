import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../models/mountain_model.dart';

abstract class MountainsRemoteDataSource {
  /// Returns the list of mountains. Data source is responsible for falling
  /// back to the bundled asset when Firestore returns an empty collection.
  Future<List<MountainModel>> getMountains();
}

class FirestoreMountainsRemoteDataSource implements MountainsRemoteDataSource {
  final FirebaseFirestore _db;
  final String _assetPath;

  FirestoreMountainsRemoteDataSource({
    required FirebaseFirestore db,
    String assetPath = 'assets/hill_station.json',
  })  : _db = db,
        _assetPath = assetPath;

  @override
  Future<List<MountainModel>> getMountains() async {
    try {
      final snap = await _db.collection('mountains').get();
      if (snap.docs.isNotEmpty) {
        return snap.docs.map(MountainModel.fromFirestore).toList();
      }
    } catch (_) {
      // Offline / permission / transient — fall through to bundled asset so
      // the browse experience still works for guests and offline launches.
    }
    return _loadFromAsset();
  }

  Future<List<MountainModel>> _loadFromAsset() async {
    final raw = await rootBundle.loadString(_assetPath);
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    return list.map((j) => MountainModel.fromJson(j)).toList();
  }
}
