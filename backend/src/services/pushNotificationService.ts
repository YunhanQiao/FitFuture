import { APNS, Notification } from 'apns2';
import fs from 'fs';

let client: APNS | null = null;

function getClient(): APNS {
  if (!client) {
    client = new APNS({
      team: process.env.APNS_TEAM_ID!,
      keyId: process.env.APNS_KEY_ID!,
      signingKey: fs.readFileSync(process.env.APNS_KEY_PATH!, 'utf8'),
      defaultTopic: process.env.APNS_BUNDLE_ID!,
      host: process.env.APNS_PRODUCTION === 'true'
        ? 'https://api.push.apple.com'
        : 'https://api.sandbox.push.apple.com',
    });
  }
  return client;
}

export const pushNotificationService = {
  async sendRevealReady(deviceToken: string, jobId: string): Promise<void> {
    try {
      const notification = new Notification(deviceToken, {
        alert: {
          title: 'Your Future Self is Ready!',
          body: 'Tap to see your AI-powered transformation.',
        },
        sound: 'default',
        data: {
          type: 'reveal_ready',
          jobId,
        },
      });
      await getClient().send(notification);
    } catch (err) {
      // Non-fatal — iOS client polls as fallback
      console.warn('[APNs] Push failed:', err);
    }
  },

  async sendWeeklyCheckInReminder(deviceToken: string): Promise<void> {
    try {
      const notification = new Notification(deviceToken, {
        alert: {
          title: "It's check-in time!",
          body: 'Log your weekly progress photo to stay on track.',
        },
        sound: 'default',
        data: { type: 'weekly_checkin' },
      });
      await getClient().send(notification);
    } catch (err) {
      console.warn('[APNs] Weekly reminder push failed:', err);
    }
  },
};
