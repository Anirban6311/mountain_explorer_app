import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/widgets.dart';
import '../cubit/login_state.dart';
import '../cubit/signup_cubit.dart';
import '../cubit/signup_state.dart';

class SignupPage extends StatelessWidget {
  const SignupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SignupCubit>(
      create: (_) => getIt<SignupCubit>(),
      child: const _SignupView(),
    );
  }
}

class _SignupView extends StatelessWidget {
  const _SignupView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: const ThemedAppBar(title: 'Create account'),
      body: BlocConsumer<SignupCubit, SignupState>(
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
          final cubit = context.read<SignupCubit>();
          return LoadingOverlay(
            isLoading: state.status == FormStatus.submitting,
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Join the mountain community',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    AppTextField(
                      label: 'Name',
                      onChanged: cubit.nameChanged,
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      label: 'Email',
                      keyboardType: TextInputType.emailAddress,
                      onChanged: cubit.emailChanged,
                      prefixIcon: const Icon(Icons.email_outlined),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppPasswordField(
                      label: 'Password',
                      onChanged: cubit.passwordChanged,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppButton(
                      label: 'Create account',
                      onPressed: cubit.submit,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Center(
                      child: TextButton(
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go(Routes.login);
                          }
                        },
                        child: const Text('Already have an account? Log in'),
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
