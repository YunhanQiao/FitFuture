import { Request, Response, NextFunction } from 'express';
import { jwtVerify } from 'jose';
import { prisma } from '../../db/client';

export interface AuthRequest extends Request {
  userId?: string;
}

export async function requireAuth(req: AuthRequest, res: Response, next: NextFunction) {
  const header = req.headers.authorization;
  if (!header?.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Missing or invalid authorization header' });
  }

  const token = header.slice(7);
  try {
    const secret = new TextEncoder().encode(process.env.JWT_SECRET!);
    const { payload } = await jwtVerify(token, secret);
    req.userId = payload.sub as string;
    next();
  } catch {
    return res.status(401).json({ error: 'Invalid or expired token' });
  }
}
