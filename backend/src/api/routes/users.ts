import { Router, Response } from 'express';
import multer from 'multer';
import sharp from 'sharp';
import { requireAuth, AuthRequest } from '../middleware/auth';
import { prisma } from '../../db/client';
import { storageService } from '../../services/storageService';
import { z } from 'zod';

export const usersRouter = Router();
const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 20 * 1024 * 1024 } });

// Upload baseline photo
usersRouter.post(
  '/:userId/photo/baseline',
  requireAuth,
  upload.single('photo'),
  async (req: AuthRequest, res: Response) => {
    if (req.userId !== req.params.userId) {
      return res.status(403).json({ error: 'Forbidden' });
    }
    if (!req.file) {
      return res.status(400).json({ error: 'photo file required' });
    }

    try {
      // Compress and validate dimensions
      const processed = await sharp(req.file.buffer)
        .resize({ width: 1080, withoutEnlargement: true })
        .jpeg({ quality: 85 })
        .toBuffer();

      const storagePath = `${req.userId}/baseline/${Date.now()}.jpg`;
      await storageService.upload(storagePath, processed, 'image/jpeg');

      const photo = await prisma.photo.create({
        data: {
          userId: req.userId!,
          type: 'baseline',
          storagePath,
        },
      });

      return res.json(photo);
    } catch (err) {
      console.error('Baseline photo upload error:', err);
      return res.status(500).json({ error: 'Upload failed' });
    }
  }
);

// Get latest completed AI generation job (for dashboard Future Self card)
usersRouter.get('/:userId/ai-job/latest', requireAuth, async (req: AuthRequest, res: Response) => {
  if (req.userId !== req.params.userId) {
    return res.status(403).json({ error: 'Forbidden' });
  }

  const job = await prisma.aIGenerationJob.findFirst({
    where: { userId: req.params.userId, status: 'completed', resultStoragePath: { not: null } },
    orderBy: { createdAt: 'desc' },
  });

  if (!job || !job.resultStoragePath) {
    return res.status(404).json({ error: 'No completed AI job found' });
  }

  const resultPhotoURL = await storageService.getSignedUrl(job.resultStoragePath);
  return res.json({ id: job.id, resultPhotoURL });
});

// Update user profile
usersRouter.patch('/:userId', requireAuth, async (req: AuthRequest, res: Response) => {
  if (req.userId !== req.params.userId) {
    return res.status(403).json({ error: 'Forbidden' });
  }

  const UpdateSchema = z.object({
    heightCm: z.number().positive().optional(),
    weightKg: z.number().positive().optional(),
    bodyFatPercent: z.number().min(0).max(100).optional(),
    goalType: z.enum(['fat_loss', 'muscle_gain', 'recomposition']).optional(),
    goalMonths: z.union([z.literal(3), z.literal(6), z.literal(12)]).optional(),
    trainingDaysPerWeek: z.number().int().min(1).max(7).optional(),
    checkInWeekday: z.number().int().min(0).max(6).optional(),
    apnsToken: z.string().optional(),
    displayName: z.string().max(50).optional(),
  });

  const parsed = UpdateSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: parsed.error.flatten() });
  }

  const user = await prisma.user.update({
    where: { id: req.userId },
    data: parsed.data,
  });

  return res.json(user);
});

// Delete user account and all data
usersRouter.delete('/:userId', requireAuth, async (req: AuthRequest, res: Response) => {
  if (req.userId !== req.params.userId) {
    return res.status(403).json({ error: 'Forbidden' });
  }

  try {
    // Delete all user photos from storage before cascade DB delete
    const photos = await prisma.photo.findMany({
      where: { userId: req.userId },
      select: { storagePath: true },
    });

    // Also delete AI-generated result images
    const aiJobs = await prisma.aIGenerationJob.findMany({
      where: { userId: req.userId, resultStoragePath: { not: null } },
      select: { resultStoragePath: true },
    });

    const storagePaths = [
      ...photos.map((p) => p.storagePath),
      ...aiJobs.map((j) => j.resultStoragePath!),
    ];

    // Delete storage files (non-blocking — don't fail the request if storage cleanup has issues)
    await Promise.allSettled(storagePaths.map((path) => storageService.delete(path)));

    // Cascade deletes photos/jobs/checkins from DB
    await prisma.user.delete({ where: { id: req.userId } });
    return res.json({ message: 'Account deleted' });
  } catch (err) {
    console.error('Delete account error:', err);
    return res.status(500).json({ error: 'Deletion failed' });
  }
});
