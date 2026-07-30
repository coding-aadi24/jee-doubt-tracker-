# Graph Report - rrr  (2026-07-29)

## Corpus Check
- 36 files · ~36,527 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 455 nodes · 587 edges · 22 communities (17 shown, 5 thin omitted)
- Extraction: 98% EXTRACTED · 2% INFERRED · 0% AMBIGUOUS · INFERRED: 14 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- splash_screen.dart
- app_theme.dart
- Win32Window
- pdf_viewer_screen.dart
- upload_screen.dart
- uploadController.ts
- Product Requirements Document (PRD)
- package.json
- dependencies
- compilerOptions
- State
- wWinMain
- manifest.json
- JEE Doubt Tracker - Standalone Backend API
- RegisterPlugins
- rules/graphify.md
- workflows/graphify.md
- jee_doubt_tracker/README.md
- String?
- chapter_list_screen.dart
- chapter_pdf_store.dart
- pdf_download_service.dart

## God Nodes (most connected - your core abstractions)
1. `Win32Window` - 22 edges
2. `Product Requirements Document (PRD)` - 14 edges
3. `MessageHandler` - 12 edges
4. `compilerOptions` - 11 edges
5. `FlutterWindow` - 10 edges
6. `Create` - 10 edges
7. `WndProc` - 10 edges
8. `MessageHandler` - 9 edges
9. `config` - 7 edges
10. `OnCreate` - 7 edges

## Surprising Connections (you probably didn't know these)
- `OnCreate` --calls--> `RegisterPlugins()`  [INFERRED]
  jee_doubt_tracker/windows/runner/flutter_window.h → jee_doubt_tracker/windows/flutter/generated_plugin_registrant.cc
- `wWinMain()` --calls--> `CreateAndAttachConsole()`  [INFERRED]
  jee_doubt_tracker/windows/runner/main.cpp → jee_doubt_tracker/windows/runner/utils.cpp
- `Win32Window::Win32Window()` --calls--> `Destroy`  [INFERRED]
  jee_doubt_tracker/windows/runner/win32_window.cpp → jee_doubt_tracker/windows/runner/win32_window.h
- `OnCreate` --calls--> `GetClientArea`  [INFERRED]
  jee_doubt_tracker/windows/runner/flutter_window.h → jee_doubt_tracker/windows/runner/win32_window.h
- `OnCreate` --calls--> `SetChildContent`  [INFERRED]
  jee_doubt_tracker/windows/runner/flutter_window.h → jee_doubt_tracker/windows/runner/win32_window.h

## Import Cycles
- None detected.

## Communities (22 total, 5 thin omitted)

### Community 0 - "splash_screen.dart"
Cohesion: 0.07
Nodes (28): Animation, AnimationController, Color, dart:async, home_screen.dart, build, JeeDoubtTrackerApp, main (+20 more)

### Community 1 - "app_theme.dart"
Cohesion: 0.06
Nodes (30): accentAmber, accentCyan, accentGold, AppTheme, backgroundDark, backgroundGradient, glassBlueBorder, glassBorder (+22 more)

### Community 2 - "Win32Window"
Cohesion: 0.06
Nodes (52): FlutterViewController, DartProject, HWND, LPARAM, LRESULT, UINT, WPARAM, FlutterWindow (+44 more)

### Community 3 - "pdf_viewer_screen.dart"
Cohesion: 0.05
Nodes (36): dart:typed_data, 6, 627, BT, build, _buildDocumentCanvas, _buildGlassContainer, createState (+28 more)

### Community 4 - "upload_screen.dart"
Cohesion: 0.05
Nodes (37): dart:io, int?, build, _buildDropdown, _buildHeaderCard, _buildResultDetailRow, _buildSectionCard, _buildSuccessCard (+29 more)

### Community 5 - "uploadController.ts"
Cohesion: 0.10
Nodes (15): config, DoubtPdfController, DoubtPdfRecord, doubtPdfs, FallbackDriveUploadRecord, fallbackUploads, prisma, UploadController (+7 more)

### Community 6 - "Product Requirements Document (PRD)"
Cohesion: 0.11
Nodes (18): 10. Open Questions (Need Your Decision), 11. MVP Scope (Suggested First Version), 12. Success Metrics, 1. Problem Statement, 2. Goal, 3. Target Users, 4. Core User Stories, 5.1 PDF Viewer (+10 more)

### Community 7 - "package.json"
Cohesion: 0.06
Nodes (31): author, description, devDependencies, prisma, ts-node-dev, @types/cors, @types/express, @types/multer (+23 more)

### Community 8 - "dependencies"
Cohesion: 0.12
Nodes (17): dependencies, cors, dotenv, express, googleapis, multer, pdf-lib, @prisma/client (+9 more)

### Community 9 - "compilerOptions"
Cohesion: 0.12
Nodes (16): compilerOptions, esModuleInterop, forceConsistentCasingInFileNames, module, moduleResolution, outDir, resolveJsonModule, rootDir (+8 more)

### Community 10 - "State"
Cohesion: 0.21
Nodes (13): ChapterListScreen, _ChapterListScreenState, HomeScreen, _HomeScreenState, PdfViewerScreen, _PdfViewerScreenState, SplashScreen, _SplashScreenState (+5 more)

### Community 11 - "wWinMain"
Cohesion: 0.24
Nodes (9): _In_, _In_opt_, wWinMain(), string, wchar_t, CreateAndAttachConsole(), GetCommandLineArguments(), Utf8FromUtf16() (+1 more)

### Community 12 - "manifest.json"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 13 - "JEE Doubt Tracker - Standalone Backend API"
Cohesion: 0.40
Nodes (4): API Endpoints, Getting Started, JEE Doubt Tracker - Standalone Backend API, Project Structure

### Community 19 - "chapter_list_screen.dart"
Cohesion: 0.05
Nodes (42): chapter_list_screen.dart, dart:convert, dart:ui, IconData, accentColor, _availableChaptersInDb, build, _buildGlassContainer (+34 more)

### Community 20 - "chapter_pdf_store.dart"
Cohesion: 0.25
Nodes (7): _chapterPdfPaths, ChapterPdfStore, getChapterPdfPath, hasPdf, _makeKey, registerChapterPdf, static final Map

### Community 22 - "pdf_download_service.dart"
Cohesion: 0.06
Nodes (35): 0000000000 65535, 0000000009 00000, 0000000058 00000, 0000000115 00000, 0000000246 00000, 0000000558 00000 n, 1 0, 50 720 (+27 more)

## Knowledge Gaps
- **240 isolated node(s):** `name`, `version`, `description`, `main`, `build` (+235 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **5 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `keywords` connect `package.json` to `uploadController.ts`?**
  _High betweenness centrality (0.018) - this node is a cross-community bridge._
- **Why does `express` connect `uploadController.ts` to `package.json`?**
  _High betweenness centrality (0.016) - this node is a cross-community bridge._
- **Why does `dependencies` connect `dependencies` to `package.json`?**
  _High betweenness centrality (0.012) - this node is a cross-community bridge._
- **Are the 4 inferred relationships involving `MessageHandler` (e.g. with `Destroy` and `GetClientArea`) actually correct?**
  _`MessageHandler` has 4 INFERRED edges - model-reasoned connections that need verification._
- **What connects `name`, `version`, `description` to the rest of the system?**
  _240 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `splash_screen.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.06896551724137931 - nodes in this community are weakly interconnected._
- **Should `app_theme.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.06451612903225806 - nodes in this community are weakly interconnected._