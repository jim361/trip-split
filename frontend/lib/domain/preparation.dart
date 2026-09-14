import 'models.dart';

const reservationTypes = {
  'flight': '항공',
  'stay': '숙소',
  'transport': '교통',
  'ticket': '티켓',
  'other': '기타',
};
const reservationStatuses = {
  'planned': '확인 필요',
  'booked': '예약 완료',
  'cancelled': '취소',
};

String? preparationOptional(String? value) =>
    value?.trim().isEmpty == true ? null : value?.trim();
void validatePreparationTitle(String title) {
  if (title.trim().isEmpty || title.trim().length > 160) {
    throw const AppError(
      code: AppErrorCode.invalidArgument,
      message: '제목은 1~160자로 입력해 주세요.',
      retryable: false,
      field: 'title',
    );
  }
}

final class ReservationDraft {
  ReservationDraft({
    required String title,
    required this.type,
    required this.status,
    String? url,
    String? memo,
    this.itineraryItemId,
  }) : title = title.trim(),
       url = preparationOptional(url),
       memo = preparationOptional(memo) {
    validatePreparationTitle(this.title);
    final uri = this.url == null ? null : Uri.tryParse(this.url!);
    if (!reservationTypes.containsKey(type) ||
        !reservationStatuses.containsKey(status)) {
      throw const AppError(
        code: AppErrorCode.invalidArgument,
        message: '예약 유형과 상태를 확인해 주세요.',
        retryable: false,
      );
    }
    if (this.url != null &&
        (this.url!.length > 2048 ||
            uri == null ||
            !['http', 'https'].contains(uri.scheme) ||
            uri.host.isEmpty ||
            uri.userInfo.isNotEmpty)) {
      throw const AppError(
        code: AppErrorCode.invalidArgument,
        message: '예약 URL은 올바른 http/https 링크로 입력해 주세요.',
        retryable: false,
        field: 'url',
      );
    }
    if ((this.memo?.length ?? 0) > 2000) {
      throw const AppError(
        code: AppErrorCode.invalidArgument,
        message: '메모는 2000자까지 입력할 수 있습니다.',
        retryable: false,
        field: 'memo',
      );
    }
  }
  final String title, type, status;
  final String? url, memo, itineraryItemId;
  Map<String, Object> toJson() => {
    'title': title,
    'type': type,
    'status': status,
    'url': ?url,
    'memo': ?memo,
    'itineraryItemId': ?itineraryItemId,
  };
  factory ReservationDraft.fromJson(Map<String, dynamic> data) =>
      ReservationDraft(
        title: data['title'] as String,
        type: data['type'] as String,
        status: data['status'] as String,
        url: data['url'] as String?,
        memo: data['memo'] as String?,
        itineraryItemId: data['itineraryItemId'] as String?,
      );
}

final class ChecklistDraft {
  ChecklistDraft({
    required String title,
    this.isDone = false,
    this.scope = 'shared',
    this.assigneeParticipantId,
  }) : title = title.trim() {
    validatePreparationTitle(this.title);
    if (!['shared', 'personal'].contains(scope)) {
      throw const AppError(
        code: AppErrorCode.invalidArgument,
        message: '공동/개인 구분을 확인해 주세요.',
        retryable: false,
      );
    }
  }
  final String title, scope;
  final bool isDone;
  final String? assigneeParticipantId;
  Map<String, Object> toJson() => {
    'title': title,
    'isDone': isDone,
    'scope': scope,
    'assigneeParticipantId': ?assigneeParticipantId,
  };
  factory ChecklistDraft.fromJson(Map<String, dynamic> data) => ChecklistDraft(
    title: data['title'] as String,
    isDone: data['isDone'] as bool,
    scope: data['scope'] as String,
    assigneeParticipantId: data['assigneeParticipantId'] as String?,
  );
}

final class Reservation {
  const Reservation({
    required this.id,
    required this.tripId,
    required this.draft,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.updatedBy,
  });
  final String id, tripId, createdBy, updatedBy;
  final int createdAt, updatedAt;
  final ReservationDraft draft;
}

final class ChecklistItem {
  const ChecklistItem({
    required this.id,
    required this.tripId,
    required this.draft,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.updatedBy,
  });
  final String id, tripId, createdBy, updatedBy;
  final int createdAt, updatedAt;
  final ChecklistDraft draft;
}

abstract interface class PreparationRepository {
  Stream<List<Reservation>> watchReservations(String tripId);
  Stream<List<ChecklistItem>> watchChecklist(String tripId);
  Future<String> saveReservation(
    String tripId,
    ReservationDraft draft, {
    String? id,
  });
  Future<String> saveChecklist(
    String tripId,
    ChecklistDraft draft, {
    String? id,
  });
  Future<void> setChecklistCompleted(String tripId, String id, bool completed);
  Future<void> deleteReservation(String tripId, String id);
  Future<void> deleteChecklist(String tripId, String id);
}
