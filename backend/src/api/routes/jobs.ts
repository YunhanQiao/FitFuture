import { Router, Response } from 'express';
import { requireAuth, AuthRequest } from '../middleware/auth';
import { prisma } from '../../db/client';
import { aiJobQueue } from '../../workers/aiJobQueue';
import { storageService } from '../../services/storageService';
import { z } from 'zod';

export const jobsRouter = Router();

const CreateJobSchema = z.object({
  userId: z.string().uuid(),
  baselinePhotoId: z.string().uuid(),
  goalType: z.enum(['fat_loss', 'muscle_gain', 'recomposition']),
  goalMonths: z.union([z.literal(3), z.literal(6), z.literal(12)]),
  trainingDaysPerWeek: z.number().int().min(1).max(7),
});

// Create AI generation job
jobsRouter.post('/', requireAuth, async (req: AuthRequest, res: Response) => {
  const parsed = CreateJobSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: parsed.error.flatten() });
  }

  if (parsed.data.userId !== req.userId) {
    return res.status(403).json({ error: 'Forbidden' });
  }

  // Verify baseline photo belongs to user
  const photo = await prisma.photo.findFirst({
    where: { id: parsed.data.baselinePhotoId, userId: req.userId, type: 'baseline' },
  });
  if (!photo) {
    return res.status(404).json({ error: 'Baseline photo not found' });
  }

  // Create job record
  const job = await prisma.aIGenerationJob.create({
    data: {
      userId: req.userId!,
      baselinePhotoId: parsed.data.baselinePhotoId,
      status: 'queued',
    },
  });

  // Enqueue worker job
  await aiJobQueue.add('generate', {
    jobId: job.id,
    userId: req.userId,
    baselinePhotoStoragePath: photo.storagePath,
    goalType: parsed.data.goalType,
    goalMonths: parsed.data.goalMonths,
    trainingDaysPerWeek: parsed.data.trainingDaysPerWeek,
  }, {
    attempts: 3,
    backoff: { type: 'exponential', delay: 5000 },
  });

  return res.status(202).json({ jobId: job.id, status: 'queued' });
});

// Poll job status
jobsRouter.get('/:jobId', requireAuth, async (req: AuthRequest, res: Response) => {
  const job = await prisma.aIGenerationJob.findFirst({
    where: { id: req.params.jobId, userId: req.userId },
  });

  if (!job) {
    return res.status(404).json({ error: 'Job not found' });
  }

  let resultPhotoURL: string | null = null;
  if (job.status === 'completed' && job.resultStoragePath) {
    resultPhotoURL = await storageService.getSignedUrl(job.resultStoragePath);
  }

  return res.json({
    id: job.id,
    userId: job.userId,
    baselinePhotoId: job.baselinePhotoId,
    status: job.status,
    resultPhotoURL,
    errorMessage: job.errorMessage,
    createdAt: job.createdAt,
    updatedAt: job.updatedAt,
  });
});
