import 'package:flutter_test/flutter_test.dart';
import 'package:trip_split/services/mock_auth_service.dart';

void main() {
  test('mock은 익명 세션을 자동 시작하고 Google 연결 후 uid를 유지한다', () async {
    final service = MockAuthService();
    addTearDown(service.dispose);

    final anonymous = await service.ensureAnonymousSession();
    final linked = await service.linkGoogleAccount();

    expect(anonymous.isAnonymous, isTrue);
    expect(linked.uid, anonymous.uid);
    expect(linked.isAnonymous, isFalse);
  });
}
