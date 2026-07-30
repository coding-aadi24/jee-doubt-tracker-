import dotenv from 'dotenv';
import path from 'path';

dotenv.config();

export const config = {
  port: parseInt(process.env.PORT || '5000', 10),
  nodeEnv: process.env.NODE_ENV || 'development',
  databaseUrl: process.env.DATABASE_URL || 'postgresql://admin:admin@localhost:5432/jee?schema=public',
  storagePath: path.resolve(process.env.STORAGE_PATH || './uploads'),
  maxFileSizeMB: parseInt(process.env.MAX_FILE_SIZE_MB || '50', 10),
  jwtSecret: process.env.JWT_SECRET || 'default_secret',
  googleDriveFolderId: process.env.GOOGLE_DRIVE_FOLDER_ID || '',
  googleDriveWebAppUrl: process.env.GOOGLE_DRIVE_WEBAPP_URL || '',
  googleServiceAccountEmail: process.env.GOOGLE_SERVICE_ACCOUNT_EMAIL || '',
  googlePrivateKey: (process.env.GOOGLE_PRIVATE_KEY || '').replace(/\\n/g, '\n'),
};
