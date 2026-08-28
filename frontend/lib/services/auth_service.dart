final class AuthUser {
  const AuthUser({
    required this.uid,
    required this.displayName,
    required this.isAnonymous,
    this.email,
    this.photoUrl,
  });

  final String uid;
  final String displayName;
  final String? email;
  final String? photoUrl;
  final bool isAnonymous;
}

abstract interface class AuthService {
  Stream<AuthUser?> authStateChanges();

  Future<AuthUser> ensureAnonymousSession();

  Future<AuthUser> linkGoogleAccount();
}
