import { AppDataSource } from './data-source.js';

const dataSource = await AppDataSource.initialize();
try {
  const applied = await dataSource.runMigrations();
  if (applied.length === 0) {
    console.log('No pending migrations');
  } else {
    console.log(`Ran ${applied.map((migration) => migration.name).join(', ')}`);
  }
} finally {
  await dataSource.destroy();
}
