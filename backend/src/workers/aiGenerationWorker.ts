import 'dotenv/config';
import { Worker, Job } from 'bullmq';
import { redis } from './redisClient';
import { AIJobPayload } from './aiJobQueue';
import { prisma } from '../db/client';
import { getImageGenerationProvider } from '../providers/imageGenerationProvider';
import { storageService } from '../services/storageService';
import { pushNotificationService } from '../services/pushNotificationService';

const worker = new Worker<AIJobPayload>(
  'ai-generation',
  async (job: Job<AIJobPayload>) => {
    const { jobId, userId, baselinePhotoStoragePath, goalType, goalMonths, trainingDaysPerWeek } = job.data;

    console.log(`[Worker] Processing job ${jobId}`);

    // Mark as processing
    await prisma.aIGenerationJob.update({
      where: { id: jobId },
      data: { status: 'processing', attempts: { increment: 1 } },
    });

    // Get signed download URL for baseline photo
    const baselinePhotoURL = await storageService.getSignedUrl(baselinePhotoStoragePath, 300);

    // Build structured prompt
    const prompt = buildTransformationPrompt({ goalType, goalMonths, trainingDaysPerWeek });
    const negativePrompt = 'unrealistic, cartoon, painting, blurry, different person, different face, nsfw, revealing';

    // Run AI generation
    const provider = getImageGenerationProvider();
    const resultImageBuffer = await provider.generate({
      baseImageURL: baselinePhotoURL,
      prompt,
      negativePrompt,
    });

    // Validate output (basic size check)
    if (resultImageBuffer.byteLength < 10_000) {
      throw new Error('Generated image too small — likely invalid output');
    }

    // Store result
    const resultPath = `${userId}/ai-results/${jobId}.jpg`;
    await storageService.upload(resultPath, Buffer.from(resultImageBuffer), 'image/jpeg');

    // Mark completed
    await prisma.aIGenerationJob.update({
      where: { id: jobId },
      data: { status: 'completed', resultStoragePath: resultPath },
    });

    // Fire push notification
    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (user?.apnsToken) {
      await pushNotificationService.sendRevealReady(user.apnsToken, jobId);
    }

    console.log(`[Worker] Job ${jobId} completed`);
  },
  {
    connection: redis,
    concurrency: 2,
  }
);

worker.on('failed', async (job, err) => {
  if (!job) return;
  const { jobId } = job.data;
  console.error(`[Worker] Job ${jobId} failed:`, err.message);

  // Only mark failed after all retries exhausted
  if (job.attemptsMade >= (job.opts.attempts ?? 3)) {
    await prisma.aIGenerationJob.update({
      where: { id: jobId },
      data: { status: 'failed', errorMessage: err.message },
    });
  }
});

worker.on('ready', () => console.log('[Worker] AI generation worker ready'));

function buildTransformationPrompt({
  goalType,
  goalMonths,
  trainingDaysPerWeek,
}: {
  goalType: string;
  goalMonths: number;
  trainingDaysPerWeek: number;
}): string {
  const goalDescriptions: Record<string, string> = {
    fat_loss: `significantly leaner physique with visible muscle definition, reduced body fat after ${goalMonths} months of consistent training`,
    muscle_gain: `visibly more muscular and developed physique with increased muscle mass and size after ${goalMonths} months of resistance training`,
    recomposition: `improved body composition with simultaneously reduced fat and increased muscle definition after ${goalMonths} months of training`,
  };

  const description = goalDescriptions[goalType] ?? goalDescriptions['fat_loss'];

  return (
    `The same person in the input photo, same face, same skin tone, same hair, ` +
    `but with a ${description}. ` +
    `Training ${trainingDaysPerWeek} days per week. ` +
    `Realistic, photographic, natural lighting, full body visible, athletic wear, gym or outdoor setting. ` +
    `Photorealistic, 8K quality, same pose and framing as input image.`
  );
}

export default worker;
