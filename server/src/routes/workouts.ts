import { Hono } from 'hono';
import { eq, and, asc, desc, gte, count } from 'drizzle-orm';
import { db } from '../db';
import { workoutPlans, workoutDays, workoutExercises, exercises, sets, workoutSessions } from '../db/schema';
import { authMiddleware, Env } from '../middleware/auth';

const workoutRoutes = new Hono<Env>();
workoutRoutes.use('*', authMiddleware);

// GET /api/workouts/today -> Get today's scheduled workout split and target exercises
workoutRoutes.get('/today', async (c) => {
  try {
    const userId = c.get('userId');
    const dayOfWeek = new Date().getDay(); // 0 = Sun, 1 = Mon, ..., 6 = Sat

    // 1. Find active plan
    const plans = await db
      .select()
      .from(workoutPlans)
      .where(and(eq(workoutPlans.userId, userId), eq(workoutPlans.isActive, true)))
      .limit(1);

    if (plans.length === 0) {
      return c.json({
        today: null,
        message: 'No active workout plan found.',
      });
    }

    const plan = plans[0];

    // 2. Find workout day for today
    const days = await db
      .select()
      .from(workoutDays)
      .where(and(eq(workoutDays.planId, plan.id), eq(workoutDays.dayOfWeek, dayOfWeek)))
      .limit(1);

    if (days.length === 0) {
      return c.json({
        today: null,
        message: 'No workout scheduled for today.',
      });
    }

    const day = days[0];

    // 3. Find target exercises for this day
    const targetExercises = await db
      .select({
        workoutExerciseId: workoutExercises.id,
        orderIndex: workoutExercises.orderIndex,
        targetSets: workoutExercises.targetSets,
        targetReps: workoutExercises.targetReps,
        targetWeight: workoutExercises.targetWeight,
        exerciseId: exercises.id,
        exerciseName: exercises.name,
        muscleGroup: exercises.muscleGroup,
        equipment: exercises.equipment,
        instructions: exercises.instructions,
      })
      .from(workoutExercises)
      .innerJoin(exercises, eq(workoutExercises.exerciseId, exercises.id))
      .where(eq(workoutExercises.workoutDayId, day.id))
      .orderBy(asc(workoutExercises.orderIndex));

    // 4. Fetch previous session performance for each exercise
    const exercisesWithHistory = await Promise.all(
      targetExercises.map(async (ex) => {
        const lastSets = await db
          .select({
            setNumber: sets.setNumber,
            weight: sets.weight,
            reps: sets.reps,
            completed: sets.completed,
          })
          .from(sets)
          .innerJoin(workoutSessions, eq(sets.sessionId, workoutSessions.id))
          .where(
            and(
              eq(workoutSessions.userId, userId),
              eq(sets.exerciseId, ex.exerciseId),
              eq(workoutSessions.status, 'completed')
            )
          )
          .orderBy(desc(workoutSessions.completedAt), asc(sets.setNumber))
          .limit(ex.targetSets);

        return {
          id: ex.exerciseId,
          workoutExerciseId: ex.workoutExerciseId,
          name: ex.exerciseName,
          muscleGroup: ex.muscleGroup,
          equipment: ex.equipment,
          instructions: ex.instructions,
          targetSets: ex.targetSets,
          targetReps: ex.targetReps,
          targetWeight: ex.targetWeight,
          lastPerformance: lastSets.map((s) => ({
            setNumber: s.setNumber,
            weight: Number(s.weight),
            reps: Number(s.reps),
            completed: s.completed,
          })),
        };
      })
    );

    // 5. Calculate totals
    const totalSets = exercisesWithHistory.reduce((acc, curr) => acc + curr.targetSets, 0);
    const estimatedMinutes = Math.max(30, exercisesWithHistory.length * 11);

    // 6. Check active session today
    const startOfDay = new Date();
    startOfDay.setHours(0, 0, 0, 0);

    const todaySessions = await db
      .select()
      .from(workoutSessions)
      .where(and(eq(workoutSessions.userId, userId), gte(workoutSessions.startedAt, startOfDay)))
      .orderBy(desc(workoutSessions.startedAt))
      .limit(1);

    const activeSession = todaySessions.length > 0 ? todaySessions[0] : null;

    return c.json({
      today: {
        planId: plan.id,
        workoutDayId: day.id,
        name: day.name,
        dayOfWeek: day.dayOfWeek,
        exerciseCount: exercisesWithHistory.length,
        totalSets,
        estimatedMinutes,
        exercises: exercisesWithHistory,
        activeSession: activeSession
          ? {
              id: activeSession.id,
              status: activeSession.status,
              completedAt: activeSession.completedAt,
              totalVolumeKg: activeSession.totalVolumeKg,
            }
          : null,
      },
    });
  } catch (err: any) {
    console.error('❌ [Workouts] Error in GET /api/workouts/today:', err);
    return c.json({ error: err.message || 'Error loading today workout', details: String(err) }, 500);
  }
});

