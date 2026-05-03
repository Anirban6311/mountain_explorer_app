import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/widgets.dart';
import '../cubit/forgot_password_cubit.dart';
import '../cubit/forgot_password_state.dart';
import '../cubit/login_state.dart';

class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ForgotPasswordCubit>(
      create: (_) => getIt<ForgotPasswordCubit>(),
      child: const _ForgotPasswordView(),
    );
  }
}

class _ForgotPasswordView extends StatefulWidget {
  const _ForgotPasswordView();

  @override
  State<_ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<_ForgotPasswordView> {
  Timer? _autoReturn;

  @override
  void dispose() {
    _autoReturn?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: const ThemedAppBar(title: 'Reset password'),
      body: BlocConsumer<ForgotPasswordCubit, ForgotPasswordState>(
        listenWhen: (prev, curr) => prev.status != curr.status,
        listener: (context, state) {
          switch (state.status) {
            case FormStatus.success:
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(const SnackBar(
                  content: Text('Reset link sent. Check your email.'),
                ));
              _autoReturn?.cancel();
              _autoReturn = Timer(const Duration(seconds: 2), () {
                if (!mounted) return;
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(Routes.login);
                }
              });
            case FormStatus.failure:
              if (state.errorMessage != null) {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(content: Text(state.errorMessage!)));
              }
            case FormStatus.initial:
            case FormStatus.submitting:
              break;
          }
        },
        builder: (context, state) {
          final cubit = context.read<ForgotPasswordCubit>();
          return LoadingOverlay(
            isLoading: state.status == FormStatus.submitting,
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      "Enter the email you signed up with and we'll send "
                      'a reset link.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    AppTextField(
                      label: 'Email',
                      keyboardType: TextInputType.emailAddress,
                      onChanged: cubit.emailChanged,
                      prefixIcon: const Icon(Icons.email_outlined),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppButton(
                      label: 'Send reset link',
                      onPressed: cubit.submit,
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
