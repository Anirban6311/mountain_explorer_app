import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: const ThemedAppBar(title: 'Profile'),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          final user = switch (state) {
            Authenticated(:final user) => user,
            NeedsVerification(:final user) => user,
            _ => null,
          };
          if (user == null) {
            return const EmptyState(
              message: 'You are not signed in.',
              icon: Icons.person_outline,
            );
          }
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.lg),
                CircleAvatar(
                  radius: 44,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  backgroundImage: (user.photoUrl != null &&
                          user.photoUrl!.isNotEmpty)
                      ? NetworkImage(user.photoUrl!)
                      : null,
                  child: (user.photoUrl == null || user.photoUrl!.isEmpty)
                      ? const Icon(
                          Icons.person,
                          size: 44,
                          color: AppColors.primary,
                        )
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  user.isAnonymous
                      ? 'Guest user'
                      : (user.displayName ?? 'Signed in'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge,
                ),
                if (user.email != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    user.email!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.slate600,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                _VerificationChip(
                  isVerified: user.isEmailVerified,
                  isAnonymous: user.isAnonymous,
                ),
                const SizedBox(height: AppSpacing.lg),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.settings_outlined),
                  title: const Text('Settings'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(Routes.settings),
                ),
                const Spacer(),
                AppButton(
                  label: 'Sign out',
                  variant: AppButtonVariant.secondary,
                  icon: Icons.logout,
                  onPressed: () => context.read<AuthCubit>().signOut(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _VerificationChip extends StatelessWidget {
  final bool isVerified;
  final bool isAnonymous;
  const _VerificationChip({
    required this.isVerified,
    required this.isAnonymous,
  });

  @override
  Widget build(BuildContext context) {
    if (isAnonymous) {
      return _chip(
        'Anonymous session',
        Icons.person_outline,
        AppColors.slate600,
      );
    }
    if (isVerified) {
      return _chip('Email verified', Icons.verified, AppColors.success);
    }
    return _chip('Email unverified', Icons.info_outline, AppColors.secondary);
  }

  Widget _chip(String label, IconData icon, Color color) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: AppSpacing.xs),
          Text(label, style: TextStyle(color: color)),
        ],
      ),
    );
  }
}
