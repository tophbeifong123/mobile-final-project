import { BadRequestException } from '@nestjs/common';
import {
  StudentDocument,
  StudentDocumentType,
} from '../students/student-document.entity.js';
import { RESUME_REQUIRED } from './applications.constants.js';

/** Service policy, rechecked under the student lock before committing. */
export function selectApplicationDocuments(
  documents: StudentDocument[],
  ids: string[] = [],
): StudentDocument[] {
  if (
    !Array.isArray(ids) ||
    ids.length > 5 ||
    new Set(ids).size !== ids.length ||
    ids.some((id) => typeof id !== 'string')
  ) {
    throw new BadRequestException('รายการเอกสารที่เลือกไม่ถูกต้อง');
  }
  const cv = documents.find((doc) => doc.type === StudentDocumentType.Cv);
  if (!cv) throw new BadRequestException(RESUME_REQUIRED);
  const selected = ids.map((id) => documents.find((doc) => doc.id === id));
  if (selected.some((doc) => !doc))
    throw new BadRequestException(
      'ไม่พบเอกสารที่เลือกในคลังของคุณ กรุณาเลือกใหม่',
    );
  return [
    cv,
    ...selected.filter(
      (doc): doc is StudentDocument => !!doc && doc.id !== cv.id,
    ),
  ];
}
