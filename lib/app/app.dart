import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../core/di/injector.dart';
import '../core/storage/app_prefs.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/presentation/cubit/auth_cubit.dart';
import '../features/auth/presentation/cubit/auth_state.dart';
import '../features/sos/presentation/cubit/sos_cubit.dart';
import 'router/app_router.dart';

class MountainExplorerApp extends StatelessWidget {
  MountainExplorerApp({super.key})
      : _router = AppRouter.create(
          prefs: getIt<AppPrefs>(),
          authCubit: getIt<AuthCubit>(),
        );

  final GoRouter _router;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthCubit>.value(
      value: getIt<AuthCubit>(),
      // Iter 5b EC-3: on the app's first Authenticated emission, fire
      // the 6h SOS-timeout flush. SosCubit swallows failures; this is
      // fire-and-forget. Re-emits of Authenticated (token refresh)
      // re-run the flush idempotently.
      child: BlocListener<AuthCubit, AuthState>(
        listenWhen: (prev, curr) =>
            prev is! Authenticated && curr is Authenticated,
        listener: (_, state) {
          if (state is Authenticated) {
            getIt<SosCubit>().flushExpiredOnBoot(state.user.uid);
          }
        },
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: 'Mountain Explorer',
          theme: AppTheme.light,
          routerConfig: _router,
        ),
      ),
    );
  }
}
