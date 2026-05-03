import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get_it/get_it.dart';

import '../data/datasources/comments_remote_data_source.dart';
import '../data/datasources/post_image_storage_data_source.dart';
import '../data/datasources/posts_remote_data_source.dart';
import '../data/repositories/comments_repository_impl.dart';
import '../data/repositories/post_image_storage_repository_impl.dart';
import '../data/repositories/posts_repository_impl.dart';
import '../domain/repositories/comments_repository.dart';
import '../domain/repositories/post_image_storage_repository.dart';
import '../domain/repositories/posts_repository.dart';
import '../domain/usecases/community_usecases.dart';
import '../presentation/cubit/create_post_cubit.dart';
import '../presentation/cubit/feed_cubit.dart';

void registerCommunityModule(GetIt getIt) {
  if (getIt.isRegistered<PostsRepository>()) return;

  getIt.registerLazySingleton<FirebaseStorage>(
    () => FirebaseStorage.instance,
  );

  getIt.registerLazySingleton<PostsRemoteDataSource>(
    () => FirestorePostsRemoteDataSource(getIt<FirebaseFirestore>()),
  );
  getIt.registerLazySingleton<CommentsRemoteDataSource>(
    () => FirestoreCommentsRemoteDataSource(getIt<FirebaseFirestore>()),
  );
  getIt.registerLazySingleton<PostImageStorageDataSource>(
    () => FirebaseStoragePostImageDataSource(getIt<FirebaseStorage>()),
  );
  getIt.registerLazySingleton<PostImageStorageRepository>(
    () => PostImageStorageRepositoryImpl(getIt<PostImageStorageDataSource>()),
  );
  getIt.registerLazySingleton<PostsRepository>(
    () => PostsRepositoryImpl(
      posts: getIt<PostsRemoteDataSource>(),
      storage: getIt<PostImageStorageRepository>(),
    ),
  );
  getIt.registerLazySingleton<CommentsRepository>(
    () => CommentsRepositoryImpl(getIt<CommentsRemoteDataSource>()),
  );

  final posts = getIt<PostsRepository>();
  final comments = getIt<CommentsRepository>();
  getIt.registerLazySingleton(() => WatchFeed(posts));
  getIt.registerLazySingleton(() => GetPost(posts));
  getIt.registerLazySingleton(() => CreatePost(posts));
  getIt.registerLazySingleton(() => UpdatePost(posts));
  getIt.registerLazySingleton(() => DeletePost(posts));
  getIt.registerLazySingleton(() => ToggleLikePost(posts));
  getIt.registerLazySingleton(() => WatchComments(comments));
  getIt.registerLazySingleton(() => AddComment(comments));
  getIt.registerLazySingleton(() => DeleteComment(comments));

  getIt.registerLazySingleton<FeedCubit>(
    () => FeedCubit(
      watchFeed: getIt<WatchFeed>(),
      toggleLikePost: getIt<ToggleLikePost>(),
    ),
    dispose: (c) => c.close(),
  );
  getIt.registerFactory<CreatePostCubit>(
    () => CreatePostCubit(createPost: getIt<CreatePost>()),
  );
}
