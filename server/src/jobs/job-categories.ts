export const JOB_CATEGORIES = [
  'IT & Software',
  'Design & UX/UI',
  'Marketing',
  'Data',
] as const;

export type JobCategory = (typeof JOB_CATEGORIES)[number];

export function isJobCategory(value: string): value is JobCategory {
  return (JOB_CATEGORIES as readonly string[]).includes(value);
}
