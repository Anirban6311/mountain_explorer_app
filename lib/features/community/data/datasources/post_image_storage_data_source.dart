import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class PostImageTooLargeException implements Exception {
  const PostImageTooLargeException();
  @override
  String toString() => 'PostImageTooLargeException';
}

abstract class PostImageStorageDataSource {
  /// Compresses [imagePath] and uploads the bytes to Storage. Returns the
  /// download URL. Throws [PostImageTooLargeException] when the compressed
  /// payload still exceeds the hard cap.
  Future<String> uploadPostImage({
    required String uid,
    required String imagePath,
  });

  /// Best-effort delete by download URL. Wraps Storage's ref-from-URL +
  /// delete; never throws.
  Future<void> deleteByUrl(String url);
}

/// Production Storage + compression data source.
///
/// Compression: quality 70 targeting ≤1MB; rejects anything still >2MB after
/// compression.
class FirebaseStoragePostImageDataSource
    implements PostImageStorageDataSource {
  final FirebaseStorage _storage;
  final int _quality;
  final int _hardCapBytes;

  FirebaseStoragePostImageDataSource(
    this._storage, {
    int quality = 70,
    int hardCapBytes = 2 * 1024 * 1024,
  })  : _quality = quality,
        _hardCapBytes = hardCapBytes;

  @override
  Future<String> uploadPostImage({
    required String uid,
    required String imagePath,
  }) async {
    final compressed = await FlutterImageCompress.compressWithFile(
      imagePath,
      quality: _quality,
    );
    final bytes = compressed ?? await File(imagePath).readAsBytes();
    if (bytes.lengthInBytes > _hardCapBytes) {
      throw const PostImageTooLargeException();
    }
    final ts = DateTime.now().millisecondsSinceEpoch;
    final ref = _storage.ref('posts/$uid/$ts.jpg');
    await ref.putData(
      Uint8List.fromList(bytes),
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return ref.getDownloadURL();
  }

  @override
  Future<void> deleteByUrl(String url) async {
    try {
      await _storage.refFromURL(url).delete();
    } catch (_) {
      // Intentionally swallowed — this is a cleanup hook, not a
      // user-visible operation.
    }
  }
}
