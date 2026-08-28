import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trip_split/app/auth_session_gate.dart';
import 'package:trip_split/services/auth_service.dart';

void main() {
  testWidgets('인증 세션이 사라지면 새 익명 uid를 자동으로 준비한다', (tester) async {
    final auth = _RestartingAuthService();
    addTearDown(auth.dispose);

    await tester.pumpWidget(
      AuthSessionGate(
        authService: auth,
        child: MaterialApp(
          home: Builder(
            builder: (context) =>
                Scaffold(body: Text(AuthSessionScope.of(context).user.uid)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('anonymous-1'), findsOneWidget);

    auth.expireSession();
    await tester.pumpAndSettle();

    expect(find.text('anonymous-2'), findsOneWidget);
    expect(auth.ensureCalls, 2);
  });
}

final class _RestartingAuthService implements AuthService {
  final _changes = StreamController<AuthUser?>.broadcast();
  var ensureCalls = 0;

  @override
  Stream<AuthUser?> authStateChanges() => _changes.stream;

  @override
  Future<AuthUser> ensureAnonymousSession() async {
    final user = AuthUser(
      uid: 'anonymous-${++ensureCalls}',
      displayName: '여행자',
      isAnonymous: true,
    );
    _changes.add(user);
    return user;
  }

  @override
  Future<AuthUser> linkGoogleAccount() => throw UnimplementedError();

  void expireSession() => _changes.add(null);

  Future<void> dispose() => _changes.close();
}
