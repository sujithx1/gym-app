import 'dotenv/config';

export const env = {
  PORT: Number(process.env.PORT) || 3001,
  DATABASE_URL: process.env.DATABASE_URL || 'postgres://sujith:Sujith%40123@localhost:5432/db',
  JWT_SECRET: process.env.JWT_SECRET || 'gym_tracker_secret_key_2026',
  NODE_ENV: process.env.NODE_ENV || 'development',
} as const;
