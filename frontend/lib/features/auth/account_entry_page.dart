import 'package:flutter/material.dart';

import '../../app/auth_session_gate.dart';
import '../../domain/models.dart';
import '../../shared/theme/app_theme.dart';

/// 익명 uid를 유지하면서 계정 연결 방식을 선택하는 비차단 시작 화면입니다.
final class AccountEntryPage extends StatefulWidget {
  const AccountEntryPage({super.key});

  @override
  State<AccountEntryPage> createState() => _AccountEntryPageState();
}

final class _AccountEntryPageState extends State<AccountEntryPage> {
  bool _linking = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final auth = AuthSessionScope.of(context);
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            const Icon(Icons.menu, size: 20, semanticLabel: '메뉴'),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'TRIP SPLIT / ACCOUNT',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall
                    ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.6),
              ),
            ),
          ],
        ),
        actions: [
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final expanded = constraints.maxWidth >= AppTheme.mediumBreakpoint;
          final padding = EdgeInsets.symmetric(
            horizontal: expanded ? 40 : 16,
            vertical: expanded ? 64 : 32,
          );
          final contentWidth = (constraints.maxWidth - padding.horizontal)
              .clamp(0.0, 600.0)
              .toDouble();
          final availableHeight = (constraints.maxHeight - padding.vertical)
              .clamp(0.0, double.infinity)
              .toDouble();

          return SingleChildScrollView(
            key: Key(
              expanded ? 'account-entry-expanded' : 'account-entry-compact',
            ),
            padding: padding,
            child: Center(
              child: SizedBox(
                width: contentWidth,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: availableHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _EntryIntroduction(expanded: expanded),
                        _EntryActions(
                          anonymous: auth.user.isAnonymous,
                          linking: _linking,
                          error: _error,
                          onGoogle: () => _continueWithGoogle(auth),
                          onGuest: _openTrips,
                          onShareCode: _openJoin,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _continueWithGoogle(AuthSessionScope auth) async {
    if (!auth.user.isAnonymous) {
      _openTrips();
      return;
    }
    setState(() {
      _linking = true;
      _error = null;
    });
    try {
      await auth.linkGoogleAccount();
      if (mounted) _openTrips();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error is AppError ? error.message : 'Google 계정을 연결하지 못했습니다.';
      });
    } finally {
      if (mounted) setState(() => _linking = false);
    }
  }

  void _openTrips() {
    Navigator.of(context).pushReplacementNamed('/trips');
  }

  void _openJoin() {
    Navigator.of(context).pushReplacementNamed('/trips?join=true');
  }
}

final class _EntryIntroduction extends StatelessWidget {
  const _EntryIntroduction({required this.expanded});

  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
          ),
          child: Text(
            'Trip Split',
            style: theme.textTheme.displaySmall?.copyWith(
              fontSize: expanded ? 48 : 36,
              fontWeight: FontWeight.w800,
              height: 1.1,
              letterSpacing: expanded ? -1.9 : -1.4,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          '여행을 선택하고 일정을 시작하세요.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 18,
            fontWeight: FontWeight.w500,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

final class _EntryActions extends StatelessWidget {
  const _EntryActions({
    required this.anonymous,
    required this.linking,
    required this.error,
    required this.onGoogle,
    required this.onGuest,
    required this.onShareCode,
  });

  final bool anonymous;
  final bool linking;
  final String? error;
  final VoidCallback onGoogle;
  final VoidCallback onGuest;
  final VoidCallback onShareCode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonTextStyle = theme.textTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: 0.6,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton(
          key: const Key('account-continue-google'),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
            textStyle: buttonTextStyle,
          ),
          onPressed: linking ? null : onGoogle,
          child: Text(
            linking
                ? '연결 중'
                : anonymous
                ? 'Google로 계속'
                : '내 여행으로 계속',
          ),
        ),
        if (anonymous) ...[
          const SizedBox(height: 24),
          OutlinedButton(
            key: const Key('account-continue-guest'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              side: BorderSide(
                color: theme.colorScheme.onSurface,
                width: AppTheme.outlineStroke,
              ),
              shape: const RoundedRectangleBorder(),
              textStyle: buttonTextStyle,
            ),
            onPressed: linking ? null : onGuest,
            child: const Text('계정 없이 시작'),
          ),
        ],
        const SizedBox(height: 24),
        TextButton(
          key: const Key('account-continue-share'),
          onPressed: linking ? null : onShareCode,
          child: const Text(
            '공유 코드로 여행 참여',
            style: TextStyle(
              decoration: TextDecoration.underline,
              decorationThickness: 1,
            ),
          ),
        ),
        if (anonymous) ...[
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),
          Text(
            '계정 없이 시작해도 나중에 Google로 연결할 수 있어요.',
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.outline,
              fontSize: 11,
              height: 1.35,
            ),
          ),
        ],
        if (error case final message?) ...[
          const SizedBox(height: 12),
          Text(
            message,
            key: const Key('account-entry-error'),
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.colorScheme.error),
          ),
        ],
        const SizedBox(height: 64),
      ],
    );
  }
}
