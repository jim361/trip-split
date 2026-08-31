import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../data/firebase/firebase_error_mapper.dart';
import '../domain/models.dart';
import 'auth_service.dart';

final class FirebaseAuthService implements AuthService {
  FirebaseAuthService({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
    GoogleSignIn? googleSignIn,
    this.googleServerClientId,
    // ignore: prefer_initializing_formals
  }) : _auth = auth,
       // ignore: prefer_initializing_formals
       _firestore = firestore,
       _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;
  final String? googleServerClientId;
  bool _googleInitialized = false;

  @override
  Stream<AuthUser?> authStateChanges() => _auth
      .userChanges()
      .map((user) => user == null ? null : _toAuthUser(user))
      .transform(
        StreamTransformer.fromHandlers(
          handleError: (error, stackTrace, sink) {
            sink.addError(mapFirebaseError(error), stackTrace);
          },
        ),
      );

  @override
  Future<AuthUser> ensureAnonymousSession() async {
    try {
      final user = _auth.currentUser ?? (await _auth.signInAnonymously()).user;
      if (user == null) {
        throw const AppError(
          code: AppErrorCode.unauthenticated,
          message: '익명 사용자 세션을 시작하지 못했습니다.',
          retryable: true,
        );
      }
      await _upsertUserProfile(user);
      return _toAuthUser(user);
    } catch (error) {
      throw mapFirebaseError(error);
    }
  }

  @override
  Future<AuthUser> linkGoogleAccount() async {
    try {
      final current = _auth.currentUser;
      if (current == null) {
        throw const AppError(
          code: AppErrorCode.unauthenticated,
          message: '로그인 세션이 필요합니다.',
          retryable: false,
        );
      }
      if (!current.isAnonymous) {
        await _upsertUserProfile(current);
        return _toAuthUser(current);
      }

      if (!_googleInitialized) {
        await _googleSignIn.initialize(serverClientId: googleServerClientId);
        _googleInitialized = true;
      }
      final account = await _googleSignIn.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw const AppError(
          code: AppErrorCode.unauthenticated,
          message: 'Google 인증 토큰을 확인할 수 없습니다.',
          retryable: false,
        );
      }

      final credential = GoogleAuthProvider.credential(idToken: idToken);
      final linked = (await current.linkWithCredential(credential)).user;
      if (linked == null) {
        throw const AppError(
          code: AppErrorCode.unauthenticated,
          message: 'Google 계정을 연결하지 못했습니다.',
          retryable: false,
        );
      }
      if (linked.uid != current.uid) {
        throw const AppError(
          code: AppErrorCode.conflict,
          message: '기존 여행 계정과 Google 계정을 연결하지 못했습니다.',
          retryable: false,
        );
      }
      await _upsertUserProfile(linked);
      return _toAuthUser(linked);
    } catch (error) {
      throw mapFirebaseError(error);
    }
  }

  Future<void> _upsertUserProfile(User user) async {
    final reference = _firestore.collection('users').doc(user.uid);
    final existing = await reference.get();
    final profile = _toAuthUser(user);
    await reference.set({
      'displayName': profile.displayName,
      if (profile.email != null) 'email': profile.email,
      if (profile.photoUrl != null) 'photoURL': profile.photoUrl,
      'authProvider': profile.isAnonymous ? 'anonymous' : 'google',
      if (!existing.exists) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

AuthUser _toAuthUser(User user) => AuthUser(
  uid: user.uid,
  displayName: user.displayName?.trim().isNotEmpty == true
      ? user.displayName!.trim()
      : '여행자 ${user.uid.substring(0, user.uid.length < 6 ? user.uid.length : 6)}',
  email: user.email,
  photoUrl: user.photoURL,
  isAnonymous: user.isAnonymous,
);
