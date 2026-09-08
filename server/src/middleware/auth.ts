import 'dotenv/config';
import { Context, Next } from 'hono';
import { jwtVerify, SignJWT } from 'jose';

export type Env = {
  Variables: {
    userId: string;
    username: string;
  };
};

const JWT_SECRET = new TextEncoder().encode(process.env.JWT_SECRET || 'gym_tracker_secret_key_2026');

export async function createToken(userId: string, username: string) {
  return await new SignJWT({ userId, username })
    .setProtectedHeader({ alg: 'HS256' })
    .setIssuedAt()
    .setExpirationTime('30d')
    .sign(JWT_SECRET);
}

export async function authMiddleware(c: Context<Env>, next: Next) {
  const authHeader = c.req.header('Authorization');
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return c.json({ error: 'Unauthorized: Missing or invalid token' }, 401);
  }

  const token = authHeader.substring(7);
  try {
    const { payload } = await jwtVerify(token, JWT_SECRET);
    c.set('userId', payload.userId as string);
    c.set('username', payload.username as string);
    await next();
  } catch (err) {
    return c.json({ error: 'Unauthorized: Token expired or invalid' }, 401);
  }
}
