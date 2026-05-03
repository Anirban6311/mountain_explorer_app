import '../../../../core/errors/result.dart';

abstract class PostImageStorageRepository {
  /// Compresses + uploads [imagePath] and returns the download URL.
  /// Returns `Failure(ValidationError)` if the compressed size exceeds the
  /// server-side cap (currently ~2MB).
  Future<Result<String>> uploadPostImage({
    required String uid,
    required String imagePath,
  });

  /// Best-effort delete of an uploaded post image given its download URL.
  /// Used to clean up orphaned Storage objects when the subsequent
  /// Firestore write fails. Never surfaces errors — callers should fire
  /// and forget.
  Future<void> deleteByUrl(String url);
}
