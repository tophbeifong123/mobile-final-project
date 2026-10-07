String? selectionProgressLabel({
  String? examUrl,
  DateTime? examDeadline,
  DateTime? examCompletedAt,
  DateTime? examPassedAt,
  String? interviewUrl,
  DateTime? interviewStartsAt,
  DateTime? now,
}) {
  final clock = now ?? DateTime.now();
  final hasExam = examUrl != null && examUrl.isNotEmpty;
  final hasInterview =
      (interviewUrl != null && interviewUrl.isNotEmpty) ||
      interviewStartsAt != null;
  if (hasInterview) return 'มีนัดสัมภาษณ์';
  if (examPassedAt != null) return 'ข้อสอบผ่านแล้ว';
  if (hasExam && examCompletedAt != null) return 'รอผลข้อสอบ';
  if (!hasExam) return null;
  final expired = examDeadline != null && clock.isAfter(examDeadline);
  return expired ? 'ข้อสอบหมดเวลา' : 'รอทำข้อสอบ';
}

bool examCanBeOpened({
  String? examUrl,
  DateTime? examDeadline,
  DateTime? examCompletedAt,
  DateTime? now,
}) {
  if (examUrl == null || examUrl.isEmpty || examCompletedAt != null) {
    return false;
  }
  if (examDeadline == null) return false;
  return (now ?? DateTime.now()).isBefore(examDeadline) ||
      (now ?? DateTime.now()).isAtSameMomentAs(examDeadline);
}

String formatSelectionWhen(DateTime value) {
  final local = value.toLocal();
  String two(int number) => number.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)}/${local.year} ${two(local.hour)}:${two(local.minute)}';
}
