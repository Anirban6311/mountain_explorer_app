import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../domain/usecases/community_usecases.dart';
import '../cubit/post_detail_cubit.dart';
import '../widgets/comment_row.dart';

class PostDetailPage extends StatelessWidget {
  final String postId;
  const PostDetailPage({super.key, required this.postId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PostDetailCubit>(
      create: (_) => PostDetailCubit(
        postId: postId,
        getPost: getIt<GetPost>(),
        watchComments: getIt<WatchComments>(),
        addComment: getIt<AddComment>(),
        deleteComment: getIt<DeleteComment>(),
        deletePost: getIt<DeletePost>(),
        toggleLikePost: getIt<ToggleLikePost>(),
      )..load(),
      child: _PostDetailView(postId: postId),
    );
  }
}

class _PostDetailView extends StatefulWidget {
  final String postId;
  const _PostDetailView({required this.postId});

  @override
  State<_PostDetailView> createState() => _PostDetailViewState();
}

class _PostDetailViewState extends State<_PostDetailView> {
  final _commentCtrl = TextEditingController();

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final currentUser = switch (authState) {
      Authenticated(:final user) => user,
      _ => null,
    };
    return Scaffold(
      appBar: ThemedAppBar(
        title: 'Post',
        actions: [
          BlocBuilder<PostDetailCubit, PostDetailState>(
            builder: (context, state) {
              final isOwner =
                  state.post != null && state.post!.uid == currentUser?.uid;
              if (!isOwner) return const SizedBox.shrink();
              return PopupMenuButton<String>(
                onSelected: (v) async {
                  if (v == 'edit') {
                    context.push(Routes.editPost(widget.postId));
                  }
                  if (v == 'delete') {
                    await _confirmDelete(context);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<PostDetailCubit, PostDetailState>(
        listenWhen: (p, c) => p.errorMessage != c.errorMessage,
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(state.errorMessage!)));
          }
        },
        builder: (context, state) {
          if (state.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          final post = state.post;
          if (post == null) {
            return const EmptyState(
              message: 'That post could not be loaded.',
              icon: Icons.sentiment_dissatisfied,
            );
          }
          return Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (post.pImage.isNotEmpty)
                              AspectRatio(
                                aspectRatio: 16 / 9,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: CachedNetworkImage(
                                    imageUrl: post.pImage,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            const SizedBox(height: AppSpacing.md),
                            Text(post.pTitle,
                                style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: AppSpacing.sm),
                            Text(post.pDescription),
                            const SizedBox(height: AppSpacing.md),
                            Row(
                              children: [
                                IconButton(
                                  onPressed: currentUser == null ||
                                          currentUser.isAnonymous
                                      ? null
                                      : () => context
                                          .read<PostDetailCubit>()
                                          .toggleLike(currentUser.uid),
                                  icon: Icon(
                                    post.likes.contains(currentUser?.uid)
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: AppColors.error,
                                  ),
                                ),
                                Text('${post.likes.length} likes'),
                              ],
                            ),
                            const Divider(height: AppSpacing.xl),
                            Text(
                              'Comments',
                              style:
                                  Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (state.comments.isEmpty)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(AppSpacing.lg),
                          child: Text('Be the first to comment.'),
                        ),
                      )
                    else
                      SliverList.separated(
                        itemCount: state.comments.length,
                        itemBuilder: (_, i) {
                          final c = state.comments[i];
                          final isOwner =
                              c.commentedBy == currentUser?.uid;
                          return CommentRow(
                            comment: c,
                            canDelete: isOwner,
                            onDelete: isOwner
                                ? () => context
                                    .read<PostDetailCubit>()
                                    .deleteComment(c.cId, currentUser!.uid)
                                : null,
                          );
                        },
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1),
                      ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 80),
                    ),
                  ],
                ),
              ),
              _CommentInput(
                controller: _commentCtrl,
                enabled: currentUser != null &&
                    !currentUser.isAnonymous &&
                    currentUser.isEmailVerified,
                submitting: state.submittingComment,
                onSubmit: (text) async {
                  if (currentUser == null) return;
                  final result = await context
                      .read<PostDetailCubit>()
                      .submitComment(
                        text: text,
                        uid: currentUser.uid,
                        name: currentUser.displayName ?? 'Explorer',
                      );
                  if (!context.mounted) return;
                  if (result is Success) _commentCtrl.clear();
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete post?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final authState = context.read<AuthCubit>().state;
    final uid = switch (authState) {
      Authenticated(:final user) => user.uid,
      _ => '',
    };
    final result = await context.read<PostDetailCubit>().deletePost(uid);
    if (!context.mounted) return;
    if (result is Success) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(Routes.feed);
      }
    } else if (result is Failure) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text((result).error.message)));
    }
  }
}

class _CommentInput extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final bool submitting;
  final ValueChanged<String> onSubmit;

  const _CommentInput({
    required this.controller,
    required this.enabled,
    required this.submitting,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  enabled: enabled,
                  maxLength: 500,
                  decoration: InputDecoration(
                    hintText: enabled
                        ? 'Write a comment…'
                        : 'Sign in with a verified email to comment',
                    counterText: '',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.sm,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton.filled(
                onPressed: !enabled || submitting
                    ? null
                    : () {
                        final t = controller.text.trim();
                        if (t.isEmpty) return;
                        onSubmit(t);
                      },
                icon: submitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
