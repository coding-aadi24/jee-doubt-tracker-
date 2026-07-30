import express from 'express';
import cors from 'cors';
import fs from 'fs';
import { config } from './config/index';
import { apiRouter } from './routes/index';

const app = express();

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Ensure upload & storage directories exist
if (!fs.existsSync(config.storagePath)) {
  fs.mkdirSync(config.storagePath, { recursive: true });
}

// Serve uploaded PDFs statically
app.use('/files', express.static(config.storagePath));

// Mount API routes
app.use('/api/v1', apiRouter);

// Root route
app.get('/', (req, res) => {
  res.json({
    name: 'JEE Doubt Tracker Backend API',
    version: '1.0.0',
    documentation: '/api/v1/health',
  });
});

app.listen(config.port, () => {
  console.log(`🚀 JEE Doubt Tracker Backend running on port ${config.port} (${config.nodeEnv})`);
  console.log(`📁 File Storage Location: ${config.storagePath}`);
});