// GET /api/workouts/plans -> Get weekly split overview
workoutRoutes.get('/plans', async (c) => {
  try {
    const userId = c.get('userId');
    const plans = await db
      .select()
      .from(workoutPlans)
      .where(eq(workoutPlans.userId, userId))
      .orderBy(desc(workoutPlans.createdAt));

    if (plans.length === 0) {
      return c.json({ plans: [] });
    }

    const plan = plans[0];
    const daysList = await db
      .select({
        id: workoutDays.id,
        dayOfWeek: workoutDays.dayOfWeek,
        name: workoutDays.name,
        exerciseCount: count(workoutExercises.id),
      })
      .from(workoutDays)
      .leftJoin(workoutExercises, eq(workoutDays.id, workoutExercises.workoutDayId))
      .where(eq(workoutDays.planId, plan.id))
      .groupBy(workoutDays.id, workoutDays.dayOfWeek, workoutDays.name)
      .orderBy(asc(workoutDays.dayOfWeek));

    return c.json({
      plan,
      days: daysList.map((d) => ({
        id: d.id,
        dayOfWeek: d.dayOfWeek,
        name: d.name,
        exerciseCount: Number(d.exerciseCount),
      })),
    });
  } catch (err: any) {
    console.error('❌ [Workouts] Error in GET /api/workouts/plans:', err);
    return c.json({ error: err.message, details: String(err) }, 500);
  }
});

// GET /api/workouts/history -> List completed workout days with full exercises & weights lifted
workoutRoutes.get('/history', async (c) => {
  try {
    const userId = c.get('userId');
    const limit = Number(c.req.query('limit')) || 30;

    // 1. Fetch completed workout sessions
    const sessions = await db
      .select()
      .from(workoutSessions)
      .where(and(eq(workoutSessions.userId, userId), eq(workoutSessions.status, 'completed')))
      .orderBy(desc(workoutSessions.completedAt))
      .limit(limit);

    if (sessions.length === 0) {
      return c.json({ sessions: [] });
    }

    const dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    // 2. For each session, fetch completed sets with exercise metadata
    const detailedSessions = await Promise.all(
      sessions.map(async (sess) => {
        const sessionSets = await db
          .select({
            setId: sets.id,
            setNumber: sets.setNumber,
            weight: sets.weight,
            reps: sets.reps,
            completed: sets.completed,
            exerciseId: exercises.id,
            exerciseName: exercises.name,
            muscleGroup: exercises.muscleGroup,
            equipment: exercises.equipment,
          })
          .from(sets)
          .innerJoin(exercises, eq(sets.exerciseId, exercises.id))
          .where(and(eq(sets.sessionId, sess.id), eq(sets.completed, true)))
          .orderBy(asc(sets.exerciseId), asc(sets.setNumber));

        // Group sets by exercise
        const exercisesMap = new Map<
          string,
          {
            exerciseId: string;
            exerciseName: string;
            muscleGroup: string;
            equipment: string;
            maxWeight: number;
            avgWeight: number;
            totalVolume: number;
            sets: Array<{
              setNumber: number;
              weight: number;
              reps: number;
              completed: boolean;
            }>;
          }
        >();

        for (const s of sessionSets) {
          if (!exercisesMap.has(s.exerciseId)) {
            exercisesMap.set(s.exerciseId, {
              exerciseId: s.exerciseId,
              exerciseName: s.exerciseName,
              muscleGroup: s.muscleGroup,
              equipment: s.equipment,
              maxWeight: 0,
              avgWeight: 0,
              totalVolume: 0,
              sets: [],
            });
          }

          const exObj = exercisesMap.get(s.exerciseId)!;
          const weight = Number(s.weight);
          const reps = Number(s.reps);

          exObj.sets.push({
            setNumber: s.setNumber,
            weight,
            reps,
            completed: s.completed,
          });

          if (weight > exObj.maxWeight) {
            exObj.maxWeight = weight;
          }
          exObj.totalVolume += weight * reps;
        }

        const exercisesList = Array.from(exercisesMap.values()).map((ex) => ({
          ...ex,
          avgWeight:
            ex.sets.length > 0
              ? Math.round((ex.sets.reduce((sum, item) => sum + item.weight, 0) / ex.sets.length) * 10) / 10
              : 0,
        }));

        const dateObj = sess.completedAt ? new Date(sess.completedAt) : new Date(sess.startedAt);
        const formattedDate = `${dayNames[dateObj.getDay()]}, ${monthNames[dateObj.getMonth()]} ${dateObj.getDate()}`;

        return {
          id: sess.id,
          workoutDayId: sess.workoutDayId,
          name: sess.name,
          date: dateObj.toISOString(),
          formattedDate,
          status: sess.status,
          durationMinutes: Number(sess.durationMinutes || 0),
          totalVolumeKg: Number(sess.totalVolumeKg || 0),
          totalSets: sessionSets.length,
          exercisesCount: exercisesList.length,
          exercises: exercisesList,
        };
      })
    );

    return c.json({ sessions: detailedSessions });
  } catch (err: any) {
    console.error('❌ [Workouts] Error in GET /api/workouts/history:', err);
    return c.json({ error: err.message || 'Error fetching workout history', details: String(err) }, 500);
  }
});

