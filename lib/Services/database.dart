import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  static Future<void> updateLikedMountains(List<String> likedMountains) async {
    try {
      await FirebaseFirestore.instance.collection('liked_mountains').doc('liked').update({
        'likedMountains': FieldValue.arrayUnion(likedMountains),
      });
    } catch (e) {
      print('Error updating liked mountains: $e');
    }
  }
}
