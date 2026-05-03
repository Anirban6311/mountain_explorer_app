import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/onboarding/presentation/onboarding_page.dart';
import '../../core/consent/background_location_disclosure_page.dart';
import '../../core/di/injector.dart';
import '../../core/storage/app_prefs.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/auth/presentation/cubit/auth_state.dart';
import '../../features/auth/presentation/view/forgot_password_page.dart';
import '../../features/auth/presentation/view/login_page.dart';
import '../../features/auth/presentation/view/signup_page.dart';
import '../../features/auth/presentation/view/verify_email_page.dart';
import '../../features/checklist/presentation/view/checklist_page.dart';
import '../../features/community/presentation/view/create_post_page.dart';
import '../../features/community/presentation/view/edit_post_page.dart';
import '../../features/community/presentation/view/post_detail_page.dart';
import '../../features/home/presentation/view/home_shell.dart';
import '../../features/home/presentation/view/profile_page.dart';
import '../../features/mountains/presentation/cubit/mountain_search_cubit.dart';
import '../../features/mountains/presentation/cubit/mountains_cubit.dart';
import '../../features/mountains/presentation/view/liked_mountains_page.dart';
import '../../features/mountains/presentation/view/mountain_search_page.dart';
import '../../features/mountains/presentation/view/mountains_page.dart';
import '../../features/offline_maps/presentation/cubit/offline_maps_cubit.dart';
import '../../features/offline_maps/presentation/view/offline_maps_page.dart';
import '../../features/offline_maps/presentation/view/offline_regions_catalog_page.dart';
import '../../features/settings/presentation/cubit/settings_cubit.dart';
import '../../features/settings/presentation/view/settings_page.dart';
import '../../features/sos/presentation/cubit/emergency_contacts_cubit.dart';
import '../../features/sos/presentation/view/emergency_contacts_page.dart';
import 'routes.dart';

class AppRouter {
  const AppRouter._();

  static const _authRoutes = <String>{
    Routes.login,
    Routes.signup,
    Routes.forgotPassword,
  };

  /// Routes that require a signed-in, email-verified (non-anonymous) user.
  /// Anonymous or unverified users get bounced to `/verify-email` or
  /// `/login` as appropriate.
  static bool _requiresVerifiedEmail(String path) {
    return path == Routes.createPost ||
        path.contains('/community/post/') && path.endsWith('/edit');
  }

  /// Pure redirect resolver — no Flutter or go_router dependencies.
  static String? resolveRedirect(
    AppPrefs prefs,
    AuthState authState,
    String path,
  ) {
    // Onboarding takes precedence for first-time users.
    if (!prefs.hasSeenOnboarding()) {
      return path == Routes.onboarding ? null : Routes.onboarding;
    }

    switch (authState) {
      case AuthInitial():
      case AuthLoading():
        return null;
      case Authenticated(:final user):
        if (_authRoutes.contains(path) ||
            path == Routes.verifyEmail ||
            path == Routes.root ||
            path == Routes.onboarding) {
          return Routes.home;
        }
        // Write-to-community routes need a verified, non-anonymous user.
        if (_requiresVerifiedEmail(path)) {
          if (user.isAnonymous) return Routes.home;
          if (!user.isEmailVerified) return Routes.verifyEmail;
        }
        return null;
      case NeedsVerification():
        if (path == Routes.verifyEmail) return null;
        // Let the user bail out: reach /login, /signup or /forgot-password
        // from the verify-email trap without having to sign out first.
        if (_authRoutes.contains(path)) return null;
        return Routes.verifyEmail;
      case Unauthenticated():
      case AuthFailure():
        if (_authRoutes.contains(path)) return null;
        return Routes.login;
    }
  }

