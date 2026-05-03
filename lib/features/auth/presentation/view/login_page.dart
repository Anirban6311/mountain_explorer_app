import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/widgets.dart';
import '../cubit/login_cubit.dart';
import '../cubit/login_state.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<LoginCubit>(
      create: (_) => getIt<LoginCubit>(),
      child: const _LoginView(),
    );
  }
}

class _LoginView extends StatelessWidget {
  const _LoginView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: const ThemedAppBar(title: 'Welcome back'),
      body: BlocConsumer<LoginCubit, LoginState>(
        listenWhen: (prev, curr) => prev.status != curr.status,
        listener: (context, state) {
          if (state.status == FormStatus.failure &&
              state.errorMessage != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(state.errorMessage!)));
          }
        },
        builder: (context, state) {
          return LoadingOverlay(
            isLoading: state.status == FormStatus.submitting,
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Sign in to continue',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    AppTextField(
                      label: 'Email',
                      keyboardType: TextInputType.emailAddress,
                      onChanged: context.read<LoginCubit>().emailChanged,
                      prefixIcon: const Icon(Icons.email_outlined),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppPasswordField(
                      label: 'Password',
                      onChanged: context.read<LoginCubit>().passwordChanged,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => context.push(Routes.forgotPassword),
                        child: const Text('Forgot password?'),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppButton(
                      label: 'Log in',
                      onPressed: () => context.read<LoginCubit>().submit(),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppButton(
                      label: 'Continue with Google',
                      variant: AppButtonVariant.secondary,
                      icon: Icons.g_mobiledata,
                      onPressed: () =>
                          context.read<LoginCubit>().signInWithGoogle(),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppButton(
                      label: 'Continue as guest',
                      variant: AppButtonVariant.tertiary,
                      onPressed: () =>
                          context.read<LoginCubit>().continueAsGuest(),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Center(
                      child: TextButton(
                        onPressed: () => context.push(Routes.signup),
                        child: RichText(
                          text: TextSpan(
                            style: theme.textTheme.bodyMedium,
                            children: [
                              const TextSpan(text: "Don't have an account? "),
                              TextSpan(
                                text: 'Sign up',
                                style: theme.textTheme.labelLarge
                                    ?.copyWith(color: AppColors.primary),
                              ),
                            ],
                          ),
                        ),
                      ),
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
