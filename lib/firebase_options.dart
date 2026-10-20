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
      default:
        return android;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDVgNXhAZvo0xd8ZlC4fAxfOxt76wkCBH8',
    appId: '1:733682005538:web:d5b850a7ef49da10037c7b',
    messagingSenderId: '733682005538',
    projectId: 'xtracker-6d4f8',
    authDomain: 'xtracker-6d4f8.firebaseapp.com',
    storageBucket: 'xtracker-6d4f8.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDVgNXhAZvo0xd8ZlC4fAxfOxt76wkCBH8',
    appId: '1:733682005538:android:d5b850a7ef49da10037c7b',
    messagingSenderId: '733682005538',
    projectId: 'xtracker-6d4f8',
    storageBucket: 'xtracker-6d4f8.firebasestorage.app',
  );
}
