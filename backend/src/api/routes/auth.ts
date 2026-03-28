import { Router, Request, Response } from 'express';
import { createRemoteJWKSet, jwtVerify, SignJWT } from 'jose';
import { prisma } from '../../db/client';
import { z } from 'zod';
import bcrypt from 'bcryptjs';

export const authRouter = Router();

const AppleSignInSchema = z.object({ identityToken: z.string().min(1) });

const APPLE_JWKS = createRemoteJWKSet(
  new URL('https://appleid.apple.com/auth/keys')
);

const RegisterSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
  displayName: z.string().min(1, 'Name is required'),
});

const LoginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(1),
});

function stripPassword<T extends { passwordHash?: string | null }>(user: T): Omit<T, 'passwordHash'> {
  const { passwordHash: _, ...safe } = user;
  return safe;
}

async function issueJWT(userId: string): Promise<string> {
  const secret = new TextEncoder().encode(process.env.JWT_SECRET!);
  return new SignJWT({ sub: userId })
    .setProtectedHeader({ alg: 'HS256' })
    .setIssuedAt()
    .setExpirationTime('90d')
    .sign(secret);
}

authRouter.post('/register', async (req: Request, res: Response) => {
  const parsed = RegisterSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: parsed.error.errors[0].message });
  }
  const { email, password, displayName } = parsed.data;
  try {
    const existing = await prisma.user.findUnique({ where: { email } });
    if (existing) return res.status(409).json({ error: 'Email already in use' });

    const passwordHash = await bcrypt.hash(password, 10);
    const user = await prisma.user.create({
      data: { email, passwordHash, displayName: displayName! },
    });
    const token = await issueJWT(user.id);
    return res.status(201).json({ token, user: stripPassword(user) });
  } catch (err: any) {
    console.error('Register error:', err?.message);
    return res.status(500).json({ error: 'Registration failed' });
  }
});

authRouter.post('/login', async (req: Request, res: Response) => {
  const parsed = LoginSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: parsed.error.errors[0].message });
  }
  const { email, password } = parsed.data;
  try {
    const user = await prisma.user.findUnique({ where: { email } });
    if (!user || !user.passwordHash) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }
    const valid = await bcrypt.compare(password, user.passwordHash);
    if (!valid) return res.status(401).json({ error: 'Invalid email or password' });

    const token = await issueJWT(user.id);
    return res.json({ token, user: stripPassword(user) });
  } catch (err: any) {
    console.error('Login error:', err?.message);
    return res.status(500).json({ error: 'Login failed' });
  }
});

// DEV ONLY — bypasses Apple verification for simulator testing
if (process.env.NODE_ENV !== 'production') {
  authRouter.post('/dev', async (_req: Request, res: Response) => {
    try {
      const user = await prisma.user.upsert({
        where: { appleUserId: 'dev-user-simulator' },
        create: { appleUserId: 'dev-user-simulator', email: 'dev@fitfuture.app' },
        update: {},
      });
      const secret = new TextEncoder().encode(process.env.JWT_SECRET!);
      const token = await new SignJWT({ sub: user.id })
        .setProtectedHeader({ alg: 'HS256' })
        .setIssuedAt()
        .setExpirationTime('90d')
        .sign(secret);
      return res.json({ token, user: stripPassword(user) });
    } catch (err: any) {
      return res.status(500).json({ error: err?.message });
    }
  });
}

authRouter.post('/apple', async (req: Request, res: Response) => {
  const parsed = AppleSignInSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: 'identityToken required' });
  }

  try {
    const { payload } = await jwtVerify(parsed.data.identityToken, APPLE_JWKS, {
      issuer: 'https://appleid.apple.com',
      audience: process.env.APPLE_CLIENT_ID,
    });

    const appleUserId = payload.sub as string;
    const email = payload.email as string | undefined;

    // Upsert user
    const user = await prisma.user.upsert({
      where: { appleUserId },
      create: { appleUserId, email },
      update: { email: email ?? undefined },
    });

    // Issue JWT
    const secret = new TextEncoder().encode(process.env.JWT_SECRET!);
    const token = await new SignJWT({ sub: user.id })
      .setProtectedHeader({ alg: 'HS256' })
      .setIssuedAt()
      .setExpirationTime('90d')
      .sign(secret);

    return res.json({ token, user: stripPassword(user) });
  } catch (err: any) {
    console.error('Apple sign-in error:', err?.message ?? err);
    return res.status(401).json({ error: err?.message ?? 'Invalid Apple identity token' });
  }
});
