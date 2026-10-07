import { AppDataSource } from './data-source.js';

// Every replica runs this on start; the advisory lock lets only one apply migrations at a time.
const MIGRATION_LOCK_ID = 7_301_966;

const dataSource = await AppDataSource.initialize();
const lockRunner = dataSource.createQueryRunner();
let failed = false;
try {
  await lockRunner.connect();
  await lockRunner.query('SELECT pg_advisory_lock($1)', [MIGRATION_LOCK_ID]);
  const applied = await dataSource.runMigrations();
  if (applied.length === 0) {
    console.log('No pending migrations');
  } else {
    console.log(`Ran ${applied.map((migration) => migration.name).join(', ')}`);
  }
} catch (error) {
  console.error(error);
  failed = true;
} finally {
  await lockRunner
    .query('SELECT pg_advisory_unlock($1)', [MIGRATION_LOCK_ID])
    .catch(() => undefined);
  await lockRunner.release();
  if (dataSource.isInitialized) {
    await dataSource.destroy();
  }
}

if (failed) {
  process.exit(1);
}
