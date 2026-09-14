import 'package:google_sign_in/google_sign_in.dart';

/// Google SDK는 앱에서 한 번만 초기화하며 Firebase 연결과 Sheets 권한은 분리합니다.
final class GoogleAccountService {
  GoogleAccountService({this.serverClientId, GoogleSignIn? signIn})
    : _signIn = signIn ?? GoogleSignIn.instance;
  final String? serverClientId;
  final GoogleSignIn _signIn;
  Future<void>? _initialization;
  String? _sheetsToken;
  Future<void> _initialize() =>
      _initialization ??= _signIn.initialize(serverClientId: serverClientId);

  Future<GoogleSignInAccount> authenticate() async {
    await _initialize();
    return _signIn.authenticate();
  }

  Future<String> authorizeSheets() async {
    await _initialize();
    if (_sheetsToken case final previous?) {
      await _signIn.authorizationClient.clearAuthorizationToken(
        accessToken: previous,
      );
    }
    const scopes = ['https://www.googleapis.com/auth/drive.file'];
    final authorization = await _signIn.authorizationClient.authorizeScopes(
      scopes,
    );
    return _sheetsToken = authorization.accessToken;
  }
}
