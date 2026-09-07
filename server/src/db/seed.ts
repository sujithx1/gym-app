import { initDb, queryClient } from './index';
import bcrypt from 'bcryptjs';

async function seed() {
  console.log('Seeding database...');
  await initDb();

  // 1. Seed User
  const passwordHash = await bcrypt.hash('password123', 10);
  const userId = 'user_sujith_01';

  await queryClient`
    INSERT INTO users (id, username, password_hash)
    VALUES (${userId}, 'sujith', ${passwordHash})
    ON CONFLICT (username) DO UPDATE SET password_hash = ${passwordHash};
  `;

  // 2. Seed Exercises
  const exercisesData = [
    { id: 'ex_bench_press', name: 'Bench Press', muscleGroup: 'Chest', equipment: 'Barbell', instructions: 'Lie on flat bench, lower bar to mid-chest, press up explosively.' },
    { id: 'ex_incline_db_press', name: 'Incline Dumbbell Press', muscleGroup: 'Chest', equipment: 'Dumbbell', instructions: 'Set bench to 30 degrees, press dumbbells upward over chest.' },
    { id: 'ex_chest_fly', name: 'Cable Chest Fly', muscleGroup: 'Chest', equipment: 'Cable', instructions: 'Bring cables together in a wide arc, squeezing inner chest.' },
    { id: 'ex_tricep_pushdown', name: 'Tricep Rope Pushdown', muscleGroup: 'Triceps', equipment: 'Cable', instructions: 'Push cable downward fully extending elbows, spread rope at bottom.' },
    { id: 'ex_skullcrusher', name: 'EZ-Bar Skullcrusher', muscleGroup: 'Triceps', equipment: 'Barbell', instructions: 'Lower EZ bar to forehead keeping upper arms still, press up.' },
    
    { id: 'ex_lat_pulldown', name: 'Lat Pulldown', muscleGroup: 'Back', equipment: 'Machine', instructions: 'Pull bar down to upper chest, squeeze shoulder blades together.' },
    { id: 'ex_barbell_row', name: 'Bent-Over Barbell Row', muscleGroup: 'Back', equipment: 'Barbell', instructions: 'Hinge at hips, row bar into lower ribs.' },
    { id: 'ex_bicep_curl', name: 'Barbell Bicep Curl', muscleGroup: 'Biceps', equipment: 'Barbell', instructions: 'Keep elbows tucked, curl bar up toward shoulders.' },
    { id: 'ex_hammer_curl', name: 'Dumbbell Hammer Curl', muscleGroup: 'Biceps', equipment: 'Dumbbell', instructions: 'Neutral grip curl focusing on brachialis.' },

    { id: 'ex_squat', name: 'Barbell Back Squat', muscleGroup: 'Legs', equipment: 'Barbell', instructions: 'Keep chest high, squat down until thighs are parallel to ground.' },
    { id: 'ex_leg_press', name: 'Leg Press', muscleGroup: 'Legs', equipment: 'Machine', instructions: 'Press platform away using heels, avoid locking knees.' },
    { id: 'ex_calf_raise', name: 'Standing Calf Raise', muscleGroup: 'Legs', equipment: 'Machine', instructions: 'Raise heels up as high as possible, lower slowly.' },

    { id: 'ex_deadlift', name: 'Conventional Deadlift', muscleGroup: 'Back', equipment: 'Barbell', instructions: 'Drive through floor, pull bar up along shins, lock out hips.' },
    { id: 'ex_overhead_press', name: 'Overhead Shoulder Press', muscleGroup: 'Shoulders', equipment: 'Barbell', instructions: 'Press barbell overhead from collarbone to full lockout.' },
    { id: 'ex_lateral_raise', name: 'Dumbbell Lateral Raise', muscleGroup: 'Shoulders', equipment: 'Dumbbell', instructions: 'Raise arms out to side to shoulder height.' },
    { id: 'ex_hanging_leg_raise', name: 'Hanging Leg Raise', muscleGroup: 'Abs', equipment: 'Bodyweight', instructions: 'Hang from pullup bar, raise legs to 90 degrees.' },
  ];

  for (const ex of exercisesData) {
    await queryClient`
      INSERT INTO exercises (id, name, muscle_group, equipment, instructions, is_custom)
      VALUES (${ex.id}, ${ex.name}, ${ex.muscleGroup}, ${ex.equipment}, ${ex.instructions}, false)
      ON CONFLICT (id) DO UPDATE SET
        name = ${ex.name},
        muscle_group = ${ex.muscleGroup},
        equipment = ${ex.equipment},
        instructions = ${ex.instructions};
    `;
  }

  // 3. Seed Workout Plan
  const planId = 'plan_push_pull_legs';
  await queryClient`
    INSERT INTO workout_plans (id, user_id, name, is_active)
    VALUES (${planId}, ${userId}, '4-Day Hypertrophy Split', true)
    ON CONFLICT (id) DO NOTHING;
  `;

  // 4. Seed Workout Days (0 = Sun, 1 = Mon, 2 = Tue, 3 = Wed, 4 = Thu, 5 = Fri, 6 = Sat)
  const workoutDaysData = [
    { id: 'day_mon', dayOfWeek: 1, name: 'Chest + Triceps' },
    { id: 'day_tue', dayOfWeek: 2, name: 'Back + Biceps' },
    { id: 'day_wed', dayOfWeek: 3, name: 'Rest & Recovery' },
    { id: 'day_thu', dayOfWeek: 4, name: 'Shoulders + Abs' },
    { id: 'day_fri', dayOfWeek: 5, name: 'Legs Day' },
    { id: 'day_sat', dayOfWeek: 6, name: 'Arms & Cardio' },
    { id: 'day_sun', dayOfWeek: 0, name: 'Rest & Recovery' },
  ];

  for (const day of workoutDaysData) {
    await queryClient`
      INSERT INTO workout_days (id, plan_id, day_of_week, name)
      VALUES (${day.id}, ${planId}, ${day.dayOfWeek}, ${day.name})
      ON CONFLICT (id) DO UPDATE SET name = ${day.name};
    `;
  }

  // 5. Seed Target Exercises for Days
  const targetExercises = [
    // Mon: Chest + Triceps
    { id: 'we_mon_1', workoutDayId: 'day_mon', exerciseId: 'ex_bench_press', orderIndex: 1, targetSets: 3, targetReps: 10, targetWeight: 60 },
    { id: 'we_mon_2', workoutDayId: 'day_mon', exerciseId: 'ex_incline_db_press', orderIndex: 2, targetSets: 3, targetReps: 10, targetWeight: 24 },
    { id: 'we_mon_3', workoutDayId: 'day_mon', exerciseId: 'ex_chest_fly', orderIndex: 3, targetSets: 3, targetReps: 12, targetWeight: 18 },
    { id: 'we_mon_4', workoutDayId: 'day_mon', exerciseId: 'ex_tricep_pushdown', orderIndex: 4, targetSets: 3, targetReps: 12, targetWeight: 27 },
    { id: 'we_mon_5', workoutDayId: 'day_mon', exerciseId: 'ex_skullcrusher', orderIndex: 5, targetSets: 3, targetReps: 10, targetWeight: 30 },

    // Tue: Back + Biceps
    { id: 'we_tue_1', workoutDayId: 'day_tue', exerciseId: 'ex_lat_pulldown', orderIndex: 1, targetSets: 4, targetReps: 10, targetWeight: 55 },
    { id: 'we_tue_2', workoutDayId: 'day_tue', exerciseId: 'ex_barbell_row', orderIndex: 2, targetSets: 3, targetReps: 8, targetWeight: 60 },
    { id: 'we_tue_3', workoutDayId: 'day_tue', exerciseId: 'ex_bicep_curl', orderIndex: 3, targetSets: 3, targetReps: 10, targetWeight: 25 },
    { id: 'we_tue_4', workoutDayId: 'day_tue', exerciseId: 'ex_hammer_curl', orderIndex: 4, targetSets: 3, targetReps: 12, targetWeight: 14 },

    // Thu: Shoulders + Abs
    { id: 'we_thu_1', workoutDayId: 'day_thu', exerciseId: 'ex_overhead_press', orderIndex: 1, targetSets: 4, targetReps: 8, targetWeight: 45 },
    { id: 'we_thu_2', workoutDayId: 'day_thu', exerciseId: 'ex_lateral_raise', orderIndex: 2, targetSets: 4, targetReps: 12, targetWeight: 12 },
    { id: 'we_thu_3', workoutDayId: 'day_thu', exerciseId: 'ex_hanging_leg_raise', orderIndex: 3, targetSets: 3, targetReps: 15, targetWeight: 0 },

    // Fri: Legs
    { id: 'we_fri_1', workoutDayId: 'day_fri', exerciseId: 'ex_squat', orderIndex: 1, targetSets: 4, targetReps: 8, targetWeight: 90 },
    { id: 'we_fri_2', workoutDayId: 'day_fri', exerciseId: 'ex_leg_press', orderIndex: 2, targetSets: 3, targetReps: 10, targetWeight: 160 },
    { id: 'we_fri_3', workoutDayId: 'day_fri', exerciseId: 'ex_calf_raise', orderIndex: 3, targetSets: 4, targetReps: 15, targetWeight: 50 },
  ];

  for (const te of targetExercises) {
    await queryClient`
      INSERT INTO workout_exercises (id, workout_day_id, exercise_id, order_index, target_sets, target_reps, target_weight)
      VALUES (${te.id}, ${te.workoutDayId}, ${te.exerciseId}, ${te.orderIndex}, ${te.targetSets}, ${te.targetReps}, ${te.targetWeight})
      ON CONFLICT (id) DO NOTHING;
    `;
  }

  // 6. Seed Past Workout Sessions & Progress data
  const pastSessions = [
    {
      id: 'sess_prev_chest',
      workoutDayId: 'day_mon',
      name: 'Chest + Triceps',
      daysAgo: 4,
      duration: 54,
      volume: 4500,
      sets: [
        { exId: 'ex_bench_press', sets: [{ w: 60, r: 10 }, { w: 60, r: 10 }, { w: 65, r: 7 }] },
        { exId: 'ex_incline_db_press', sets: [{ w: 22, r: 10 }, { w: 22, r: 10 }, { w: 24, r: 8 }] },
        { exId: 'ex_chest_fly', sets: [{ w: 18, r: 12 }, { w: 18, r: 12 }, { w: 18, r: 10 }] },
        { exId: 'ex_tricep_pushdown', sets: [{ w: 25, r: 12 }, { w: 25, r: 12 }, { w: 27, r: 10 }] },
        { exId: 'ex_skullcrusher', sets: [{ w: 28, r: 10 }, { w: 28, r: 10 }, { w: 30, r: 8 }] }
      ]
    },
    {
      id: 'sess_prev_back',
      workoutDayId: 'day_tue',
      name: 'Back + Biceps',
      daysAgo: 3,
      duration: 48,
      volume: 4200,
      sets: [
        { exId: 'ex_lat_pulldown', sets: [{ w: 50, r: 10 }, { w: 55, r: 10 }, { w: 55, r: 8 }] },
        { exId: 'ex_barbell_row', sets: [{ w: 55, r: 10 }, { w: 60, r: 8 }, { w: 60, r: 8 }] },
        { exId: 'ex_bicep_curl', sets: [{ w: 22, r: 10 }, { w: 25, r: 8 }, { w: 25, r: 8 }] }
      ]
    },
    {
      id: 'sess_prev_legs',
      workoutDayId: 'day_fri',
      name: 'Legs Day',
      daysAgo: 2,
      duration: 58,
      volume: 5100,
      sets: [
        { exId: 'ex_squat', sets: [{ w: 80, r: 10 }, { w: 85, r: 8 }, { w: 90, r: 6 }] },
        { exId: 'ex_leg_press', sets: [{ w: 140, r: 10 }, { w: 150, r: 10 }, { w: 160, r: 8 }] }
      ]
    }
  ];

  for (const sess of pastSessions) {
    const sessionDate = new Date();
    sessionDate.setDate(sessionDate.getDate() - sess.daysAgo);

    const dateStr = sessionDate.toISOString();
    await queryClient`
      INSERT INTO workout_sessions (id, user_id, workout_day_id, name, started_at, completed_at, status, total_volume_kg, duration_minutes)
      VALUES (${sess.id}, ${userId}, ${sess.workoutDayId}, ${sess.name}, ${dateStr}, ${dateStr}, 'completed', ${sess.volume}, ${sess.duration})
      ON CONFLICT (id) DO NOTHING;
    `;

    let setCounter = 1;
    for (const group of sess.sets) {
      for (let i = 0; i < group.sets.length; i++) {
        const s = group.sets[i];
        const setId = `set_${sess.id}_${group.exId}_${i + 1}`;
        await queryClient`
          INSERT INTO sets (id, session_id, exercise_id, set_number, weight, reps, completed, completed_at)
          VALUES (${setId}, ${sess.id}, ${group.exId}, ${i + 1}, ${s.w}, ${s.r}, true, ${dateStr})
          ON CONFLICT (id) DO NOTHING;
        `;
        setCounter++;
      }
    }
  }

  console.log('Seeding completed successfully!');
}

seed().catch(err => {
  console.error('Seed failed:', err);
  process.exit(1);
});
