import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../cubit/trek_cubit.dart';
import '../../cubit/trek_state.dart';

/// AppBar action button that toggles the active trek session. Disabled
/// label / icon flip based on the [TrekCubit] state.
class TrekToggleButton extends StatelessWidget {
  const TrekToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TrekCubit, TrekState>(
      builder: (context, state) {
        final active = state is TrekActive;
        return IconButton(
          tooltip: active ? 'Stop Trek' : 'Start Trek',
          icon: Icon(
            active ? Icons.stop_circle_outlined : Icons.play_circle_outline,
            color: active ? AppColors.error : null,
          ),
          onPressed: () {
            final cubit = context.read<TrekCubit>();
            if (active) {
              cubit.stop();
            } else {
              cubit.start(context);
            }
          },
        );
      },
    );
  }
}
