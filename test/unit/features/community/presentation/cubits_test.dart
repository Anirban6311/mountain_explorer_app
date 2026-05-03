import 'dart:async';

import 'package:basic_crud_flutter/core/errors/app_error.dart';
import 'package:basic_crud_flutter/core/errors/result.dart';
import 'package:basic_crud_flutter/features/community/domain/entities/comment.dart';
import 'package:basic_crud_flutter/features/community/domain/entities/post.dart';
import 'package:basic_crud_flutter/features/community/domain/entities/post_draft.dart';
import 'package:basic_crud_flutter/features/community/domain/repositories/comments_repository.dart';
import 'package:basic_crud_flutter/features/community/domain/repositories/posts_repository.dart';
import 'package:basic_crud_flutter/features/community/domain/usecases/community_usecases.dart';
import 'package:basic_crud_flutter/features/community/presentation/cubit/create_post_cubit.dart';
import 'package:basic_crud_flutter/features/community/presentation/cubit/edit_post_cubit.dart';
import 'package:basic_crud_flutter/features/community/presentation/cubit/feed_cubit.dart';
import 'package:basic_crud_flutter/features/community/presentation/cubit/post_detail_cubit.dart';
import 'package:bloc_test/bloc_test.dart';
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

Comment _comment(String id) => Comment(
      cId: id,
      text: 'hi',
      commentedBy: 'u1',
      commentedByName: 'U',
      commentedAt: DateTime(2026),
    );

