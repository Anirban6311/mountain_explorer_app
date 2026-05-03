import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../cubit/feed_cubit.dart';
import '../widgets/post_card.dart';

class FeedPage extends StatelessWidget {
  const FeedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ThemedAppBar(title: 'Community'),
      body: const _FeedView(),
      floatingActionButton: _CreateFab(),
    );
  }
}

class _FeedView extends StatefulWidget {
  const _FeedView();

  @override
  State<_FeedView> createState() => _FeedViewState();
}

class _FeedViewState extends State<_FeedView> {
  @override
  void initState() {
    super.initState();
    context.read<FeedCubit>().subscribe();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FeedCubit, FeedState>(
      builder: (context, state) {
        return switch (state) {
          FeedInitial() || FeedLoading() =>
            const Center(child: CircularProgressIndicator()),
          FeedError(:final message) => ErrorView(
              message: message,
              onRetry: () => context.read<FeedCubit>().subscribe(),
            ),
          FeedLoaded(:final posts) => posts.isEmpty
              ? const EmptyState(
                  message: 'No posts yet. Be the first to share a trip!',
                  icon: Icons.forum_outlined,
                )
              : _FeedList(posts: posts),
        };
      },
    );
  }
}

class _FeedList extends StatelessWidget {
  final List posts;
  const _FeedList({required this.posts});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final uid = switch (authState) {
      Authenticated(:final user) => user.uid,
      _ => '',
    };
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: posts.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (_, i) {
        final post = posts[i];
        return AppCard(
          onTap: () => context.push('/community/post/${post.pId}'),
          child: PostCard(
            post: post,
            isLikedByCurrentUser: post.likes.contains(uid),
            onTap: () => context.push('/community/post/${post.pId}'),
            onLike: uid.isEmpty
                ? null
                : () => context
                    .read<FeedCubit>()
                    .toggleLike(postId: post.pId, uid: uid),
          ),
        );
      },
    );
  }
}

class _CreateFab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final canPost = switch (state) {
          Authenticated(:final user) =>
            !user.isAnonymous && user.isEmailVerified,
          _ => false,
        };
        if (!canPost) return const SizedBox.shrink();
        return FloatingActionButton.extended(
          // Distinct heroTag — feed page sits inside HomeShell which
          // also overlays SosFab on certain tabs.
          heroTag: 'community_feed_fab',
          icon: const Icon(Icons.add),
          label: const Text('New post'),
          onPressed: () => context.push(Routes.createPost),
        );
      },
    );
  }
}
