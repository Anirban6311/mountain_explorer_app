import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app/app.dart';
import 'core/di/injector.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Mountain Explorer runs in remote areas with no signal. Disable the
  // google_fonts runtime CDN fetch so the app never crashes trying to
  // download Montserrat from fonts.gstatic.com on a cold-start with no
  // network. With `allowRuntimeFetching = false`, the package falls back
  // to the platform default font (Roboto on Android, San Francisco on
  // iOS) when Montserrat isn't bundled. To restore branded typography
  // even offline, bundle the Montserrat .ttf files under assets/fonts/
  // and declare them in pubspec.yaml's `fonts:` section.
  GoogleFonts.config.allowRuntimeFetching = false;
  await dotenv.load(fileName: '.env');
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FMTCObjectBoxBackend().initialise();
  await configureDependencies();
  getIt<AuthCubit>().bootstrap();
  runApp(MountainExplorerApp());
}
