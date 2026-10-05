import { runDuesNow, runRemindersNow, runPenaltiesNow } from '../jobs';
import { closePool } from '../config/database';

const job = process.argv[2];

(async () => {
  try {
    switch (job) {
      case 'dues': {
        console.log('Running dues generation…');
        await runDuesNow();
        break;
      }
      case 'reminders': {
        console.log('Running payment reminders…');
        await runRemindersNow();
        break;
      }
      case 'penalties': {
        console.log('Running automatic penalties…');
        const result = await runPenaltiesNow();
        if (!result.enabled) {
          console.log('Penalties are disabled in settings. Enable with:');
          console.log('  PUT /settings/penalty.enabled  { "value": true }');
        } else {
          console.log(`Created: ${result.created}, Skipped: ${result.skipped}`);
        }
        break;
      }
      default: {
        console.log('Usage: ts-node src/scripts/run-job.ts [dues|reminders|penalties]');
      }
    }
  } catch (err: any) {
    console.error('Job failed:', err.message);
    process.exit(1);
  } finally {
    await closePool();
  }
})();