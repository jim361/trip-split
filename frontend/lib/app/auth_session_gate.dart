import 'dart:async';

import 'package:flutter/material.dart';

import '../domain/models.dart';
import '../services/auth_service.dart';

final class AuthSessionScope extends InheritedWidget {
  const AuthSessionScope({
    required this.user,
    required this.linkGoogleAccount,
    required super.child,
    super.key,
  });

  final AuthUser user;
  final Future<AuthUser> Function() linkGoogleAccount;

  static AuthSessionScope of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<AuthSessionScope>();
    assert(scope != null, 'AuthSessionScope가 필요합니다.');
    return scope!;
  }

  @override
  bool updateShouldNotify(AuthSessionScope oldWidget) => oldWidget.user != user;
}

/// [TASK-02 · 익명 인증] 모든 route 앞에서 Firebase uid 세션을 자동으로 준비합니다.
final class AuthSessionGate extends StatefulWidget {
  const AuthSessionGate({
    required this.authService,
    required this.child,
    super.key,
  });

  final AuthService authService;
  final Widget child;

  @override
  State<AuthSessionGate> createState() => _AuthSessionGateState();
}

final class _AuthSessionGateState extends State<AuthSessionGate> {
  StreamSubscription<AuthUser?>? _subscription;
  AuthUser? _user;
  AppError? _error;
  bool _ensuring = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error case final error?) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off_outlined, size: 40),
                  const SizedBox(height: 12),
                  Text(error.message, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton(onPressed: _start, child: const Text('다시 시도')),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final user = _user;
    if (user == null) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return AuthSessionScope(
      user: user,
      linkGoogleAccount: _linkGoogleAccount,
      child: widget.child,
    );
  }

  Future<void> _start() async {
    setState(() {
      _error = null;
      _user = null;
    });
    await _subscription?.cancel();
    _subscription = widget.authService.authStateChanges().listen((user) {
      if (!mounted) return;
      setState(() => _user = user);
      if (user == null) unawaited(_ensureSession());
    }, onError: _setError);
    await _ensureSession();
  }

  Future<void> _ensureSession() async {
    if (_ensuring) return;
    _ensuring = true;
    try {
      final user = await widget.authService.ensureAnonymousSession();
      if (mounted) setState(() => _user = user);
    } catch (error) {
      _setError(error);
    } finally {
      _ensuring = false;
    }
  }

  Future<AuthUser> _linkGoogleAccount() async {
    final user = await widget.authService.linkGoogleAccount();
    if (mounted) setState(() => _user = user);
    return user;
  }

  void _setError(Object error) {
    if (!mounted) return;
    setState(() {
      _error = error is AppError
          ? error
          : AppError(
              code: AppErrorCode.unknown,
              message: '인증 세션을 시작하지 못했습니다.',
              retryable: true,
              details: {'cause': error.toString()},
            );
    });
  }
}
