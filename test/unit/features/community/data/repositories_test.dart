import 'package:basic_crud_flutter/core/errors/app_error.dart';
import 'package:basic_crud_flutter/core/errors/result.dart';
import 'package:basic_crud_flutter/features/community/data/datasources/comments_remote_data_source.dart';
import 'package:basic_crud_flutter/features/community/data/datasources/post_image_storage_data_source.dart';
import 'package:basic_crud_flutter/features/community/data/datasources/posts_remote_data_source.dart';
import 'package:basic_crud_flutter/features/community/data/models/post_model.dart';
import 'package:basic_crud_flutter/features/community/data/repositories/comments_repository_impl.dart';
import 'package:basic_crud_flutter/features/community/data/repositories/post_image_storage_repository_impl.dart';
import 'package:basic_crud_flutter/features/community/data/repositories/posts_repository_impl.dart';
import 'package:basic_crud_flutter/features/community/domain/entities/post.dart';
import 'package:basic_crud_flutter/features/community/domain/entities/post_draft.dart';
import 'package:basic_crud_flutter/features/community/domain/repositories/post_image_storage_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockPostsDs extends Mock implements PostsRemoteDataSource {}

class _MockCommentsDs extends Mock implements CommentsRemoteDataSource {}

class _MockStorageRepo extends Mock implements PostImageStorageRepository {}

class _MockStorageDs extends Mock implements PostImageStorageDataSource {}

PostModel _samplePost() => PostModel(
      pId: 'p1',
      pTitle: 't',
      pDescription: 'd',
      pImage: 'url',
      pTime: DateTime(2026),
      uid: 'u1',
      uEmail: 'u@e',
      uName: 'U',
      likes: const [],
    );

