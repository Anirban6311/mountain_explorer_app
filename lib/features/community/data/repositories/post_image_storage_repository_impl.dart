import 'package:firebase_core/firebase_core.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/errors/result.dart';
import '../../domain/repositories/post_image_storage_repository.dart';
import '../datasources/post_image_storage_data_source.dart';

class PostImageStorageRepositoryImpl implements PostImageStorageRepository {
  final PostImageStorageDataSource _ds;
  const PostImageStorageRepositoryImpl(this._ds);

  @override
  Future<Result<String>> uploadPostImage({
    required String uid,
    required String imagePath,
  }) async {
    try {
      final url = await _ds.uploadPostImage(uid: uid, imagePath: imagePath);
      return Success<String>(url);
    } on PostImageTooLargeException catch (e) {
      return Failure<String>(
        ValidationError(
          'Image is too large. Please pick a smaller photo.',
          cause: e,
        ),
      );
    } on FirebaseException catch (e) {
      return Failure<String>(NetworkError(e.message ?? e.code, cause: e));
    } catch (e) {
      return Failure<String>(
        UnknownError('Image upload failed.', cause: e),
      );
    }
  }

  @override
  Future<void> deleteByUrl(String url) => _ds.deleteByUrl(url);
}
