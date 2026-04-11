// Generated from GoogleService-Info.plist

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions is not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBvjdzx4WizuKEfmZuCN-wo5193RwuIvVw',
    appId: '1:554494039862:ios:fc65d64c463432ec088597',
    messagingSenderId: '554494039862',
    projectId: 'cheatmonster-22993',
    databaseURL: 'https://cheatmonster-22993-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'cheatmonster-22993.firebasestorage.app',
    iosBundleId: 'com.imanaka.cheatmonster',
  );
}
