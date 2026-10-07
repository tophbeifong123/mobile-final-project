import { BadRequestException } from '@nestjs/common';
import { ApplicationStatus } from './application-status.js';
import { InterviewMode } from '../jobs/job-enums.js';
import {
  EXAM_ALREADY_COMPLETED,
  EXAM_DEADLINE_PASSED,
  EXAM_LINK_LOCKED,
  EXAM_NOT_OPEN,
  INTERVIEW_ONSITE_HAS_NO_LINK,
  EXAM_ALREADY_PASSED,
  EXAM_NOT_FINISHED,
  INTERVIEW_REQUIRES_PASSED_EXAM,
  SELECTION_LINK_INVALID,
  SELECTION_ONLY_WHILE_REVIEWING,
  SELECTION_TIME_MUST_BE_FUTURE,
} from './applications.constants.js';
import {
  assertCanCompleteExam,
  assertCanPassExam,
  assertCanSetExam,
  assertCanSetInterview,
  assertFutureInstant,
  assertPublicHttpUrl,
  interviewUrlForMode,
  type SelectionState,
} from './selection-link.js';

const future = new Date(Date.now() + 60 * 60 * 1000);
const past = new Date(Date.now() - 60 * 1000);

function state(overrides: Partial<SelectionState> = {}): SelectionState {
  return {
    status: ApplicationStatus.Reviewing,
    examUrl: null,
    examDeadline: null,
    examCompletedAt: null,
    examPassedAt: null,
    ...overrides,
  };
}

describe('selection links', () => {
  it('accepts a public http url and rejects credentials or other schemes', () => {
    expect(assertPublicHttpUrl(' https://exam.example/quiz ')).toBe(
      'https://exam.example/quiz',
    );
    expect(() => assertPublicHttpUrl('https://user:secret@exam.example/quiz')).toThrow(
      new BadRequestException(SELECTION_LINK_INVALID),
    );
    expect(() => assertPublicHttpUrl('javascript:alert(1)')).toThrow(
      BadRequestException,
    );
  });

  it('requires a future instant', () => {
    expect(assertFutureInstant(future)).toEqual(future);
    expect(() => assertFutureInstant(past)).toThrow(
      new BadRequestException(SELECTION_TIME_MUST_BE_FUTURE),
    );
  });

  it('lets a company set an exam only while reviewing and before the student finishes', () => {
    expect(() => assertCanSetExam(state())).not.toThrow();
    expect(() =>
      assertCanSetExam(state({ status: ApplicationStatus.Submitted })),
    ).toThrow(new BadRequestException(SELECTION_ONLY_WHILE_REVIEWING));
    expect(() =>
      assertCanSetExam(state({ status: ApplicationStatus.Accepted })),
    ).toThrow(BadRequestException);
    expect(() =>
      assertCanSetExam(state({ examCompletedAt: new Date() })),
    ).toThrow(new BadRequestException(EXAM_LINK_LOCKED));
  });

  it('lets a company pass an exam only after the student finishes it', () => {
    const finished = new Date();
    expect(() =>
      assertCanPassExam(state({ examCompletedAt: finished })),
    ).not.toThrow();
    expect(() => assertCanPassExam(state())).toThrow(
      new BadRequestException(EXAM_NOT_FINISHED),
    );
    expect(() =>
      assertCanPassExam(
        state({ examCompletedAt: finished, examPassedAt: new Date() }),
      ),
    ).toThrow(new BadRequestException(EXAM_ALREADY_PASSED));
  });

  it('lets a company invite only after the company marks the exam passed', () => {
    const finished = new Date();
    expect(() =>
      assertCanSetInterview(
        state({ examCompletedAt: finished, examPassedAt: new Date() }),
      ),
    ).not.toThrow();
    expect(() =>
      assertCanSetInterview(state({ examCompletedAt: finished })),
    ).toThrow(new BadRequestException(INTERVIEW_REQUIRES_PASSED_EXAM));
    expect(() =>
      assertCanSetInterview(
        state({
          status: ApplicationStatus.Rejected,
          examCompletedAt: new Date(),
        }),
      ),
    ).toThrow(new BadRequestException(SELECTION_ONLY_WHILE_REVIEWING));
  });

  it('requires a meeting link only for an online interview', () => {
    expect(interviewUrlForMode(InterviewMode.Online, ' https://meet.example/room ')).toBe(
      'https://meet.example/room',
    );
    expect(interviewUrlForMode(InterviewMode.OnSite, '  ')).toBeNull();
    expect(() => interviewUrlForMode(InterviewMode.Online, '')).toThrow(
      new BadRequestException(SELECTION_LINK_INVALID),
    );
    expect(() =>
      interviewUrlForMode(InterviewMode.OnSite, 'https://meet.example/room'),
    ).toThrow(new BadRequestException(INTERVIEW_ONSITE_HAS_NO_LINK));
  });

  it('lets the student mark an open exam done once before the deadline', () => {
    const open = state({
      examUrl: 'https://exam.example/quiz',
      examDeadline: future,
    });
    expect(() => assertCanCompleteExam(open, new Date())).not.toThrow();
    expect(() => assertCanCompleteExam(state(), new Date())).toThrow(
      new BadRequestException(EXAM_NOT_OPEN),
    );
    expect(() =>
      assertCanCompleteExam(
        state({
          examUrl: 'https://exam.example/quiz',
          examDeadline: past,
        }),
        new Date(),
      ),
    ).toThrow(new BadRequestException(EXAM_DEADLINE_PASSED));
    expect(() =>
      assertCanCompleteExam(
        state({
          examUrl: 'https://exam.example/quiz',
          examDeadline: future,
          examCompletedAt: new Date(),
        }),
        new Date(),
      ),
    ).toThrow(new BadRequestException(EXAM_ALREADY_COMPLETED));
    expect(() =>
      assertCanCompleteExam(
        state({
          status: ApplicationStatus.Submitted,
          examUrl: 'https://exam.example/quiz',
          examDeadline: future,
        }),
        new Date(),
      ),
    ).toThrow(BadRequestException);
  });
});