  static GoRouter create({
    required AppPrefs prefs,
    required AuthCubit authCubit,
  }) {
    return GoRouter(
      initialLocation: Routes.root,
      refreshListenable: _AuthStreamListenable(authCubit),
      redirect: (context, state) => resolveRedirect(
        prefs,
        authCubit.state,
        state.matchedLocation,
      ),
      routes: [
        GoRoute(
          path: Routes.root,
          builder: (_, __) => const SizedBox.shrink(),
        ),
        GoRoute(
          path: Routes.onboarding,
          builder: (_, __) => const OnboardingPage(),
        ),
        GoRoute(
          path: Routes.login,
          builder: (_, __) => const LoginPage(),
        ),
        GoRoute(
          path: Routes.signup,
          builder: (_, __) => const SignupPage(),
        ),
        GoRoute(
          path: Routes.forgotPassword,
          builder: (_, __) => const ForgotPasswordPage(),
        ),
        GoRoute(
          path: Routes.verifyEmail,
          builder: (_, __) => const VerifyEmailPage(),
        ),
        GoRoute(
          path: Routes.home,
          builder: (_, __) => const HomeShell(),
        ),
        GoRoute(
          path: Routes.mountains,
          builder: (context, __) => _withMountainsCubit(
            context,
            const MountainsPage(),
          ),
        ),
        GoRoute(
          path: Routes.mountainSearch,
          builder: (context, __) => _withMountainsAndSearch(
            context,
            const MountainSearchPage(),
          ),
        ),
        GoRoute(
          path: Routes.likedMountains,
          builder: (context, __) => _withMountainsCubit(
            context,
            const LikedMountainsPage(),
          ),
        ),
        GoRoute(
          path: Routes.profile,
          builder: (_, __) => const ProfilePage(),
        ),
        GoRoute(
          path: Routes.checklist,
          builder: (_, __) => const ChecklistPage(),
        ),
        GoRoute(
          path: Routes.createPost,
          builder: (_, __) => const CreatePostPage(),
        ),
        GoRoute(
          path: Routes.postDetailPattern,
          builder: (_, state) =>
              PostDetailPage(postId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: Routes.editPostPattern,
          builder: (_, state) =>
              EditPostPage(postId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: Routes.backgroundLocationConsent,
          builder: (_, __) => const BackgroundLocationDisclosurePage(),
        ),
        GoRoute(
          path: Routes.map,
          builder: (_, __) => _withOfflineMapsCubit(const OfflineMapsPage()),
        ),
        GoRoute(
          path: Routes.settings,
          builder: (_, __) => _withSettingsCubit(const SettingsPage()),
        ),
        GoRoute(
          path: Routes.offlineRegions,
          builder: (_, __) =>
              _withOfflineMapsCubit(const OfflineRegionsCatalogPage()),
        ),
        GoRoute(
          path: Routes.emergencyContacts,
          builder: (_, __) =>
              _withEmergencyContactsCubit(const EmergencyContactsPage()),
        ),
      ],
    );
  }

  static Widget _withEmergencyContactsCubit(Widget child) {
    return BlocProvider<EmergencyContactsCubit>(
      create: (_) => getIt<EmergencyContactsCubit>(),
      child: child,
    );
  }

  static Widget _withOfflineMapsCubit(Widget child) {
    return BlocProvider<OfflineMapsCubit>(
      create: (_) => getIt<OfflineMapsCubit>(),
      child: child,
    );
  }

  static Widget _withSettingsCubit(Widget child) {
    return BlocProvider<SettingsCubit>(
      create: (_) => getIt<SettingsCubit>(),
      child: child,
    );
  }

  static Widget _withMountainsCubit(BuildContext context, Widget child) {
    final cubit = getIt<MountainsCubit>();
    final uid = _uidFromAuth(context);
    if (uid.isNotEmpty) cubit.load(uid: uid);
    return BlocProvider<MountainsCubit>.value(value: cubit, child: child);
  }

  static Widget _withMountainsAndSearch(BuildContext context, Widget child) {
    final cubit = getIt<MountainsCubit>();
    final uid = _uidFromAuth(context);
    if (uid.isNotEmpty) cubit.load(uid: uid);
    return MultiBlocProvider(
      providers: [
        BlocProvider<MountainsCubit>.value(value: cubit),
        BlocProvider<MountainSearchCubit>(
          create: (_) => getIt<MountainSearchCubit>(),
        ),
      ],
      child: child,
    );
  }

  static String _uidFromAuth(BuildContext context) {
    final state = getIt<AuthCubit>().state;
    return switch (state) {
      Authenticated(:final user) => user.uid,
      NeedsVerification(:final user) => user.uid,
      _ => '',
    };
  }
}

/// Bridges an `AuthCubit` state stream into a `Listenable` so `GoRouter`
/// re-runs its redirect on every auth transition.
class _AuthStreamListenable extends ChangeNotifier {
  _AuthStreamListenable(AuthCubit cubit) {
    _sub = cubit.stream.listen((_) => notifyListeners());
  }
  late final StreamSubscription<AuthState> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
