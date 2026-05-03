import 'package:basic_crud_flutter/app/router/app_router.dart';
import 'package:basic_crud_flutter/app/router/routes.dart';
import 'package:basic_crud_flutter/core/storage/app_prefs.dart';
import 'package:basic_crud_flutter/features/auth/domain/entities/app_user.dart';
import 'package:basic_crud_flutter/features/auth/presentation/cubit/auth_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _verifiedUser = AppUser(
  uid: 'u',
  email: 'a@b.com',
  displayName: 'A',
  photoUrl: null,
  isAnonymous: false,
  isEmailVerified: true,
  providerId: 'password',
);

const _unverifiedUser = AppUser(
  uid: 'u',
  email: 'a@b.com',
  displayName: 'A',
  photoUrl: null,
  isAnonymous: false,
  isEmailVerified: false,
  providerId: 'password',
);

const _anonUser = AppUser(
  uid: 'anon',
  email: null,
  displayName: null,
  photoUrl: null,
  isAnonymous: true,
  isEmailVerified: false,
  providerId: 'anonymous',
);

Future<AppPrefs> _prefs({bool seen = true}) async {
  SharedPreferences.setMockInitialValues(seen ? {'onboarding_seen': true} : {});
  return AppPrefs.create();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('onboarding gate', () {
    test('first launch redirects any route to /onboarding', () async {
      final prefs = await _prefs(seen: false);
      expect(
        AppRouter.resolveRedirect(prefs, const Unauthenticated(), Routes.root),
        Routes.onboarding,
      );
      expect(
        AppRouter.resolveRedirect(
          prefs,
          const Unauthenticated(),
          Routes.login,
        ),
        Routes.onboarding,
      );
    });

    test('unseen user on /onboarding is not redirected', () async {
      final prefs = await _prefs(seen: false);
      expect(
        AppRouter.resolveRedirect(
          prefs,
          const Unauthenticated(),
          Routes.onboarding,
        ),
        isNull,
      );
    });
  });

  group('Unauthenticated', () {
    test('at /login stays', () async {
      final prefs = await _prefs();
      expect(
        AppRouter.resolveRedirect(prefs, const Unauthenticated(), Routes.login),
        isNull,
      );
    });

    test('at /signup stays', () async {
      final prefs = await _prefs();
      expect(
        AppRouter.resolveRedirect(
          prefs,
          const Unauthenticated(),
          Routes.signup,
        ),
        isNull,
      );
    });

    test('at /forgot-password stays', () async {
      final prefs = await _prefs();
      expect(
        AppRouter.resolveRedirect(
          prefs,
          const Unauthenticated(),
          Routes.forgotPassword,
        ),
        isNull,
      );
    });

    test('at /verify-email bounces to /login', () async {
      final prefs = await _prefs();
      expect(
        AppRouter.resolveRedirect(
          prefs,
          const Unauthenticated(),
          Routes.verifyEmail,
        ),
        Routes.login,
      );
    });

    test('at / redirects to /login', () async {
      final prefs = await _prefs();
      expect(
        AppRouter.resolveRedirect(prefs, const Unauthenticated(), Routes.root),
        Routes.login,
      );
    });

    test('at /home redirects to /login', () async {
      final prefs = await _prefs();
      expect(
        AppRouter.resolveRedirect(prefs, const Unauthenticated(), Routes.home),
        Routes.login,
      );
    });
  });

  group('Authenticated', () {
    test('at /login bounces to /home', () async {
      final prefs = await _prefs();
      expect(
        AppRouter.resolveRedirect(
          prefs,
          const Authenticated(_verifiedUser),
          Routes.login,
        ),
        Routes.home,
      );
    });

    test('at /signup bounces to /home', () async {
      final prefs = await _prefs();
      expect(
        AppRouter.resolveRedirect(
          prefs,
          const Authenticated(_verifiedUser),
          Routes.signup,
        ),
        Routes.home,
      );
    });

    test('at /forgot-password bounces to /home', () async {
      final prefs = await _prefs();
      expect(
        AppRouter.resolveRedirect(
          prefs,
          const Authenticated(_verifiedUser),
          Routes.forgotPassword,
        ),
        Routes.home,
      );
    });

    test('at / bounces to /home', () async {
      final prefs = await _prefs();
      expect(
        AppRouter.resolveRedirect(
          prefs,
          const Authenticated(_verifiedUser),
          Routes.root,
        ),
        Routes.home,
      );
    });

    test('at /onboarding bounces to /home', () async {
      final prefs = await _prefs();
      expect(
        AppRouter.resolveRedirect(
          prefs,
          const Authenticated(_verifiedUser),
          Routes.onboarding,
        ),
        Routes.home,
      );
    });

    test('at /verify-email bounces to /home', () async {
      final prefs = await _prefs();
      expect(
        AppRouter.resolveRedirect(
          prefs,
          const Authenticated(_verifiedUser),
          Routes.verifyEmail,
        ),
        Routes.home,
      );
    });

    test('at /home stays', () async {
      final prefs = await _prefs();
      expect(
        AppRouter.resolveRedirect(
          prefs,
          const Authenticated(_verifiedUser),
          Routes.home,
        ),
        isNull,
      );
    });

    test('at /mountains stays', () async {
      final prefs = await _prefs();
      expect(
        AppRouter.resolveRedirect(
          prefs,
          const Authenticated(_verifiedUser),
          Routes.mountains,
        ),
        isNull,
      );
    });

    test('verified user at /community/new stays', () async {
      final prefs = await _prefs();
      expect(
        AppRouter.resolveRedirect(
          prefs,
          const Authenticated(_verifiedUser),
          Routes.createPost,
        ),
        isNull,
      );
    });

    test('anonymous user at /community/new bounces to /home', () async {
      final prefs = await _prefs();
      expect(
        AppRouter.resolveRedirect(
          prefs,
          const Authenticated(_anonUser),
          Routes.createPost,
        ),
        Routes.home,
      );
    });

    test('Authenticated-but-unverified (e.g. freshly signed up, not '
        'NeedsVerification yet) at /community/new bounces to /verify-email',
        () async {
      const unverifiedAuthenticated = AppUser(
        uid: 'u',
        email: 'a@b.com',
        displayName: 'A',
        photoUrl: null,
        isAnonymous: false,
        isEmailVerified: false,
        providerId: 'google.com',
      );
      final prefs = await _prefs();
      expect(
        AppRouter.resolveRedirect(
          prefs,
          const Authenticated(unverifiedAuthenticated),
          Routes.createPost,
        ),
        Routes.verifyEmail,
      );
    });

    test('anonymous Authenticated user is treated identically', () async {
      final prefs = await _prefs();
      expect(
        AppRouter.resolveRedirect(
          prefs,
          const Authenticated(_anonUser),
          Routes.login,
        ),
        Routes.home,
      );
      expect(
        AppRouter.resolveRedirect(
          prefs,
          const Authenticated(_anonUser),
          Routes.home,
        ),
        isNull,
      );
    });
  });

  group('NeedsVerification', () {
    // Gated routes bounce to /verify-email
    for (final path in [
      Routes.home,
      Routes.mountains,
      Routes.likedMountains,
      Routes.root,
      Routes.onboarding,
    ]) {
      test('at $path redirects to /verify-email', () async {
        final prefs = await _prefs();
        expect(
          AppRouter.resolveRedirect(
            prefs,
            const NeedsVerification(_unverifiedUser),
            path,
          ),
          Routes.verifyEmail,
        );
      });
    }

    // Auth routes remain accessible so a pending-verification user can
    // sign in with a different account or initiate a password reset.
    for (final path in [
      Routes.login,
      Routes.signup,
      Routes.forgotPassword,
    ]) {
      test('at $path stays (escape hatch)', () async {
        final prefs = await _prefs();
        expect(
          AppRouter.resolveRedirect(
            prefs,
            const NeedsVerification(_unverifiedUser),
            path,
          ),
          isNull,
        );
      });
    }

    test('at /verify-email stays', () async {
      final prefs = await _prefs();
      expect(
        AppRouter.resolveRedirect(
          prefs,
          const NeedsVerification(_unverifiedUser),
          Routes.verifyEmail,
        ),
        isNull,
      );
    });
  });

  group('transitional auth states', () {
    test('AuthInitial does not redirect', () async {
      final prefs = await _prefs();
      expect(
        AppRouter.resolveRedirect(prefs, const AuthInitial(), Routes.root),
        isNull,
      );
      expect(
        AppRouter.resolveRedirect(prefs, const AuthInitial(), Routes.login),
        isNull,
      );
    });

    test('AuthLoading does not redirect', () async {
      final prefs = await _prefs();
      expect(
        AppRouter.resolveRedirect(prefs, const AuthLoading(), Routes.home),
        isNull,
      );
    });

    test('AuthFailure is treated like Unauthenticated', () async {
      final prefs = await _prefs();
      const failure = AuthFailure('boom');
      expect(
        AppRouter.resolveRedirect(prefs, failure, Routes.home),
        Routes.login,
      );
      expect(
        AppRouter.resolveRedirect(prefs, failure, Routes.login),
        isNull,
      );
    });
  });
}
