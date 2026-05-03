import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/router/routes.dart';
import '../../../../../core/di/injector.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../../auth/presentation/cubit/auth_state.dart';
import '../../../domain/entities/emergency_contact.dart';
import '../../../domain/usecases/watch_contacts.dart';
import '../../cubit/sos_cubit.dart';
import '../../cubit/sos_state.dart';
import 'sos_countdown_dialog.dart';

/// Persistent SOS FAB rendered by `HomeShell._ShellView`.
///
/// Subscribes to the user's emergency-contacts stream so the FAB knows
/// whether a primary contact exists (to enable / disable the button).
class SosFab extends StatefulWidget {
  const SosFab({super.key});

  @override
  State<SosFab> createState() => _SosFabState();
}

class _SosFabState extends State<SosFab> {
  Stream<List<EmergencyContact>>? _stream;
  String _uid = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authState = context.read<AuthCubit>().state;
    final uid = switch (authState) {
      Authenticated(:final user) => user.uid,
      NeedsVerification(:final user) => user.uid,
      _ => '',
    };
    if (uid != _uid) {
      _uid = uid;
      _stream = uid.isEmpty ? null : getIt<WatchContacts>()(uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_stream == null) {
      return const SizedBox.shrink();
    }
    return StreamBuilder<List<EmergencyContact>>(
      stream: _stream,
      builder: (context, snap) {
        final contacts = snap.data ?? const <EmergencyContact>[];
        final hasPrimary = contacts.any((c) => c.isPrimary);
        // Mirror the contact list state into the SosCubit so its own
        // hasPrimaryContact field is up to date for any other consumers.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          context.read<SosCubit>().onContactsChanged(contacts);
        });
        return BlocConsumer<SosCubit, SosState>(
          listenWhen: (prev, curr) =>
              (prev is! SosCountdown && curr is SosCountdown) ||
              (prev is! SosError && curr is SosError) ||
              (prev is! SosDispatched &&
                  curr is SosDispatched &&
                  curr.queued),
          listener: (ctx, state) {
            if (state is SosCountdown) {
              showDialog<void>(
                context: ctx,
                barrierDismissible: false,
                builder: (_) => BlocProvider<SosCubit>.value(
                  value: ctx.read<SosCubit>(),
                  child: const SosCountdownDialog(),
                ),
              );
              return;
            }
            if (state is SosError) {
              _showSosErrorDialog(ctx, state.message);
              return;
            }
            if (state is SosDispatched && state.queued) {
              // Network unavailable at dispatch time → SMS opened
              // anyway, alert is queued and will sync when online.
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(
                  content: Text(
                    "You're offline — SOS is queued and will sync when "
                    'the connection returns. SMS to your contacts opens '
                    'now if your device has cellular service.',
                  ),
                  duration: Duration(seconds: 6),
                ),
              );
              return;
            }
          },
          builder: (_, state) {
            return FloatingActionButton.extended(
              // Distinct heroTag so the global SOS overlay doesn't
              // collide with per-page FABs (e.g. the Map's "Download
              // this view" or the Community feed's "New post").
              heroTag: 'sos_fab',
              backgroundColor:
                  hasPrimary ? AppColors.error : AppColors.stone400,
              foregroundColor: Colors.white,
              // Always clickable — when no primary contact exists we
              // pop a guidance dialog instead of silently no-op'ing
              // (the prior `onPressed: null` left the user wondering
              // why the SOS button does nothing).
              onPressed: () {
                if (!hasPrimary) {
                  _showNoPrimaryContactDialog(context);
                  return;
                }
                final auth = context.read<AuthCubit>().state;
                final user = switch (auth) {
                  Authenticated(:final user) => user,
                  NeedsVerification(:final user) => user,
                  _ => null,
                };
                // Anonymous users can't fire SOS — there's no verified
                // email or display name to surface to emergency contacts.
                if (user == null || user.isAnonymous) {
                  _showAnonymousBlockedDialog(context);
                  return;
                }
                context.read<SosCubit>().onFabPressed(
                      uid: user.uid,
                      userName: user.displayName ?? 'Mountain Explorer',
                      userEmail: user.email ?? '',
                      contacts: contacts,
                    );
              },
              icon: const Icon(Icons.sos),
              label: const Text('SOS'),
            );
          },
        );
      },
    );
  }

  /// Pre-flight nudge when the user taps SOS without a primary contact.
  /// Offers a one-tap path to the Emergency Contacts page.
  Future<void> _showNoPrimaryContactDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded,
            color: AppColors.error, size: 36),
        title: const Text('No emergency contact'),
        content: const Text(
          'SOS sends a message and your live location to your primary '
          "emergency contact. You haven't added one yet.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              context.push(Routes.emergencyContacts);
            },
            child: const Text('Add contact'),
          ),
        ],
      ),
    );
  }

  /// Anonymous users can't fire SOS (no verified email / display name to
  /// surface to contacts). Tell them why instead of silently failing.
  Future<void> _showAnonymousBlockedDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        icon: const Icon(Icons.lock_outline,
            color: AppColors.error, size: 36),
        title: const Text('Sign in to use SOS'),
        content: const Text(
          'SOS attaches your name and verified email to the alert your '
          'emergency contacts receive. Anonymous accounts can browse the '
          "app, but can't dispatch an SOS.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Surfaces the cubit's SosError state (no permission, no contacts at
  /// dispatch time, etc.). The cubit clears the error state when the
  /// user dismisses, so the next FAB tap starts fresh.
  Future<void> _showSosErrorDialog(BuildContext context, String message) {
    return showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        icon: const Icon(Icons.error_outline,
            color: AppColors.error, size: 36),
        title: const Text("SOS couldn't be sent"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              if (context.mounted) {
                context.read<SosCubit>().clearError();
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
