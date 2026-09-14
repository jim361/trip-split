import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trip_split/data/firebase/firestore_trip_repositories.dart';
import 'package:trip_split/domain/models.dart';
import 'package:trip_split/domain/repositories.dart';

const _legacy = <String, dynamic>{
  'date': '2026-11-25',
  'title': '도쿄 일정',
  'order': 0,
  'updatedAt': 0,
};

void main() {
  test('Firestore의 누락된 계획·유형만 A안·기타로 읽는다', () {
    final legacy = itineraryItemFromFirestore('trip', 'item', _legacy);
    expect(legacy.planId, 'A');
    expect(legacy.category, 'other');
    final alternate = itineraryItemFromFirestore('trip', 'item', {
      ..._legacy,
      'planId': 'B',
      'category': 'stay',
    });
    expect(alternate.planId, 'B');
    expect(alternate.category, 'stay');
  });

  test('존재하는 잘못된 계획·유형은 구독에 AppError로 전달한다', () async {
    for (final field in ['planId', 'category']) {
      for (final value in [null, 1, false, 'C', '']) {
        final subscription = Stream<Map<String, dynamic>>.value({
          ..._legacy,
          field: value,
        }).map((data) => itineraryItemFromFirestore('trip', 'item', data));
        await expectLater(
          subscription,
          emitsError(
            isA<AppError>()
                .having((error) => error.field, 'field', field)
                .having((error) => error.retryable, 'retryable', false),
          ),
        );
      }
    }
  });

  group('permission-denied 재정렬 재조회', () {
    final draft = ItineraryOrderDraft(
      date: '2026-11-25',
      planId: 'A',
      itemIds: ['item'],
    );
    final original = FirebaseException(
      plugin: 'cloud_firestore',
      code: 'permission-denied',
    );
    final item = itineraryItemFromFirestore('trip', 'item', _legacy);

    test('정상 재조회는 원래 SDK 오류를 보존한다', () async {
      await expectLater(
        classifyReorderPermissionDenied(
          draft: draft,
          originalError: original,
          reload: () async => [item],
        ),
        throwsA(same(original)),
      );
    });

    test('삭제된 문서는 notFound로 분류한다', () async {
      await expectLater(
        classifyReorderPermissionDenied(
          draft: draft,
          originalError: original,
          reload: () async => [null],
        ),
        throwsA(
          isA<AppError>().having(
            (error) => error.code,
            'code',
            AppErrorCode.notFound,
          ),
        ),
      );
    });

    test('날짜 또는 계획 이동은 conflict로 분류한다', () async {
      for (final data in [
        {..._legacy, 'date': '2026-11-26'},
        {..._legacy, 'planId': 'B'},
      ]) {
        final moved = itineraryItemFromFirestore('trip', 'item', data);
        await expectLater(
          classifyReorderPermissionDenied(
            draft: draft,
            originalError: original,
            reload: () async => [moved],
          ),
          throwsA(
            isA<AppError>().having(
              (error) => error.code,
              'code',
              AppErrorCode.conflict,
            ),
          ),
        );
      }
    });

    test('SDK 재조회 권한 오류는 원래 오류를 보존한다', () async {
      await expectLater(
        classifyReorderPermissionDenied(
          draft: draft,
          originalError: original,
          reload: () => Future<List<ItineraryItem?>>.error(
            FirebaseException(
              plugin: 'cloud_firestore',
              code: 'permission-denied',
            ),
          ),
        ),
        throwsA(same(original)),
      );
    });

    test('재조회 모델 변환 오류는 원래 오류를 보존한다', () async {
      await expectLater(
        classifyReorderPermissionDenied(
          draft: draft,
          originalError: original,
          reload: () async => [
            itineraryItemFromFirestore('trip', 'item', {
              ..._legacy,
              'title': 1,
            }),
          ],
        ),
        throwsA(same(original)),
      );
    });
  });
}
