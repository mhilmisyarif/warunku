// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAUS3bydN1yIIFRs8Q_uF1QEN6XkJcCFhk',
    appId: '1:712610418450:web:09050dcbf5b4ea1d7dadcb',
    messagingSenderId: '712610418450',
    projectId: 'warunku-7b5c7',
    authDomain: 'warunku-7b5c7.firebaseapp.com',
    storageBucket: 'warunku-7b5c7.appspot.com',
    measurementId: 'G-NJ2GYKH896',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD6Sm_qWzQrDanwFChCNf_bZWMpy1Wvc_U',
    appId: '1:712610418450:android:12588d49354784157dadcb',
    messagingSenderId: '712610418450',
    projectId: 'warunku-7b5c7',
    storageBucket: 'warunku-7b5c7.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAhE_oMCYC8om9MjBs3jj1NYcIxqKEgREk',
    appId: '1:712610418450:ios:566f02514b0cf7147dadcb',
    messagingSenderId: '712610418450',
    projectId: 'warunku-7b5c7',
    storageBucket: 'warunku-7b5c7.appspot.com',
    iosClientId: '712610418450-inbohbnc18bjqaldr3q4fmjsbkf4bp4q.apps.googleusercontent.com',
    iosBundleId: 'com.example.warunkApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAhE_oMCYC8om9MjBs3jj1NYcIxqKEgREk',
    appId: '1:712610418450:ios:566f02514b0cf7147dadcb',
    messagingSenderId: '712610418450',
    projectId: 'warunku-7b5c7',
    storageBucket: 'warunku-7b5c7.appspot.com',
    iosClientId: '712610418450-inbohbnc18bjqaldr3q4fmjsbkf4bp4q.apps.googleusercontent.com',
    iosBundleId: 'com.example.warunkApp',
  );
}
