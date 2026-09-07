import { Hono } from 'hono';
import bcrypt from 'bcryptjs';
import { eq } from 'drizzle-orm';
import { db } from '../db';
import { users } from '../db/schema';
import { createToken, authMiddleware, Env } from '../middleware/auth';

const authRoutes = new Hono<Env>();

authRoutes.post('/login', async (c) => {
  try {
    const { username, password } = await c.req.json();
    if (!username || !password) {
      return c.json({ error: 'Username and password are required' }, 400);
    }

    const userList = await db
      .select()
      .from(users)
      .where(eq(users.username, String(username)))
      .limit(1);

    if (userList.length === 0) {
      return c.json({ error: 'Invalid username or password' }, 401);
    }

    const user = userList[0];
    const isMatch = await bcrypt.compare(String(password), user.passwordHash);
    if (!isMatch) {
      return c.json({ error: 'Invalid username or password' }, 401);
    }

    const token = await createToken(user.id, user.username);
    return c.json({
      token,
      user: {
        id: user.id,
        username: user.username,
        createdAt: user.createdAt,
      },
    });
  } catch (err: any) {
    return c.json({ error: err.message || 'Server error' }, 500);
  }
});

authRoutes.get('/me', authMiddleware, async (c) => {
  const userId = c.get('userId');
  const userList = await db
    .select({
      id: users.id,
      username: users.username,
      createdAt: users.createdAt,
    })
    .from(users)
    .where(eq(users.id, userId))
    .limit(1);

  if (userList.length === 0) {
    return c.json({ error: 'User not found' }, 404);
  }

  return c.json({ user: userList[0] });
});

authRoutes.post('/logout', async (c) => {
  return c.json({ message: 'Logged out successfully' });
});

export default authRoutes;
