import { Queue } from 'bullmq';
import { redis } from './redisClient';

export interface AIJobPayload {
  jobId: string;
  userId: string;
  baselinePhotoStoragePath: string;
  goalType: 'fat_loss' | 'muscle_gain' | 'recomposition';
  goalMonths: 3 | 6 | 12;
  trainingDaysPerWeek: number;
}

export const aiJobQueue = new Queue<AIJobPayload>('ai-generation', {
  connection: redis,
  defaultJobOptions: {
    attempts: 3,
    backoff: { type: 'exponential', delay: 5000 },
    removeOnComplete: 100,
    removeOnFail: 500,
  },
});
