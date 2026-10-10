import { Hono } from 'hono';
import { eq, or, and, max, desc, asc } from 'drizzle-orm';
import { db } from '../db';
import { exercises, sets, workoutSessions, users } from '../db/schema';
import { authMiddleware, Env } from '../middleware/auth';

const exerciseRoutes = new Hono<Env>();
exerciseRoutes.use('*', authMiddleware);

// GET /api/exercises -> Get exercise library
exerciseRoutes.get('/', async (c) => {
  try {
    const userId = c.get('userId');
    const muscleGroup = c.req.query('muscleGroup');

    const userCondition = or(
      eq(exercises.isCustom, false),
      eq(exercises.userId, userId)
    );

    const condition = muscleGroup
      ? and(userCondition, eq(exercises.muscleGroup, muscleGroup))
      : userCondition;

    const exercisesList = await db
      .select()
      .from(exercises)
      .where(condition)
      .orderBy(asc(exercises.muscleGroup), asc(exercises.name));

    return c.json({ exercises: exercisesList });
  } catch (err: any) {
    console.error('❌ [Exercises] Error in GET /api/exercises:', err);
    return c.json({ error: err.message, details: String(err) }, 500);
  }
});

// POST /api/exercises -> Create custom exercise
exerciseRoutes.post('/', async (c) => {
  try {
    const userId = c.get('userId');
    const { id: providedId, name, muscleGroup, equipment, instructions } = await c.req.json();

    console.log(`[Exercises] Creating custom exercise: "${name}" (${muscleGroup}) for user=${userId}`);
    if (!name || !muscleGroup) {
      return c.json({ error: 'Name and Muscle Group are required' }, 400);
    }

    // Ensure user exists in users table so foreign key constraint is satisfied
    if (userId) {
      await (db.insert(users) as any).values({
        id: userId,
        username: c.get('username') || userId,
        passwordHash: 'placeholder',
      }).onConflictDoNothing();
    }

    const id = providedId || `ex_custom_${Date.now()}`;

    await (db.insert(exercises) as any).values({
      id,
      name: String(name),
      muscleGroup: String(muscleGroup),
      equipment: String(equipment || 'Barbell'),
      instructions: String(instructions || ''),
      isCustom: true,
      userId,
    }).onConflictDoUpdate({
      target: exercises.id,
      set: {
        name: String(name),
        muscleGroup: String(muscleGroup),
        equipment: String(equipment || 'Barbell'),
        instructions: String(instructions || ''),
      },
    });

    console.log(`✅ [Exercises] Custom exercise created successfully: ${id} (${name})`);

    return c.json({
      id,
      name,
      muscleGroup,
      equipment: equipment || 'Barbell',
      instructions: instructions || '',
      isCustom: true,
    });
  } catch (err: any) {
    console.error('❌ [Exercises] Error creating custom exercise in POST /api/exercises:', err);
    return c.json({ error: err.message || 'Failed to create exercise', details: String(err) }, 500);
  }
});

// GET /api/exercises/:id/stats -> Get PRs and history for exercise
exerciseRoutes.get('/:id/stats', async (c) => {
  try {
    const userId = c.get('userId');
    const exerciseId = c.req.param('id');

    // 1. Fetch exercise details
    const exercisesList = await db
      .select()
      .from(exercises)
      .where(eq(exercises.id, exerciseId))
      .limit(1);

    if (exercisesList.length === 0) {
      return c.json({ error: 'Exercise not found' }, 404);
    }

    const exercise = exercisesList[0];

    // 2. Personal Bests
    const maxWeightRes = await db
      .select({
        maxWeight: max(sets.weight),
        reps: sets.reps,
        completedAt: sets.completedAt,
      })
      .from(sets)
      .innerJoin(workoutSessions, eq(sets.sessionId, workoutSessions.id))
      .where(
        and(
          eq(workoutSessions.userId, userId),
          eq(sets.exerciseId, exerciseId),
          eq(sets.completed, true)
        )
      )
      .groupBy(sets.reps, sets.completedAt)
      .orderBy(desc(max(sets.weight)))
      .limit(1);

    const prWeight = maxWeightRes.length > 0 ? Number(maxWeightRes[0].maxWeight) : 0;
    const prReps = maxWeightRes.length > 0 ? Number(maxWeightRes[0].reps) : 0;

    // 3. Progression history points
    const historyPoints = await db
      .select({
        weight: sets.weight,
        reps: sets.reps,
        date: workoutSessions.completedAt,
      })
      .from(sets)
      .innerJoin(workoutSessions, eq(sets.sessionId, workoutSessions.id))
      .where(
        and(
          eq(workoutSessions.userId, userId),
          eq(sets.exerciseId, exerciseId),
          eq(sets.completed, true)
        )
      )
      .orderBy(asc(workoutSessions.completedAt));

    return c.json({
      exercise,
      personalRecord: {
        weight: prWeight,
        reps: prReps,
      },
      history: historyPoints.map((h) => ({
        weight: Number(h.weight),
        reps: Number(h.reps),
        date: h.date,
      })),
    });
  } catch (err: any) {
    console.error(`❌ [Exercises] Error in GET /api/exercises/${c.req.param('id')}/stats:`, err);
    return c.json({ error: err.message, details: String(err) }, 500);
  }
});

export default exerciseRoutes;
