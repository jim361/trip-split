import 'package:flutter_test/flutter_test.dart';
import 'package:trip_split/data/firebase/firestore_trip_repositories.dart';
import 'package:trip_split/domain/models.dart';

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
}
