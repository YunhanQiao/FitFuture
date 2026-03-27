import { Router, Request, Response } from 'express';
import { createRemoteJWKSet, jwtVerify, SignJWT } from 'jose';
import { prisma } from '../../db/client';
import { z } from 'zod';

export const authRouter = Router();

const AppleSignInSchema = z.object({ identityToken: z.string().min(1) });

const APPLE_JWKS = createRemoteJWKSet(
  new URL('https://appleid.apple.com/auth/keys')
);

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

    return res.json({ token, user });
  } catch (err) {
    console.error('Apple sign-in error:', err);
    return res.status(401).json({ error: 'Invalid Apple identity token' });
  }
});