void main() {
  group('PostsRepositoryImpl', () {
    late _MockPostsDs posts;
    late _MockStorageRepo storage;
    late PostsRepositoryImpl repo;

    setUp(() {
      posts = _MockPostsDs();
      storage = _MockStorageRepo();
      when(() => storage.deleteByUrl(any())).thenAnswer((_) async {});
      repo = PostsRepositoryImpl(posts: posts, storage: storage);
    });

    test('createPost rejects an invalid draft without calling storage',
        () async {
      final result = await repo.createPost(
        draft: const PostDraft(title: '', description: 'd', imagePath: '/x'),
        uid: 'u',
        uEmail: 'e',
        uName: 'n',
      );
      expect((result as Failure<Post>).error, isA<ValidationError>());
      verifyNever(() => storage.uploadPostImage(
            uid: any(named: 'uid'),
            imagePath: any(named: 'imagePath'),
          ));
    });

    test('createPost happy path uploads then writes doc', () async {
      when(() => storage.uploadPostImage(
            uid: any(named: 'uid'),
            imagePath: any(named: 'imagePath'),
          )).thenAnswer((_) async => const Success<String>('https://img'));
      when(() => posts.createPost(
            pTitle: any(named: 'pTitle'),
            pDescription: any(named: 'pDescription'),
            pImage: any(named: 'pImage'),
            uid: any(named: 'uid'),
            uEmail: any(named: 'uEmail'),
            uName: any(named: 'uName'),
          )).thenAnswer((_) async => _samplePost());

      final result = await repo.createPost(
        draft: const PostDraft(
          title: 't',
          description: 'd',
          imagePath: '/x',
        ),
        uid: 'u1',
        uEmail: 'u@e',
        uName: 'U',
      );

      expect((result as Success<Post>).value.pId, 'p1');
      verify(() => storage.uploadPostImage(
            uid: 'u1',
            imagePath: '/x',
          )).called(1);
    });

    test('createPost cleans up orphan image when Firestore write fails',
        () async {
      when(() => storage.uploadPostImage(
            uid: any(named: 'uid'),
            imagePath: any(named: 'imagePath'),
          )).thenAnswer((_) async => const Success<String>('https://orphan'));
      when(() => posts.createPost(
            pTitle: any(named: 'pTitle'),
            pDescription: any(named: 'pDescription'),
            pImage: any(named: 'pImage'),
            uid: any(named: 'uid'),
            uEmail: any(named: 'uEmail'),
            uName: any(named: 'uName'),
          )).thenThrow(
        FirebaseException(plugin: 'firestore', code: 'permission-denied'),
      );

      await repo.createPost(
        draft: const PostDraft(title: 't', description: 'd', imagePath: '/x'),
        uid: 'u1',
        uEmail: 'u@e',
        uName: 'U',
      );

      // unawaited — give the fire-and-forget delete a microtask to run
      await Future<void>.delayed(Duration.zero);
      verify(() => storage.deleteByUrl('https://orphan')).called(1);
    });

    test('createPost surfaces storage Failure without writing doc', () async {
      when(() => storage.uploadPostImage(
            uid: any(named: 'uid'),
            imagePath: any(named: 'imagePath'),
          )).thenAnswer(
        (_) async => const Failure<String>(ValidationError('too large')),
      );

      final result = await repo.createPost(
        draft: const PostDraft(title: 't', description: 'd', imagePath: '/x'),
        uid: 'u',
        uEmail: 'e',
        uName: 'n',
      );
      expect((result as Failure<Post>).error, isA<ValidationError>());
      verifyNever(() => posts.createPost(
            pTitle: any(named: 'pTitle'),
            pDescription: any(named: 'pDescription'),
            pImage: any(named: 'pImage'),
            uid: any(named: 'uid'),
            uEmail: any(named: 'uEmail'),
            uName: any(named: 'uName'),
          ));
    });

    test('updatePost maps permission-denied → PermissionError', () async {
      when(() => posts.updatePost(
            pId: any(named: 'pId'),
            title: any(named: 'title'),
            description: any(named: 'description'),
          )).thenThrow(
        FirebaseException(plugin: 'firestore', code: 'permission-denied'),
      );
      final result = await repo.updatePost(
        pId: 'p1',
        uid: 'u1',
        title: 't',
        description: 'd',
      );
      expect((result as Failure<void>).error, isA<PermissionError>());
    });

    test('deletePost maps unavailable → NetworkError', () async {
      when(() => posts.deletePost(any())).thenThrow(
        FirebaseException(plugin: 'firestore', code: 'unavailable'),
      );
      final result = await repo.deletePost(pId: 'p1', uid: 'u1');
      expect((result as Failure<void>).error, isA<NetworkError>());
    });

    test('toggleLikePost happy path', () async {
      when(() => posts.toggleLikePost(
            pId: any(named: 'pId'),
            uid: any(named: 'uid'),
          )).thenAnswer((_) async {});
      final result = await repo.toggleLikePost(pId: 'p1', uid: 'u1');
      expect(result, isA<Success<void>>());
    });

    test('getPost returns NotFoundError when doc missing', () async {
      when(() => posts.getPost(any())).thenAnswer((_) async => null);
      final result = await repo.getPost('p1');
      expect((result as Failure<Post>).error, isA<NotFoundError>());
    });
  });

  group('CommentsRepositoryImpl', () {
    late _MockCommentsDs ds;
    late CommentsRepositoryImpl repo;

    setUp(() {
      ds = _MockCommentsDs();
      repo = CommentsRepositoryImpl(ds);
    });

    test('addComment trims and rejects empty text', () async {
      final result = await repo.addComment(
        pId: 'p1',
        text: '   ',
        commentedBy: 'u',
        commentedByName: 'U',
      );
      expect((result as Failure<void>).error, isA<ValidationError>());
      verifyNever(() => ds.addComment(
            pId: any(named: 'pId'),
            text: any(named: 'text'),
            commentedBy: any(named: 'commentedBy'),
            commentedByName: any(named: 'commentedByName'),
          ));
    });

    test('addComment rejects > 500 chars', () async {
      final result = await repo.addComment(
        pId: 'p1',
        text: 'x' * 501,
        commentedBy: 'u',
        commentedByName: 'U',
      );
      expect((result as Failure<void>).error, isA<ValidationError>());
    });

    test('addComment happy path', () async {
      when(() => ds.addComment(
            pId: any(named: 'pId'),
            text: any(named: 'text'),
            commentedBy: any(named: 'commentedBy'),
            commentedByName: any(named: 'commentedByName'),
          )).thenAnswer((_) async {});
      final result = await repo.addComment(
        pId: 'p1',
        text: 'hi',
        commentedBy: 'u',
        commentedByName: 'U',
      );
      expect(result, isA<Success<void>>());
    });

    test('deleteComment maps permission-denied', () async {
      when(() => ds.deleteComment(
            pId: any(named: 'pId'),
            commentId: any(named: 'commentId'),
          )).thenThrow(
        FirebaseException(plugin: 'firestore', code: 'permission-denied'),
      );
      final result = await repo.deleteComment(
        pId: 'p1',
        commentId: 'c1',
        uid: 'u-other',
      );
      expect((result as Failure<void>).error, isA<PermissionError>());
    });
  });

  group('PostImageStorageRepositoryImpl', () {
    late _MockStorageDs ds;
    late PostImageStorageRepositoryImpl repo;

    setUp(() {
      ds = _MockStorageDs();
      repo = PostImageStorageRepositoryImpl(ds);
    });

    test('returns Success(url) on happy path', () async {
      when(() => ds.uploadPostImage(
            uid: any(named: 'uid'),
            imagePath: any(named: 'imagePath'),
          )).thenAnswer((_) async => 'https://img');
      final result = await repo.uploadPostImage(uid: 'u', imagePath: '/x');
      expect((result as Success<String>).value, 'https://img');
    });

    test('maps PostImageTooLargeException → ValidationError', () async {
      when(() => ds.uploadPostImage(
            uid: any(named: 'uid'),
            imagePath: any(named: 'imagePath'),
          )).thenThrow(const PostImageTooLargeException());
      final result = await repo.uploadPostImage(uid: 'u', imagePath: '/x');
      expect((result as Failure<String>).error, isA<ValidationError>());
    });

    test('maps generic failures → UnknownError', () async {
      when(() => ds.uploadPostImage(
            uid: any(named: 'uid'),
            imagePath: any(named: 'imagePath'),
          )).thenThrow(StateError('bad'));
      final result = await repo.uploadPostImage(uid: 'u', imagePath: '/x');
      expect((result as Failure<String>).error, isA<UnknownError>());
    });
  });
}
