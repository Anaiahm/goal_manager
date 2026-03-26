import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:     return ios;
      case TargetPlatform.android: return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // ── Web ──────────────────────────────────────────────────────
  static const FirebaseOptions web = FirebaseOptions(
    apiKey:            'AIzaSyD5VGuYYDF3091rRbZ3loOY57r8w143cpc',
    authDomain:        'goal-ly.firebaseapp.com',
    projectId:         'goal-ly',
    storageBucket:     'goal-ly.appspot.com',
    messagingSenderId: '264330081726',
    appId:             '1:264330081726:web:210495a7d0136dc45835ef',
  );

  // ── iOS ──────────────────────────────────────────────────────
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey:            'AIzaSyD5VGuYYDF3091rRbZ3loOY57r8w143cpc',
    authDomain:        'goal-ly.firebaseapp.com',
    projectId:         'goal-ly',
    storageBucket:     'goal-ly.appspot.com',
    messagingSenderId: '264330081726',
    appId:             '1:264330081726:ios:585615eba0d639505835ef',
    iosBundleId:       'com.example.goal-ly',
  );

  // ── Android ──────────────────────────────────────────────────
  static const FirebaseOptions android = FirebaseOptions(
    apiKey:            'YOUR_ANDROID_API_KEY',
    authDomain:        'goal-ly.firebaseapp.com',
    projectId:         'goal-ly',
    storageBucket:     'goal-ly.appspot.com',
    messagingSenderId: '264330081726',
    appId:             'YOUR_ANDROID_APP_ID',
  );
}