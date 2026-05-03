import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../cubit/sos_cubit.dart';
import '../../cubit/sos_state.dart';

/// Renders the live `SosCountdown` from the singleton [SosCubit].
/// Auto-dismisses (pop) when the cubit transitions away from
/// `SosCountdown` (which happens when the dispatch begins or the user
/// cancels via the cubit).
class SosCountdownDialog extends StatelessWidget {
  const SosCountdownDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SosCubit, SosState>(
      listenWhen: (prev, curr) =>
          prev is SosCountdown && curr is! SosCountdown,
      listener: (_, __) {
        if (Navigator.of(context).canPop()) Navigator.of(context).pop();
      },
      builder: (_, state) {
        final remaining = state is SosCountdown ? state.remainingSeconds : 0;
        return AlertDialog(
          backgroundColor: AppColors.error,
          title: const Text(
            'Sending SOS',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$remaining',
                style: const TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Tap Cancel to abort.',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => context.read<SosCubit>().cancelCountdown(),
              child: const Text('Cancel',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