void main() {
  setUpAll(() {
    registerFallbackValue(const PostDraft());
  });

  group('FeedCubit', () {
    late _MockPostsRepo repo;
    setUp(() {
      repo = _MockPostsRepo();
    });

    blocTest<FeedCubit, FeedState>(
      'subscribe() emits Loading then Loaded',
      build: () => FeedCubit(
        watchFeed: WatchFeed(repo),
        toggleLikePost: ToggleLikePost(repo),
      ),
      setUp: () {
        when(() => repo.watchFeed()).thenAnswer(
          (_) => Stream.value([_post('a'), _post('b')]),
        );
      },
      act: (c) => c.subscribe(),
      expect: () => [
        isA<FeedLoading>(),
        isA<FeedLoaded>().having((s) => s.posts.length, 'len', 2),
      ],
    );

    blocTest<FeedCubit, FeedState>(
      'subscribe() emits Error on stream error',
      build: () => FeedCubit(
        watchFeed: WatchFeed(repo),
        toggleLikePost: ToggleLikePost(repo),
      ),
      setUp: () {
        when(() => repo.watchFeed()).thenAnswer(
          (_) => Stream<List<Post>>.error(StateError('boom')),
        );
      },
      act: (c) async {
        c.subscribe();
        await Future<void>.delayed(Duration.zero);
      },
      expect: () => [
        isA<FeedLoading>(),
        isA<FeedError>(),
      ],
    );

    blocTest<FeedCubit, FeedState>(
      'calling subscribe twice is idempotent',
      build: () => FeedCubit(
        watchFeed: WatchFeed(repo),
        toggleLikePost: ToggleLikePost(repo),
      ),
      setUp: () {
        when(() => repo.watchFeed())
            .thenAnswer((_) => const Stream<List<Post>>.empty());
      },
      act: (c) {
        c.subscribe();
        c.subscribe();
      },
      expect: () => [isA<FeedLoading>()],
      verify: (_) => verify(() => repo.watchFeed()).called(1),
    );
  });

  group('CreatePostCubit', () {
    late _MockPostsRepo repo;
    setUp(() => repo = _MockPostsRepo());

    blocTest<CreatePostCubit, CreatePostState>(
      'submit with missing image emits failure without repo call',
      build: () => CreatePostCubit(createPost: CreatePost(repo)),
      seed: () => const CreatePostState(
        draft: PostDraft(title: 't', description: 'd'),
      ),
      act: (c) => c.submit(uid: 'u', uEmail: 'e', uName: 'n'),
      expect: () => [
        isA<CreatePostState>()
            .having((s) => s.status, 'status', CreatePostStatus.failure)
            .having((s) => s.errorMessage, 'err', contains('image')),
      ],
      verify: (_) => verifyNever(() => repo.createPost(
            draft: any(named: 'draft'),
            uid: any(named: 'uid'),
            uEmail: any(named: 'uEmail'),
            uName: any(named: 'uName'),
          )),
    );

    blocTest<CreatePostCubit, CreatePostState>(
      'submit happy path emits submitting → success',
      build: () {
        when(() => repo.createPost(
              draft: any(named: 'draft'),
              uid: any(named: 'uid'),
              uEmail: any(named: 'uEmail'),
              uName: any(named: 'uName'),
            )).thenAnswer((_) async => Success<Post>(_post('a')));
        return CreatePostCubit(createPost: CreatePost(repo));
      },
      seed: () => const CreatePostState(
        draft: PostDraft(title: 't', description: 'd', imagePath: '/x'),
      ),
      act: (c) => c.submit(uid: 'u1', uEmail: 'u@e', uName: 'U'),
      expect: () => [
        isA<CreatePostState>()
            .having((s) => s.status, 'status', CreatePostStatus.submitting),
        isA<CreatePostState>()
            .having((s) => s.status, 'status', CreatePostStatus.success)
            .having((s) => s.created?.pId, 'id', 'a'),
      ],
    );

    blocTest<CreatePostCubit, CreatePostState>(
      'submit maps ValidationError from repo',
      build: () {
        when(() => repo.createPost(
              draft: any(named: 'draft'),
              uid: any(named: 'uid'),
              uEmail: any(named: 'uEmail'),
              uName: any(named: 'uName'),
            )).thenAnswer(
          (_) async => const Failure<Post>(ValidationError('too big')),
        );
        return CreatePostCubit(createPost: CreatePost(repo));
      },
      seed: () => const CreatePostState(
        draft: PostDraft(title: 't', description: 'd', imagePath: '/x'),
      ),
      act: (c) => c.submit(uid: 'u', uEmail: 'e', uName: 'n'),
      expect: () => [
        isA<CreatePostState>()
            .having((s) => s.status, 'status', CreatePostStatus.submitting),
        isA<CreatePostState>()
            .having((s) => s.status, 'status', CreatePostStatus.failure)
            .having((s) => s.errorMessage, 'err', 'too big'),
      ],
    );
  });

  group('EditPostCubit', () {
    late _MockPostsRepo repo;
    setUp(() => repo = _MockPostsRepo());

    blocTest<EditPostCubit, EditPostState>(
      'seedFrom sets title/description from post',
      build: () => EditPostCubit(pId: 'p1', updatePost: UpdatePost(repo)),
      act: (c) => c.seedFrom(_post('p1')),
      expect: () => [
        isA<EditPostState>()
            .having((s) => s.title, 'title', 't')
            .having((s) => s.description, 'desc', 'd'),
      ],
    );

    blocTest<EditPostCubit, EditPostState>(
      'submit with empty title emits failure',
      build: () => EditPostCubit(pId: 'p1', updatePost: UpdatePost(repo)),
      seed: () => const EditPostState(title: '', description: 'd'),
      act: (c) => c.submit('u'),
      expect: () => [
        isA<EditPostState>()
            .having((s) => s.status, 'status', EditPostStatus.failure),
      ],
    );

    blocTest<EditPostCubit, EditPostState>(
      'submit happy path',
      build: () {
        when(() => repo.updatePost(
              pId: any(named: 'pId'),
              uid: any(named: 'uid'),
              title: any(named: 'title'),
              description: any(named: 'description'),
            )).thenAnswer((_) async => const Success<void>(null));
        return EditPostCubit(pId: 'p1', updatePost: UpdatePost(repo));
      },
      seed: () => const EditPostState(title: 'new', description: 'body'),
      act: (c) => c.submit('u1'),
      expect: () => [
        isA<EditPostState>()
            .having((s) => s.status, 'status', EditPostStatus.submitting),
        isA<EditPostState>()
            .having((s) => s.status, 'status', EditPostStatus.success),
      ],
    );
  });

  group('PostDetailCubit', () {
    late _MockPostsRepo posts;
    late _MockCommentsRepo comments;

    PostDetailCubit build() => PostDetailCubit(
          postId: 'p1',
          getPost: GetPost(posts),
          watchComments: WatchComments(comments),
          addComment: AddComment(comments),
          deleteComment: DeleteComment(comments),
          deletePost: DeletePost(posts),
          toggleLikePost: ToggleLikePost(posts),
        );

    setUp(() {
      posts = _MockPostsRepo();
      comments = _MockCommentsRepo();
    });

    blocTest<PostDetailCubit, PostDetailState>(
      'load() populates post + subscribes to comments',
      build: () {
        when(() => posts.getPost(any()))
            .thenAnswer((_) async => Success<Post>(_post('p1')));
        when(() => comments.watchComments(any())).thenAnswer(
          (_) => Stream.value([_comment('c1')]),
        );
        return build();
      },
      act: (c) async {
        await c.load();
        await Future<void>.delayed(Duration.zero);
      },
      expect: () => [
        isA<PostDetailState>().having((s) => s.post?.pId, 'post', 'p1'),
        isA<PostDetailState>().having((s) => s.comments.length, 'n', 1),
      ],
    );

    blocTest<PostDetailCubit, PostDetailState>(
      'load() surfaces NotFoundError as errorMessage',
      build: () {
        when(() => posts.getPost(any())).thenAnswer(
          (_) async => const Failure<Post>(NotFoundError('gone')),
        );
        return build();
      },
      act: (c) => c.load(),
      expect: () => [
        isA<PostDetailState>()
            .having((s) => s.loading, 'loading', false)
            .having((s) => s.errorMessage, 'err', 'gone'),
      ],
    );

    blocTest<PostDetailCubit, PostDetailState>(
      'submitComment delegates and emits submitting → idle',
      build: () {
        when(() => comments.addComment(
              pId: any(named: 'pId'),
              text: any(named: 'text'),
              commentedBy: any(named: 'commentedBy'),
              commentedByName: any(named: 'commentedByName'),
            )).thenAnswer((_) async => const Success<void>(null));
        return build();
      },
      act: (c) => c.submitComment(text: 'hi', uid: 'u', name: 'U'),
      expect: () => [
        isA<PostDetailState>()
            .having((s) => s.submittingComment, 'submitting', true),
        isA<PostDetailState>()
            .having((s) => s.submittingComment, 'submitting', false),
      ],
    );
  });
}
