import { type MigrationInterface, type QueryRunner } from 'typeorm';

export class CreateApplicationDocuments1791950000000 implements MigrationInterface {
  name = 'CreateApplicationDocuments1791950000000';
  async up(runner: QueryRunner): Promise<void> {
    await runner.query(`CREATE TABLE application_documents (
      id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
      application_id uuid NOT NULL REFERENCES applications(id) ON DELETE CASCADE,
      type varchar(16) NOT NULL CHECK (type IN ('cv', 'transcript', 'other')),
      file_name varchar(255) NOT NULL,
      object_key varchar(1024) NOT NULL,
      created_at timestamptz NOT NULL DEFAULT now()
    )`);
    await runner.query(
      `CREATE UNIQUE INDEX "UQ_application_documents_single_type" ON application_documents(application_id, type) WHERE type IN ('cv', 'transcript')`,
    );
    await runner.query(
      `CREATE INDEX "IDX_application_documents_application" ON application_documents(application_id)`,
    );
    await runner.query(
      `CREATE INDEX "IDX_application_documents_object" ON application_documents(object_key)`,
    );
    // Old applications only consented to a CV; never backfill current optional files.
    await runner.query(`INSERT INTO application_documents(application_id, type, file_name, object_key, created_at)
      SELECT id, 'cv', COALESCE(resume_file_name, 'CV.pdf'), resume_object_key, created_at
      FROM applications WHERE resume_object_key IS NOT NULL`);
  }
  async down(runner: QueryRunner): Promise<void> {
    const [{ count }] = await runner.query(
      `SELECT count(*)::int AS count FROM application_documents WHERE type <> 'cv'`,
    );
    if (count > 0)
      throw new Error(
        'Cannot rollback while optional application document snapshots exist',
      );
    await runner.query(
      `UPDATE applications AS app SET resume_file_name = doc.file_name, resume_object_key = doc.object_key FROM application_documents AS doc WHERE doc.application_id = app.id AND doc.type = 'cv'`,
    );
    await runner.query('DROP TABLE application_documents');
  }
}
