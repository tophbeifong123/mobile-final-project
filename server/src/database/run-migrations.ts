import { AppDataSource } from './data-source.js';

const dataSource = await AppDataSource.initialize();
let failed = false;
try {
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
  if (dataSource.isInitialized) {
    await dataSource.destroy();
  }
}

if (failed) {
  process.exit(1);
}
