import 'package:client/features/applications/domain/selection_progress.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final deadline = DateTime.utc(2026, 10, 8, 12);

  test('labels an open exam, a finished exam, and an interview', () {
    expect(
      selectionProgressLabel(
        examUrl: 'https://exam.example/quiz',
        examDeadline: deadline,
        now: DateTime.utc(2026, 10, 8, 11),
      ),
      'รอทำข้อสอบ',
    );
    expect(
      selectionProgressLabel(
        examUrl: 'https://exam.example/quiz',
        examDeadline: deadline,
        examCompletedAt: DateTime.utc(2026, 10, 8, 11),
        now: DateTime.utc(2026, 10, 8, 11),
      ),
      'รอผลข้อสอบ',
    );
    expect(
      selectionProgressLabel(
        examUrl: 'https://exam.example/quiz',
        examDeadline: deadline,
        examCompletedAt: DateTime.utc(2026, 10, 8, 11),
        examPassedAt: DateTime.utc(2026, 10, 8, 12),
        now: DateTime.utc(2026, 10, 8, 12),
      ),
      'ข้อสอบผ่านแล้ว',
    );
    expect(
      selectionProgressLabel(
        interviewUrl: 'https://meet.example/room',
        now: deadline,
      ),
      'มีนัดสัมภาษณ์',
    );
    expect(
      selectionProgressLabel(
        examUrl: 'https://exam.example/quiz',
        examDeadline: deadline,
        now: DateTime.utc(2026, 10, 8, 13),
      ),
      'ข้อสอบหมดเวลา',
    );
  });

  test(
    'closes the exam link after the deadline or after the student finishes',
    () {
      expect(
        examCanBeOpened(
          examUrl: 'https://exam.example/quiz',
          examDeadline: deadline,
          now: DateTime.utc(2026, 10, 8, 11),
        ),
        isTrue,
      );
      expect(
        examCanBeOpened(
          examUrl: 'https://exam.example/quiz',
          examDeadline: deadline,
          now: DateTime.utc(2026, 10, 8, 13),
        ),
        isFalse,
      );
      expect(
        examCanBeOpened(
          examUrl: 'https://exam.example/quiz',
          examDeadline: deadline,
          examCompletedAt: DateTime.utc(2026, 10, 8, 11),
          now: DateTime.utc(2026, 10, 8, 11),
        ),
        isFalse,
      );
    },
  );
}
