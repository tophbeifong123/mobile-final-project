import { BadRequestException } from '@nestjs/common';
import { isURL } from 'class-validator';
import { InterviewMode } from '../jobs/job-enums.js';
import { ApplicationStatus } from './application-status.js';
import {
  EXAM_ALREADY_COMPLETED,
  EXAM_ALREADY_PASSED,
  EXAM_DEADLINE_PASSED,
  EXAM_LINK_LOCKED,
  EXAM_NOT_FINISHED,
  EXAM_NOT_OPEN,
  INTERVIEW_ONSITE_HAS_NO_LINK,
  INTERVIEW_REQUIRES_PASSED_EXAM,
  SELECTION_LINK_INVALID,
  SELECTION_ONLY_WHILE_REVIEWING,
  SELECTION_TIME_MUST_BE_FUTURE,
} from './applications.constants.js';

export interface SelectionState {
  status: ApplicationStatus;
  examUrl: string | null;
  examDeadline: Date | null;
  examCompletedAt: Date | null;
  examPassedAt: Date | null;
}

export function assertPublicHttpUrl(value: string): string {
  const url = value.trim();
  if (
    url.length === 0 ||
    url.length > 2048 ||
    !isURL(url, {
      protocols: ['http', 'https'],
      require_protocol: true,
      require_valid_protocol: true,
      disallow_auth: true,
    })
  ) {
    throw new BadRequestException(SELECTION_LINK_INVALID);
  }
  return url;
}

export function assertFutureInstant(value: Date): Date {
  if (Number.isNaN(value.getTime()) || value.getTime() <= Date.now()) {
    throw new BadRequestException(SELECTION_TIME_MUST_BE_FUTURE);
  }
  return value;
}

export function assertCanSetExam(application: SelectionState): void {
  assertReviewing(application);
  if (application.examCompletedAt) {
    throw new BadRequestException(EXAM_LINK_LOCKED);
  }
}

export function assertCanPassExam(application: SelectionState): void {
  assertReviewing(application);
  if (!application.examCompletedAt) {
    throw new BadRequestException(EXAM_NOT_FINISHED);
  }
  if (application.examPassedAt) {
    throw new BadRequestException(EXAM_ALREADY_PASSED);
  }
}

export function assertCanSetInterview(application: SelectionState): void {
  assertReviewing(application);
  if (!application.examPassedAt) {
    throw new BadRequestException(INTERVIEW_REQUIRES_PASSED_EXAM);
  }
}

export function interviewUrlForMode(
  mode: InterviewMode,
  url: string | null | undefined,
): string | null {
  const trimmed = url?.trim() ?? '';
  if (mode === InterviewMode.OnSite) {
    if (trimmed.length > 0) {
      throw new BadRequestException(INTERVIEW_ONSITE_HAS_NO_LINK);
    }
    return null;
  }
  return assertPublicHttpUrl(trimmed);
}

export function assertCanCompleteExam(
  application: SelectionState,
  now: Date,
): void {
  assertReviewing(application);
  if (!application.examUrl || !application.examDeadline) {
    throw new BadRequestException(EXAM_NOT_OPEN);
  }
  if (application.examCompletedAt) {
    throw new BadRequestException(EXAM_ALREADY_COMPLETED);
  }
  if (now.getTime() > application.examDeadline.getTime()) {
    throw new BadRequestException(EXAM_DEADLINE_PASSED);
  }
}

function assertReviewing(application: SelectionState): void {
  if (application.status !== ApplicationStatus.Reviewing) {
    throw new BadRequestException(SELECTION_ONLY_WHILE_REVIEWING);
  }
}
