import 'dart:async';

import 'auth_service.dart';

final class MockAuthService implements AuthService {
  MockAuthService({
    AuthUser initialUser = const AuthUser(
      uid: 'tokyo-owner',
      displayName: '나',
      isAnonymous: true,
    ),
  }) : _user = initialUser;

  final StreamController<AuthUser?> _changes = StreamController.broadcast();
  AuthUser _user;

  @override
  Stream<AuthUser?> authStateChanges() async* {
    yield _user;
    yield* _changes.stream;
  }

  @override
  Future<AuthUser> ensureAnonymousSession() async {
    _changes.add(_user);
    return _user;
  }

  @override
  Future<AuthUser> linkGoogleAccount() async {
    _user = AuthUser(
      uid: _user.uid,
      displayName: '나 (Google 연결)',
      email: 'demo@example.com',
      photoUrl: _user.photoUrl,
      isAnonymous: false,
    );
    _changes.add(_user);
    return _user;
  }

  Future<void> dispose() => _changes.close();
}
