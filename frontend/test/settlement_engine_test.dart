import 'package:flutter_test/flutter_test.dart';
import 'package:trip_split/domain/models.dart';
import 'package:trip_split/features/settlement/settlement_engine.dart';

void main() {
  const consumers = ['me', 'minsu', 'jiyeon'];

  test('10,000을 세 소비자 순서대로 3,334 / 3,333 / 3,333으로 배분한다', () {
    expect(
      _pairs(allocateEqually(totalAmount: 10000, consumers: consumers)),
      const [('me', 3334), ('minsu', 3333), ('jiyeon', 3333)],
    );
  });

  test('1을 나눌 때 0원 소비자 행도 유지한다', () {
    expect(
      _pairs(allocateEqually(totalAmount: 1, consumers: consumers)),
      const [('me', 1), ('minsu', 0), ('jiyeon', 0)],
    );
  });

  test('음수 나머지를 앞 소비자부터 -1씩 배분한다', () {
    expect(
      _pairs(allocateEqually(totalAmount: -1000, consumers: consumers)),
      const [('me', -334), ('minsu', -333), ('jiyeon', -333)],
    );
  });

  test('빈 소비자는 invalid-argument로 거부한다', () {
    expect(
      () => allocateEqually(totalAmount: 1000, consumers: const []),
      throwsA(
        isA<AppError>()
            .having((error) => error.code, 'code', AppErrorCode.invalidArgument)
            .having((error) => error.field, 'field', 'consumers'),
      ),
    );
  });

  test('중복 participantId는 invalid-argument로 거부한다', () {
    expect(
      () => allocateEqually(totalAmount: 1000, consumers: const ['me', 'me']),
      throwsA(
        isA<AppError>()
            .having((error) => error.code, 'code', AppErrorCode.invalidArgument)
            .having((error) => error.field, 'field', 'consumers'),
      ),
    );
  });

  test('같은 입력은 결정적인 결과를 만들고 입력을 변경하지 않는다', () {
    final mutableConsumers = <ParticipantId>['jiyeon', 'me', 'minsu'];
    final before = List<ParticipantId>.of(mutableConsumers);

    final first = allocateEqually(
      totalAmount: 10000,
      consumers: mutableConsumers,
    );
    final second = allocateEqually(
      totalAmount: 10000,
      consumers: mutableConsumers,
    );

    expect(mutableConsumers, before);
    expect(_pairs(first), _pairs(second));
    expect(_pairs(first), const [
      ('jiyeon', 3334),
      ('me', 3333),
      ('minsu', 3333),
    ]);
  });
}

List<(ParticipantId, CurrencyAmount)> _pairs(
  List<MoneyAllocation> allocations,
) {
  return allocations
      .map((allocation) => (allocation.participantId, allocation.amount))
      .toList(growable: false);
}
