import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../firebase_options.dart';

class AuthProvider extends ChangeNotifier {
  FirebaseAuth? _auth;
  GoogleSignIn? _googleSignIn;
  StreamSubscription<User?>? _authSub;

  bool _isInitialized = false;
  bool _isLoading = false;
  String? _errorMessage;

  String? _cachedPhotoUrl;
  String? _cachedDisplayName;
  String? _cachedEmail;
  String? _cachedUid;

  static const _cachedPhotoKey = 'auth_cached_photo_url';
  static const _cachedNameKey = 'auth_cached_display_name';
  static const _cachedEmailKey = 'auth_cached_email';
  static const _cachedUidKey = 'auth_cached_uid';

  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  User? get user {
    try {
      return _auth?.currentUser;
    } catch (_) {
      return null;
    }
  }

  bool get isSignedIn =>
      user != null || (_cachedUid != null && _cachedUid!.isNotEmpty);

  String get displayName {
    if (user != null) {
      if (user!.displayName != null && user!.displayName!.trim().isNotEmpty) {
        return user!.displayName!;
      }
      for (final info in user!.providerData) {
        if (info.displayName != null && info.displayName!.trim().isNotEmpty) {
          return info.displayName!;
        }
      }
    }
    if (!kIsWeb && _googleSignIn?.currentUser?.displayName != null) {
      return _googleSignIn!.currentUser!.displayName!;
    }
    if (_cachedDisplayName != null && _cachedDisplayName!.isNotEmpty) {
      return _cachedDisplayName!;
    }
    if (email.isNotEmpty) {
      return email.split('@').first;
    }
    return 'Pengguna Google';
  }

  String get email {
    if (user != null) {
      if (user!.email != null && user!.email!.isNotEmpty) {
        return user!.email!;
      }
      for (final info in user!.providerData) {
        if (info.email != null && info.email!.isNotEmpty) {
          return info.email!;
        }
      }
    }
    if (!kIsWeb && _googleSignIn?.currentUser?.email != null) {
      return _googleSignIn!.currentUser!.email;
    }
    return _cachedEmail ?? '';
  }

  String? get photoUrl {
    if (user != null) {
      if (user!.photoURL != null && user!.photoURL!.isNotEmpty) {
        return user!.photoURL;
      }
      for (final info in user!.providerData) {
        if (info.photoURL != null && info.photoURL!.isNotEmpty) {
          return info.photoURL;
        }
      }
    }
    if (!kIsWeb && _googleSignIn?.currentUser?.photoUrl != null) {
      return _googleSignIn!.currentUser!.photoUrl;
    }
    return _cachedPhotoUrl;
  }

  AuthProvider() {
    _init();
  }

  Future<void> _loadCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _cachedPhotoUrl = prefs.getString(_cachedPhotoKey);
      _cachedDisplayName = prefs.getString(_cachedNameKey);
      _cachedEmail = prefs.getString(_cachedEmailKey);
      _cachedUid = prefs.getString(_cachedUidKey);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _saveCache() async {
    final photo = photoUrl;
    final name = displayName;
    final mail = email;
    final uid = user?.uid ?? _cachedUid;
    if (uid != null && uid.isNotEmpty) {
      try {
        final prefs = await SharedPreferences.getInstance();
        if (photo != null && photo.isNotEmpty) {
          await prefs.setString(_cachedPhotoKey, photo);
          _cachedPhotoUrl = photo;
        }
        if (name.isNotEmpty) {
          await prefs.setString(_cachedNameKey, name);
          _cachedDisplayName = name;
        }
        if (mail.isNotEmpty) {
          await prefs.setString(_cachedEmailKey, mail);
          _cachedEmail = mail;
        }
        await prefs.setString(_cachedUidKey, uid);
        _cachedUid = uid;
      } catch (_) {}
    }
  }

  Future<void> _clearCache() async {
    _cachedPhotoUrl = null;
    _cachedDisplayName = null;
    _cachedEmail = null;
    _cachedUid = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cachedPhotoKey);
      await prefs.remove(_cachedNameKey);
      await prefs.remove(_cachedEmailKey);
      await prefs.remove(_cachedUidKey);
    } catch (_) {}
  }

  Future<void> _init() async {
    await _loadCache();
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      _auth = FirebaseAuth.instance;
      if (!kIsWeb) {
        _googleSignIn = GoogleSignIn(
          scopes: ['email', 'profile'],
        );
        if (_auth?.currentUser != null) {
          try {
            await _googleSignIn?.signInSilently();
          } catch (_) {}
        }
      }

      _authSub = _auth?.authStateChanges().listen((user) {
        if (user != null) {
          _saveCache();
        } else if (_isInitialized) {
          _clearCache();
        }
        notifyListeners();
      });

      if (_auth?.currentUser != null) {
        await _saveCache();
      }

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Firebase/Auth init warning: $e');
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_auth == null) {
        await _init();
      }
      if (_auth == null) {
        throw Exception('Firebase Auth belum siap.');
      }

      UserCredential userCredential;

      if (kIsWeb) {
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        userCredential = await _auth!.signInWithPopup(googleProvider);
      } else {
        _googleSignIn ??= GoogleSignIn();
        final GoogleSignInAccount? googleUser = await _googleSignIn!.signIn();
        if (googleUser == null) {
          // User canceled the sign-in flow
          _isLoading = false;
          notifyListeners();
          return false;
        }

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        userCredential = await _auth!.signInWithCredential(credential);
      }

      _isLoading = false;
      if (userCredential.user != null) {
        await _saveCache();
      }
      notifyListeners();
      return userCredential.user != null;
    } catch (e) {
      debugPrint('Error signing in with Google: $e');
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _clearCache();
      if (!kIsWeb) {
        await _googleSignIn?.signOut();
      }
      await _auth?.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
