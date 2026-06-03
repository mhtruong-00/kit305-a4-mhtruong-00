// PLACEHOLDER Firebase configuration.
//
// >>> MARKER NOTE <<<
// To run this app against your own Firebase project, regenerate this file with
// the FlutterFire CLI:
//
//     dart pub global activate flutterfire_cli
//     flutterfire configure
//
// That writes real values here and drops the platform config files
// (android/app/google-services.json and ios/Runner/GoogleService-Info.plist).
//
// The placeholder values below let the project compile, but Firestore will not
// connect until you run `flutterfire configure` (or drop in your own config).
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return android;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'REPLACE_ME',
    appId: '1:000000000000:web:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'kit305-a4-placeholder',
    authDomain: 'kit305-a4-placeholder.firebaseapp.com',
    storageBucket: 'kit305-a4-placeholder.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'REPLACE_ME',
    appId: '1:000000000000:android:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'kit305-a4-placeholder',
    storageBucket: 'kit305-a4-placeholder.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REPLACE_ME',
    appId: '1:000000000000:ios:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'kit305-a4-placeholder',
    storageBucket: 'kit305-a4-placeholder.appspot.com',
    iosBundleId: 'dev.mhtruong.kit305a4',
  );
}

