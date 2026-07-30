# JEE Doubt Tracker - Standalone Backend API

Standalone Node.js + Express + TypeScript backend server for the **JEE Doubt Tracker** collaborative PDF question organizer app.

## Project Structure

```
d:\rrr\
├── backend\                     # Dedicated Backend Server Project
│   ├── src\
│   │   ├── config\             # Environment & App Config
│   │   ├── controllers\        # Express API Controllers
│   │   ├── services\           # PDF extraction & page manipulation service (pdf-lib)
│   │   ├── routes\             # API endpoint declarations
│   │   └── server.ts           # Main Express server entry point
│   ├── prisma\
│   │   └── schema.prisma       # Database ORM schema (User, Group, DoubtPDF, PDFPage)
│   ├── package.json
│   ├── tsconfig.json
│   └── .env
└── jee_doubt_tracker\          # Standalone Flutter Frontend App
```

## Getting Started

1. Navigate to the backend directory:
   ```bash
   cd d:\rrr\backend
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Start the development server:
   ```bash
   npm run dev
   ```

## API Endpoints

- `GET /api/v1/health` - Server health check
- `GET /api/v1/doubt-pdfs` - List organized doubt PDFs by Class/Subject/Chapter
- `POST /api/v1/doubt-pdfs` - Create a new doubt PDF entry
- `POST /api/v1/doubt-pdfs/:id/append-page` - Extract & append a page from a source PDF
- `DELETE /api/v1/doubt-pdfs/:id/pages/:pageIndex` - Delete a page from a doubt PDF
