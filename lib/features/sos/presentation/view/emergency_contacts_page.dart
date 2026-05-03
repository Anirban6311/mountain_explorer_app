import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../domain/entities/emergency_contact.dart';
import '../cubit/emergency_contacts_cubit.dart';
import '../cubit/emergency_contacts_state.dart';
import 'widgets/contact_form_bottom_sheet.dart';

class EmergencyContactsPage extends StatefulWidget {
  const EmergencyContactsPage({super.key});

  @override
  State<EmergencyContactsPage> createState() => _EmergencyContactsPageState();
}

class _EmergencyContactsPageState extends State<EmergencyContactsPage> {
  bool _subscribed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_subscribed) return;
    final auth = context.read<AuthCubit>().state;
    final uid = switch (auth) {
      Authenticated(:final user) => user.uid,
      NeedsVerification(:final user) => user.uid,
      _ => '',
    };
    if (uid.isNotEmpty) {
      context.read<EmergencyContactsCubit>().subscribe(uid);
      _subscribed = true;
    }
  }

  Future<void> _openForm({EmergencyContact? initial}) async {
    final result = await ContactFormBottomSheet.show(context, initial: initial);
    if (result == null || !mounted) return;
    final cubit = context.read<EmergencyContactsCubit>();
    if (initial == null) {
      await cubit.add(result);
    } else {
      await cubit.update(result);
    }
  }

  Future<void> _confirmDelete(BuildContext context, EmergencyContact c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove contact?'),
        content: Text('Remove ${c.name} from your emergency contacts?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<EmergencyContactsCubit>().delete(c.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ThemedAppBar(title: 'Emergency contacts'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Add contact'),
      ),
      body: BlocBuilder<EmergencyContactsCubit, EmergencyContactsState>(
        builder: (context, state) {
          if (state.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.contacts.isEmpty) {
            return const EmptyState(
              icon: Icons.contact_emergency_outlined,
              message:
                  'No emergency contacts yet. Add at least one so the SOS\n'
                  'button can notify them in an emergency.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: state.contacts.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: AppSpacing.sm),
            itemBuilder: (_, i) {
              final c = state.contacts[i];
              return Dismissible(
                key: ValueKey(c.id),
                direction: DismissDirection.endToStart,
                confirmDismiss: (_) async {
                  await _confirmDelete(context, c);
                  return false; // We delete via the cubit, not the widget.
                },
                background: Container(
                  alignment: Alignment.centerRight,
                  color: AppColors.error,
                  padding: const EdgeInsets.only(right: AppSpacing.lg),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                child: AppCard(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          c.isPrimary ? AppColors.error : AppColors.slate200,
                      foregroundColor:
                          c.isPrimary ? Colors.white : AppColors.slate700,
                      child: Text(
                        c.name.isEmpty ? '?' : c.name[0].toUpperCase(),
                      ),
                    ),
                    title: Text(c.name),
                    subtitle: Text(
                      [
                        c.phone,
                        if (c.relationship != null && c.relationship!.isNotEmpty)
                          c.relationship!,
                      ].join(' · '),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (c.isPrimary)
                          const Chip(
                            label: Text('Primary'),
                            backgroundColor: AppColors.error,
                            labelStyle: TextStyle(color: Colors.white),
                          )
                        else
                          TextButton(
                            onPressed: () => context
                                .read<EmergencyContactsCubit>()
                                .setPrimary(c.id),
                            child: const Text('Set primary'),
                          ),
                        IconButton(
                          tooltip: 'Remove contact',
                          icon: const Icon(
                            Icons.delete_outline,
                            color: AppColors.error,
                          ),
                          onPressed: () => _confirmDelete(context, c),
                        ),
                      ],
                    ),
                    onTap: () => _openForm(initial: c),
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