// GET /api/workouts/days -> List all workout routine days with exercises, target weights & last lifted weights
workoutRoutes.get('/days', async (c) => {
  try {
    const userId = c.get('userId');

    // 1. Find active plan
    const plans = await db
      .select()
      .from(workoutPlans)
      .where(and(eq(workoutPlans.userId, userId), eq(workoutPlans.isActive, true)))
      .limit(1);

    if (plans.length === 0) {
      return c.json({ plan: null, days: [] });
    }

    const plan = plans[0];

    // 2. Find days for this plan
    const days = await db
      .select()
      .from(workoutDays)
      .where(eq(workoutDays.planId, plan.id))
      .orderBy(asc(workoutDays.dayOfWeek));

    const dayNames = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

    // 3. For each day, get target exercises and their last performed weights
    const detailedDays = await Promise.all(
      days.map(async (day) => {
        const targetExercises = await db
          .select({
            workoutExerciseId: workoutExercises.id,
            orderIndex: workoutExercises.orderIndex,
            targetSets: workoutExercises.targetSets,
            targetReps: workoutExercises.targetReps,
            targetWeight: workoutExercises.targetWeight,
            exerciseId: exercises.id,
            exerciseName: exercises.name,
            muscleGroup: exercises.muscleGroup,
            equipment: exercises.equipment,
            instructions: exercises.instructions,
          })
          .from(workoutExercises)
          .innerJoin(exercises, eq(workoutExercises.exerciseId, exercises.id))
          .where(eq(workoutExercises.workoutDayId, day.id))
          .orderBy(asc(workoutExercises.orderIndex));

        // Fetch last logged weights for these exercises
        const exercisesWithHistory = await Promise.all(
          targetExercises.map(async (ex) => {
            const lastSets = await db
              .select({
                setNumber: sets.setNumber,
                weight: sets.weight,
                reps: sets.reps,
                completed: sets.completed,
              })
              .from(sets)
              .innerJoin(workoutSessions, eq(sets.sessionId, workoutSessions.id))
              .where(
                and(
                  eq(workoutSessions.userId, userId),
                  eq(sets.exerciseId, ex.exerciseId),
                  eq(workoutSessions.status, 'completed')
                )
              )
              .orderBy(desc(workoutSessions.completedAt), asc(sets.setNumber))
              .limit(ex.targetSets);

            const lastWeights = lastSets.map((s) => Number(s.weight));
            const maxLastWeight = lastWeights.length > 0 ? Math.max(...lastWeights) : null;

            return {
              id: ex.exerciseId,
              workoutExerciseId: ex.workoutExerciseId,
              name: ex.exerciseName,
              muscleGroup: ex.muscleGroup,
              equipment: ex.equipment,
              instructions: ex.instructions,
              targetSets: ex.targetSets,
              targetReps: ex.targetReps,
              targetWeight: ex.targetWeight,
              maxLastWeight,
              lastPerformance: lastSets.map((s) => ({
                setNumber: s.setNumber,
                weight: Number(s.weight),
                reps: Number(s.reps),
                completed: s.completed,
              })),
            };
          })
        );

        return {
          id: day.id,
          dayOfWeek: day.dayOfWeek,
          dayName: dayNames[day.dayOfWeek] || `Day ${day.dayOfWeek}`,
          name: day.name,
          exerciseCount: exercisesWithHistory.length,
          exercises: exercisesWithHistory,
        };
      })
    );

    return c.json({
      plan: {
        id: plan.id,
        name: plan.name,
      },
      days: detailedDays,
    });
  } catch (err: any) {
    console.error('❌ [Workouts] Error in GET /api/workouts/days:', err);
    return c.json({ error: err.message || 'Error fetching workout days', details: String(err) }, 500);
  }
});

export default workoutRoutes;
