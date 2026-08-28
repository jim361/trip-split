import '../../domain/models.dart';

/// 소비자 순서를 보존해 최소 통화 단위 정수를 균등 배분한다.
List<MoneyAllocation> allocateEqually({
  required CurrencyAmount totalAmount,
  required List<ParticipantId> consumers,
}) {
  if (consumers.isEmpty) {
    throw const AppError(
      code: AppErrorCode.invalidArgument,
      message: '소비자를 한 명 이상 선택해 주세요.',
      retryable: false,
      field: 'consumers',
    );
  }

  if (consumers.toSet().length != consumers.length) {
    throw const AppError(
      code: AppErrorCode.invalidArgument,
      message: '같은 참여자를 소비자에 두 번 넣을 수 없습니다.',
      retryable: false,
      field: 'consumers',
    );
  }

  final baseAmount = totalAmount ~/ consumers.length;
  final remainder = totalAmount - (baseAmount * consumers.length);
  final remainderCount = remainder.abs();
  final remainderUnit = remainder.sign;

  return List<MoneyAllocation>.unmodifiable(
    List<MoneyAllocation>.generate(consumers.length, (index) {
      return MoneyAllocation(
        participantId: consumers[index],
        amount: baseAmount + (index < remainderCount ? remainderUnit : 0),
      );
    }),
  );
}
