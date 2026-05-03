import 'package:basic_crud_flutter/core/errors/app_error.dart';
import 'package:basic_crud_flutter/core/errors/result.dart';
import 'package:basic_crud_flutter/features/community/domain/entities/comment.dart';
import 'package:basic_crud_flutter/features/community/domain/entities/post.dart';
import 'package:basic_crud_flutter/features/community/domain/entities/post_draft.dart';
import 'package:basic_crud_flutter/features/community/domain/repositories/comments_repository.dart';
import 'package:basic_crud_flutter/features/community/domain/repositories/posts_repository.dart';
import 'package:basic_crud_flutter/features/community/domain/usecases/community_usecases.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockPostsRepo extends Mock implements PostsRepository {}

class _MockCommentsRepo extends Mock implements CommentsRepository {}

Post _post(String id) => Post(
      pId: id,
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
  late _MockPostsRepo posts;
  late _MockCommentsRepo comments;

  setUp(() {
    posts = _MockPostsRepo();
    comments = _MockCommentsRepo();
    registerFallbackValue(const PostDraft());
  });

  group('WatchFeed / WatchComments stream passthrough', () {
    test('WatchFeed forwards repo stream', () async {
      when(() => posts.watchFeed()).thenAnswer(
        (_) => Stream.value([_post('a'), _post('b')]),
      );
      expect(await WatchFeed(posts)().first, hasLength(2));
    });

    test('WatchComments forwards repo stream', () async {
      final list = [
        Comment(
          cId: 'c',
          text: 'hi',
          commentedBy: 'u1',
          commentedByName: 'U',
          commentedAt: DateTime(2026),
        ),
      ];
      when(() => comments.watchComments(any()))
          .thenAnswer((_) => Stream.value(list));
      expect(await WatchComments(comments)('p1').first, list);
    });
  });

  group('CreatePost', () {
    test('delegates to repo and returns Success', () async {
      when(() => posts.createPost(
            draft: any(named: 'draft'),
            uid: any(named: 'uid'),
            uEmail: any(named: 'uEmail'),
            uName: any(named: 'uName'),
          )).thenAnswer((_) async => Success<Post>(_post('a')));
      final result = await CreatePost(posts)(
        draft: const PostDraft(
          title: 't',
          description: 'd',
          imagePath: '/tmp/x',
        ),
        uid: 'u1',
        uEmail: 'u@e',
        uName: 'U',
      );
      expect((result as Success<Post>).value.pId, 'a');
    });

    test('propagates ValidationError', () async {
      when(() => posts.createPost(
            draft: any(named: 'draft'),
            uid: any(named: 'uid'),
            uEmail: any(named: 'uEmail'),
            uName: any(named: 'uName'),
          )).thenAnswer(
        (_) async => const Failure<Post>(ValidationError('too large')),
      );
      final result = await CreatePost(posts)(
        draft: const PostDraft(title: 't', description: 'd', imagePath: '/x'),
        uid: 'u',
        uEmail: 'e',
        uName: 'n',
      );
      expect((result as Failure<Post>).error, isA<ValidationError>());
    });
  });

  group('UpdatePost / DeletePost / ToggleLikePost', () {
    test('UpdatePost forwards args', () async {
      when(() => posts.updatePost(
            pId: any(named: 'pId'),
            uid: any(named: 'uid'),
            title: any(named: 'title'),
            description: any(named: 'description'),
          )).thenAnswer((_) async => const Success<void>(null));
      final result = await UpdatePost(posts)(
        pId: 'p1',
        uid: 'u1',
        title: 'new',
        description: 'body',
      );
      expect(result, isA<Success<void>>());
      verify(() => posts.updatePost(
            pId: 'p1',
            uid: 'u1',
            title: 'new',
            description: 'body',
          )).called(1);
    });

    test('DeletePost forwards args', () async {
      when(() => posts.deletePost(
            pId: any(named: 'pId'),
            uid: any(named: 'uid'),
          )).thenAnswer((_) async => const Success<void>(null));
      await DeletePost(posts)(pId: 'p1', uid: 'u1');
      verify(() => posts.deletePost(pId: 'p1', uid: 'u1')).called(1);
    });

    test('ToggleLikePost forwards args', () async {
      when(() => posts.toggleLikePost(
            pId: any(named: 'pId'),
            uid: any(named: 'uid'),
          )).thenAnswer((_) async => const Success<void>(null));
      await ToggleLikePost(posts)(pId: 'p1', uid: 'u1');
      verify(() => posts.toggleLikePost(pId: 'p1', uid: 'u1')).called(1);
    });
  });

  group('AddComment / DeleteComment', () {
    test('AddComment forwards', () async {
      when(() => comments.addComment(
            pId: any(named: 'pId'),
            text: any(named: 'text'),
            commentedBy: any(named: 'commentedBy'),
            commentedByName: any(named: 'commentedByName'),
          )).thenAnswer((_) async => const Success<void>(null));
      await AddComment(comments)(
        pId: 'p1',
        text: 'hi',
        commentedBy: 'u1',
        commentedByName: 'U',
      );
      verify(() => comments.addComment(
            pId: 'p1',
            text: 'hi',
            commentedBy: 'u1',
            commentedByName: 'U',
          )).called(1);
    });

    test('DeleteComment forwards', () async {
      when(() => comments.deleteComment(
            pId: any(named: 'pId'),
            commentId: any(named: 'commentId'),
            uid: any(named: 'uid'),
          )).thenAnswer((_) async => const Success<void>(null));
      await DeleteComment(comments)(pId: 'p1', commentId: 'c1', uid: 'u1');
      verify(() => comments.deleteComment(
            pId: 'p1',
            commentId: 'c1',
            uid: 'u1',
          )).called(1);
    });

    test('DeleteComment propagates PermissionError', () async {
      when(() => comments.deleteComment(
            pId: any(named: 'pId'),
            commentId: any(named: 'commentId'),
            uid: any(named: 'uid'),
          )).thenAnswer(
        (_) async => const Failure<void>(PermissionError('denied')),
      );
      final result = await DeleteComment(comments)(
        pId: 'p1',
        commentId: 'c1',
        uid: 'u-other',
      );
      expect((result as Failure<void>).error, isA<PermissionError>());
    });
  });

  group('GetPost', () {
    test('returns Success', () async {
      when(() => posts.getPost(any()))
          .thenAnswer((_) async => Success<Post>(_post('a')));
      final result = await GetPost(posts)('a');
      expect((result as Success<Post>).value.pId, 'a');
    });
  });
}
