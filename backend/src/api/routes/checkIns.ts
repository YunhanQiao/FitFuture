import { Router, Response } from 'express';
import multer from 'multer';
import sharp from 'sharp';
import { requireAuth, AuthRequest } from '../middleware/auth';
import { prisma } from '../../db/client';
import { storageService } from '../../services/storageService';
import { z } from 'zod';

export const checkInsRouter = Router();
const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 20 * 1024 * 1024 } });

// Create check-in
checkInsRouter.post(
  '/',
  requireAuth,
  upload.single('photo'),
  async (req: AuthRequest, res: Response) => {
    if (!req.file) {
      return res.status(400).json({ error: 'photo required' });
    }

    const BodySchema = z.object({
      userId: z.string().uuid(),
      weightKg: z.coerce.number().positive().optional(),
    });
    const parsed = BodySchema.safeParse(req.body);
    if (!parsed.success || parsed.data.userId !== req.userId) {
      return res.status(400).json({ error: 'Invalid request' });
    }

    try {
      // Calculate week number from baseline
      const baselinePhoto = await prisma.photo.findFirst({
        where: { userId: req.userId, type: 'baseline' },
        orderBy: { takenAt: 'asc' },
      });

      const weekNumber = baselinePhoto
        ? Math.floor((Date.now() - baselinePhoto.takenAt.getTime()) / (7 * 24 * 3600 * 1000)) + 1
        : 1;

      const processed = await sharp(req.file.buffer)
        .resize({ width: 1080, withoutEnlargement: true })
        .jpeg({ quality: 85 })
        .toBuffer();

      const storagePath = `${req.userId}/progress/week-${weekNumber}-${Date.now()}.jpg`;
      await storageService.upload(storagePath, processed, 'image/jpeg');

      const photo = await prisma.photo.create({
        data: { userId: req.userId!, type: 'progress', storagePath, weekNumber },
      });

      const checkIn = await prisma.checkIn.create({
        data: {
          userId: req.userId!,
          photoId: photo.id,
          weekNumber,
          weightKg: parsed.data.weightKg,
        },
      });

      return res.json(checkIn);
    } catch (err) {
      console.error('Check-in error:', err);
      return res.status(500).json({ error: 'Check-in upload failed' });
    }
  }
);

// List check-ins
checkInsRouter.get('/:userId', requireAuth, async (req: AuthRequest, res: Response) => {
  if (req.userId !== req.params.userId) {
    return res.status(403).json({ error: 'Forbidden' });
  }

  const checkIns = await prisma.checkIn.findMany({
    where: { userId: req.userId },
    orderBy: { weekNumber: 'asc' },
    include: { photo: true },
  });

  return res.json(checkIns);
});
