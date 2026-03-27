import 'dotenv/config';
import cron from 'node-cron';
import { prisma } from '../db/client';
import { pushNotificationService } from '../services/pushNotificationService';

/**
 * Weekly Check-In Reminder Scheduler
 *
 * Runs every day at 9:00 AM (server time).
 * Finds all users whose preferred check-in weekday matches today
 * and sends them a push notification reminder.
 *
 * Weekday convention: 0 = Sunday, 1 = Monday, ..., 6 = Saturday
 * (matches JavaScript's Date.getDay())
 */

function getTodayWeekday(): number {
  return new Date().getDay(); // 0 = Sunday
}

async function sendReminders(): Promise<void> {
  const todayWeekday = getTodayWeekday();

  console.log(`[Scheduler] Running weekly reminder check for weekday ${todayWeekday}`);

  const users = await prisma.user.findMany({
    where: {
      checkInWeekday: todayWeekday,
      apnsToken: { not: null },
      deletedAt: null,
    },
    select: {
      id: true,
      apnsToken: true,
    },
  });

  console.log(`[Scheduler] Found ${users.length} user(s) to remind`);

  for (const user of users) {
    if (user.apnsToken) {
      try {
        await pushNotificationService.sendWeeklyCheckInReminder(user.apnsToken);
        console.log(`[Scheduler] Reminder sent to user ${user.id}`);
      } catch (err) {
        console.warn(`[Scheduler] Failed to send reminder to user ${user.id}:`, err);
      }
    }
  }
}

// Schedule: every day at 09:00
cron.schedule('0 9 * * *', async () => {
  try {
    await sendReminders();
  } catch (err) {
    console.error('[Scheduler] Reminder job failed:', err);
  }
});

console.log('[Scheduler] Weekly check-in reminder scheduler started (daily at 09:00)');

export { sendReminders };
