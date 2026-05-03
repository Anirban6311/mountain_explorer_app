import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/env/env.dart';
import '../data/datasources/auth_remote_data_source.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/usecases/reload_current_user.dart';
import '../domain/usecases/reset_password.dart';
import '../domain/usecases/send_email_verification.dart';
import '../domain/usecases/sign_in_anonymously.dart';
import '../domain/usecases/sign_in_with_email.dart';
import '../domain/usecases/sign_in_with_google.dart';
import '../domain/usecases/sign_out.dart';
import '../domain/usecases/sign_up.dart';
import '../domain/usecases/watch_auth_state.dart';
import '../presentation/cubit/auth_cubit.dart';
import '../presentation/cubit/forgot_password_cubit.dart';
import '../presentation/cubit/login_cubit.dart';
import '../presentation/cubit/signup_cubit.dart';
import '../presentation/cubit/verify_email_cubit.dart';

void registerAuthModule(GetIt getIt) {
  if (getIt.isRegistered<AuthRepository>()) return;

  getIt.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  getIt.registerLazySingleton<GoogleSignIn>(
    () => GoogleSignIn(
      serverClientId: getIt<Env>().googleSignInServerClientId,
      scopes: const ['email', 'profile'],
    ),
  );

  getIt.registerLazySingleton<AuthRemoteDataSource>(
    () => FirebaseAuthRemoteDataSource(
      auth: getIt<FirebaseAuth>(),
      google: getIt<GoogleSignIn>(),
    ),
  );

  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(getIt<AuthRemoteDataSource>()),
  );

  final repo = getIt<AuthRepository>();
  getIt.registerLazySingleton(() => SignInWithEmail(repo));
  getIt.registerLazySingleton(() => SignUp(repo));
  getIt.registerLazySingleton(() => SignInWithGoogle(repo));
  getIt.registerLazySingleton(() => SignInAnonymously(repo));
  getIt.registerLazySingleton(() => SignOut(repo));
  getIt.registerLazySingleton(() => SendEmailVerification(repo));
  getIt.registerLazySingleton(() => ResetPassword(repo));
  getIt.registerLazySingleton(() => ReloadCurrentUser(repo));
  getIt.registerLazySingleton(() => WatchAuthState(repo));

  getIt.registerLazySingleton<AuthCubit>(
    () => AuthCubit(
      watchAuthState: getIt<WatchAuthState>(),
      signOutUseCase: getIt<SignOut>(),
    ),
    dispose: (cubit) => cubit.close(),
  );

  getIt.registerFactory<LoginCubit>(
    () => LoginCubit(
      signInWithEmail: getIt<SignInWithEmail>(),
      signInWithGoogle: getIt<SignInWithGoogle>(),
      signInAnonymously: getIt<SignInAnonymously>(),
    ),
  );
  getIt.registerFactory<SignupCubit>(
    () => SignupCubit(signUp: getIt<SignUp>()),
  );
  getIt.registerFactory<ForgotPasswordCubit>(
    () => ForgotPasswordCubit(resetPassword: getIt<ResetPassword>()),
  );
  getIt.registerFactory<VerifyEmailCubit>(
    () => VerifyEmailCubit(
      sendEmailVerification: getIt<SendEmailVerification>(),
      reloadCurrentUser: getIt<ReloadCurrentUser>(),
    ),
  );
}
