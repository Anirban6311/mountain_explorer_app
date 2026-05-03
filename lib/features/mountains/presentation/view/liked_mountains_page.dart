import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../cubit/mountains_cubit.dart';
import '../cubit/mountains_state.dart';

class LikedMountainsPage extends StatelessWidget {
  const LikedMountainsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ThemedAppBar(title: 'Liked mountains'),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          final isAnonymous = switch (authState) {
            Authenticated(:final user) => user.isAnonymous,
            _ => true,
          };
          if (isAnonymous) {
            return EmptyState(
              message: 'Sign up to save and view your favourite mountains.',
              icon: Icons.favorite_border,
              actionLabel: 'Sign up',
              onAction: () => context.push(Routes.signup),
            );
          }
          return BlocBuilder<MountainsCubit, MountainsState>(
            builder: (context, state) {
              if (state is! MountainsLoaded) {
                return const Center(child: CircularProgressIndicator());
              }
              final liked = state.mountains
                  .where((m) => state.likedIds.contains(m.id))
                  .toList(growable: false);
              if (liked.isEmpty) {
                return const EmptyState(
                  message: 'You have not liked any mountains yet.',
                  icon: Icons.favorite_border,
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: liked.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (_, i) => AppCard(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(liked[i].name),
                    subtitle: Text(
                      liked[i].description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
