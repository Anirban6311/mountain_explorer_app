import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/widgets.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/verify_email_cubit.dart';
import '../cubit/verify_email_state.dart';

class VerifyEmailPage extends StatelessWidget {
  const VerifyEmailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<VerifyEmailCubit>(
      create: (_) => getIt<VerifyEmailCubit>(),
      child: const _VerifyEmailView(),
    );
  }
}

class _VerifyEmailView extends StatelessWidget {
  const _VerifyEmailView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: const ThemedAppBar(title: 'Verify your email'),
      body: BlocConsumer<VerifyEmailCubit, VerifyEmailState>(
        listenWhen: (prev, curr) => prev.status != curr.status,
        listener: (context, state) {
          final messenger = ScaffoldMessenger.of(context);
          switch (state.status) {
            case VerifyStatus.resent:
              messenger
                ..hideCurrentSnackBar()
                ..showSnackBar(const SnackBar(
                  content: Text('Verification email sent.'),
                ));
            case VerifyStatus.notVerifiedYet:
              messenger
                ..hideCurrentSnackBar()
                ..showSnackBar(const SnackBar(
                  content: Text(
                    'Not verified yet. Check your inbox and try again.',
                  ),
                ));
            case VerifyStatus.error:
              if (state.errorMessage != null) {
                messenger
                  ..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(content: Text(state.errorMessage!)));
              }
            case VerifyStatus.idle:
            case VerifyStatus.sending:
            case VerifyStatus.checking:
            case VerifyStatus.verified:
              break;
          }
        },
        builder: (context, state) {
          final cubit = context.read<VerifyEmailCubit>();
          final isBusy = state.status == VerifyStatus.sending ||
              state.status == VerifyStatus.checking;
          return LoadingOverlay(
            isLoading: isBusy,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpacing.xl),
                    Icon(
                      Icons.mark_email_unread_outlined,
                      size: 72,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Check your inbox',
                      style: theme.textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      "We sent you a verification link. Tap it, then come "
                      "back here and press \"I've verified\".",
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const Spacer(),
                    AppButton(
                      label: "I've verified",
                      onPressed: cubit.checkVerified,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppButton(
                      label: 'Resend email',
                      variant: AppButtonVariant.secondary,
                      onPressed: cubit.resendVerification,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppButton(
                      label: 'Sign out',
                      variant: AppButtonVariant.tertiary,
                      onPressed: () =>
                          context.read<AuthCubit>().signOut(),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
