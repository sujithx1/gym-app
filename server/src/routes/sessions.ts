import { Hono } from 'hono';
import { eq, and, desc, asc, ne, count } from 'drizzle-orm';
import { db } from '../db';
import { workoutSessions, sets } from '../db/schema';
import { authMiddleware, Env } from '../middleware/auth';

const sessionRoutes = new Hono<Env>();
sessionRoutes.use('*', authMiddleware);

// POST /api/sessions/start -> Start a workout session
sessionRoutes.post('/start', async (c) => {
  try {
    const userId = c.get('userId');
    const { workoutDayId, name } = await c.req.json();

    const sessionId = `sess_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`;

    await (db.insert(workoutSessions) as any).values({
      id: sessionId,
      userId,
      workoutDayId: workoutDayId || null,
      name: name || "Today's Workout",
      startedAt: new Date(),
      status: 'in_progress',
    });

    return c.json({
      sessionId,
      status: 'in_progress',
      startedAt: new Date(),
    });
  } catch (err: any) {
    return c.json({ error: err.message || 'Failed to start session' }, 500);
  }
});

// GET /api/sessions/:id -> Get session with logged sets
sessionRoutes.get('/:id', async (c) => {
  try {
    const userId = c.get('userId');
    const sessionId = c.req.param('id');

    const sessionsList = await db
      .select()
      .from(workoutSessions)
      .where(and(eq(workoutSessions.id, sessionId), eq(workoutSessions.userId, userId)))
      .limit(1);

    if (sessionsList.length === 0) {
      return c.json({ error: 'Session not found' }, 404);
    }

    const session = sessionsList[0];
    const loggedSets = await db
      .select()
      .from(sets)
      .where(eq(sets.sessionId, sessionId))
      .orderBy(asc(sets.setNumber));

    return c.json({
      session,
      sets: loggedSets.map((s) => ({
        id: s.id,
        exerciseId: s.exerciseId,
        setNumber: s.setNumber,
        weight: Number(s.weight),
        reps: Number(s.reps),
        completed: s.completed,
      })),
    });
  } catch (err: any) {
    return c.json({ error: err.message }, 500);
  }
});

// PUT /api/sessions/:id/set -> Log/update a set using Drizzle upsert
sessionRoutes.put('/:id/set', async (c) => {
  try {
    const sessionId = c.req.param('id');
    const { exerciseId, setNumber, weight, reps, completed } = await c.req.json();

    if (!exerciseId || setNumber === undefined || weight === undefined || reps === undefined) {
      return c.json({ error: 'Missing set information' }, 400);
    }

    const setId = `set_${sessionId}_${exerciseId}_${setNumber}`;

    await (db.insert(sets) as any)
      .values({
        id: setId,
        sessionId,
        exerciseId,
        setNumber: Number(setNumber),
        weight: Number(weight),
        reps: Number(reps),
        completed: completed ?? true,
        completedAt: new Date(),
      })
      .onConflictDoUpdate({
        target: sets.id,
        set: {
          weight: Number(weight),
          reps: Number(reps),
          completed: completed ?? true,
          completedAt: new Date(),
        },
      });

    return c.json({
      setId,
      exerciseId,
      setNumber,
      weight,
      reps,
      completed: completed ?? true,
    });
  } catch (err: any) {
    return c.json({ error: err.message }, 500);
  }
});

