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
import '../cubit/checklist_cubit.dart';
import '../cubit/checklist_state.dart';

class ChecklistPage extends StatelessWidget {
  const ChecklistPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ChecklistCubit>.value(
      value: getIt<ChecklistCubit>(),
      child: const _ChecklistView(),
    );
  }
}

class _ChecklistView extends StatefulWidget {
  const _ChecklistView();

  @override
  State<_ChecklistView> createState() => _ChecklistViewState();
}

class _ChecklistViewState extends State<_ChecklistView> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthCubit>().state;
    final uid = switch (auth) {
      Authenticated(:final user) when !user.isAnonymous => user.uid,
      _ => '',
    };
    context.read<ChecklistCubit>().subscribe(uid);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ThemedAppBar(title: 'Checklist'),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          final isGuest = switch (authState) {
            Authenticated(:final user) => user.isAnonymous,
            _ => true,
          };
          if (isGuest) {
            return EmptyState(
              icon: Icons.checklist_outlined,
              title: 'Sign up to save your checklist',
              message: 'Checklists sync across your devices once you sign up.',
              actionLabel: 'Sign up',
              onAction: () => context.push(Routes.signup),
            );
          }
          return BlocListener<AuthCubit, AuthState>(
            listenWhen: (prev, curr) {
              final prevUid = prev is Authenticated ? prev.user.uid : null;
              final currUid = curr is Authenticated ? curr.user.uid : null;
              return prevUid != currUid;
            },
            listener: (context, state) {
              if (state case Authenticated(:final user)
                  when !user.isAnonymous) {
                context.read<ChecklistCubit>().subscribe(user.uid);
              }
            },
            child: Column(
              children: [
                Expanded(child: _ChecklistList(controller: _controller)),
                _InputBar(controller: _controller),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ChecklistList extends StatelessWidget {
  final TextEditingController controller;
  const _ChecklistList({required this.controller});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChecklistCubit, ChecklistState>(
      builder: (context, state) {
        return switch (state) {
          ChecklistInitial() || ChecklistLoading() =>
            const Center(child: CircularProgressIndicator()),
          ChecklistError(:final message) => ErrorView(
              message: message,
              onRetry: () {
                final auth = context.read<AuthCubit>().state;
                if (auth case Authenticated(:final user)) {
                  context.read<ChecklistCubit>().subscribe(user.uid);
                }
              },
            ),
          ChecklistLoaded(:final items) => items.isEmpty
              ? const EmptyState(
                  message: 'Nothing to pack yet. Add your first item below.',
                  icon: Icons.checklist_outlined,
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final item = items[i];
                    return CheckboxListTile(
                      value: item.isDone,
                      onChanged: (_) =>
                          context.read<ChecklistCubit>().toggle(item),
                      title: Text(
                        item.text,
                        style: TextStyle(
                          decoration: item.isDone
                              ? TextDecoration.lineThrough
                              : null,
                          color: item.isDone
                              ? AppColors.slate600
                              : AppColors.onSurface,
                        ),
                      ),
                      secondary: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () =>
                            context.read<ChecklistCubit>().delete(item),
                      ),
                    );
                  },
                ),
        };
      },
    );
  }
}

class _InputBar extends StatefulWidget {
  final TextEditingController controller;
  const _InputBar({required this.controller});

  @override
  State<_InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<_InputBar> {
  bool _submitting = false;

  Future<void> _submit() async {
    final text = widget.controller.text.trim();
    if (text.isEmpty || _submitting) return;
    setState(() => _submitting = true);
    final result = await context.read<ChecklistCubit>().addItem(text);
    if (!mounted) return;
    setState(() => _submitting = false);
    switch (result) {
      case Success():
        widget.controller.clear();
      case Failure(:final error):
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

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
                  controller: widget.controller,
                  maxLength: 120,
                  decoration: InputDecoration(
                    hintText: 'Add an item (e.g. "Sleeping bag")',
                    counterText: '',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.sm,
                    ),
                  ),
                  onSubmitted: (_) => _submit(),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton.filled(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
