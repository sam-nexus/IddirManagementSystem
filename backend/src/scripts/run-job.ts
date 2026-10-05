import { runDuesNow, runRemindersNow } from '../jobs';
import { closePool } from '../config/database';

const job = process.argv[2];

(async () => {
  try {
    if (job === 'dues') {
      console.log('Running dues generation…');
      await runDuesNow();
    } else if (job === 'reminders') {
      console.log('Running payment reminders…');
      await runRemindersNow();
    } else {
      console.log('Usage: ts-node src/scripts/run-job.ts [dues|reminders]');
    }
  } catch (err: any) {
    console.error('Job failed:', err.message);
    process.exit(1);
  } finally {
    await closePool();
  }
})();