// POST /api/sessions/:id/complete -> Complete workout session & calculate volume deltas
sessionRoutes.post('/:id/complete', async (c) => {
  try {
    const userId = c.get('userId');
    const sessionId = c.req.param('id');
    const { notes } = await c.req.json().catch(() => ({ notes: '' }));

    const sessionsList = await db
      .select()
      .from(workoutSessions)
      .where(and(eq(workoutSessions.id, sessionId), eq(workoutSessions.userId, userId)))
      .limit(1);

    if (sessionsList.length === 0) {
      return c.json({ error: 'Session not found' }, 404);
    }

    const session = sessionsList[0];

    // 1. Fetch completed sets for this session
    const completedSets = await db
      .select()
      .from(sets)
      .where(and(eq(sets.sessionId, sessionId), eq(sets.completed, true)));

    // 2. Calculate Total Volume = sum(weight * reps)
    let totalVolumeKg = 0;
    for (const s of completedSets) {
      totalVolumeKg += Number(s.weight) * Number(s.reps);
    }

    const now = new Date();
    const durationMinutes = Math.max(1, Math.round((now.getTime() - new Date(session.startedAt).getTime()) / (1000 * 60)));

    // 3. Mark session completed
    await (db.update(workoutSessions) as any)
      .set({
        completedAt: now,
        status: 'completed',
        totalVolumeKg,
        durationMinutes,
        notes: notes || null,
      })
      .where(eq(workoutSessions.id, sessionId));

    // 4. Fetch previous session volume for comparison
    const previousSessions = await db
      .select({ totalVolumeKg: workoutSessions.totalVolumeKg })
      .from(workoutSessions)
      .where(
        and(
          eq(workoutSessions.userId, userId),
          eq(workoutSessions.status, 'completed'),
          ne(workoutSessions.id, sessionId)
        )
      )
      .orderBy(desc(workoutSessions.completedAt))
      .limit(1);

    const previousVolume = previousSessions.length > 0 ? Number(previousSessions[0].totalVolumeKg) : 0;
    const volumeDeltaKg = totalVolumeKg - previousVolume;

    return c.json({
      success: true,
      summary: {
        sessionId,
        name: session.name,
        totalVolumeKg,
        durationMinutes,
        totalSetsCompleted: completedSets.length,
        previousVolumeKg: previousVolume,
        volumeDeltaKg,
        percentageDelta: previousVolume > 0 ? Math.round(((totalVolumeKg - previousVolume) / previousVolume) * 100) : 0,
        message: volumeDeltaKg >= 0 
          ? `Great session! You lifted ${Math.abs(Math.round(volumeDeltaKg))} kg more than last workout!`
          : `Solid effort! Consistency is key to long term growth.`,
      },
    });
  } catch (err: any) {
    return c.json({ error: err.message || 'Error completing session' }, 500);
  }
});

// GET /api/sessions/history -> Get past sessions history list
sessionRoutes.get('/history/all', async (c) => {
  try {
    const userId = c.get('userId');

    const history = await db
      .select({
        id: workoutSessions.id,
        name: workoutSessions.name,
        startedAt: workoutSessions.startedAt,
        completedAt: workoutSessions.completedAt,
        status: workoutSessions.status,
        totalVolumeKg: workoutSessions.totalVolumeKg,
        durationMinutes: workoutSessions.durationMinutes,
        totalSets: count(sets.id),
      })
      .from(workoutSessions)
      .leftJoin(sets, and(eq(workoutSessions.id, sets.sessionId), eq(sets.completed, true)))
      .where(and(eq(workoutSessions.userId, userId), eq(workoutSessions.status, 'completed')))
      .groupBy(
        workoutSessions.id,
        workoutSessions.name,
        workoutSessions.startedAt,
        workoutSessions.completedAt,
        workoutSessions.status,
        workoutSessions.totalVolumeKg,
        workoutSessions.durationMinutes
      )
      .orderBy(desc(workoutSessions.completedAt))
      .limit(30);

    return c.json({
      history: history.map((h) => ({
        id: h.id,
        name: h.name,
        startedAt: h.startedAt,
        completedAt: h.completedAt,
        totalVolumeKg: Number(h.totalVolumeKg),
        durationMinutes: Number(h.durationMinutes),
        totalSets: Number(h.totalSets),
      })),
    });
  } catch (err: any) {
    return c.json({ error: err.message }, 500);
  }
});

export default sessionRoutes;
