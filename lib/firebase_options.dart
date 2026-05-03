import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Firebase configuration options.
///
/// Android values are authored from the project's existing `google-services.json`.
/// For iOS, macOS, and web, run `flutterfire configure` to generate the correct
/// options; calling [currentPlatform] on those platforms throws before that runs.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'Web platform is not configured. Run `flutterfire configure` to '
        'generate web options.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return android;
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        throw UnsupportedError(
          'This platform is not configured for Firebase.',
        );
    }
  }

  static const FirebaseOptions _android = FirebaseOptions(
    apiKey: 'AIzaSyCbuzacMkEh-B-yCjFKEwNnDsNS5R8mxA8',
    appId: '1:935877536444:android:368c2f66c23a856153beb9',
    messagingSenderId: '935877536444',
    projectId: 'btack-5f03e',
    storageBucket: 'btack-5f03e.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDcMulEPfsJIvlWcQhKdOQk5Fql55W-LYs',
    appId: '1:935877536444:ios:3d3792dfe6a9e7e453beb9',
    messagingSenderId: '935877536444',
    projectId: 'btack-5f03e',
    databaseURL: 'https://btack-5f03e-default-rtdb.firebaseio.com',
    storageBucket: 'btack-5f03e.appspot.com',
    androidClientId: '935877536444-bgiec0eg2g74er0s37io8lcraoiar4bm.apps.googleusercontent.com',
    iosClientId: '935877536444-fnka0ogsvo64bl0alo51944agc3of4h1.apps.googleusercontent.com',
    iosBundleId: 'com.example.mountainExplorer',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCbuzacMkEh-B-yCjFKEwNnDsNS5R8mxA8',
    appId: '1:935877536444:android:88544b1137f3aee853beb9',
    messagingSenderId: '935877536444',
    projectId: 'btack-5f03e',
    databaseURL: 'https://btack-5f03e-default-rtdb.firebaseio.com',
    storageBucket: 'btack-5f03e.appspot.com',
  );

}