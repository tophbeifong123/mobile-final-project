# 📱 InternFinder — Mobile Final Project

[![Flutter CI](https://github.com/tophbeifong123/mobile-final-project/actions/workflows/client-ci.yml/badge.svg)](https://github.com/tophbeifong123/mobile-final-project/actions/workflows/client-ci.yml)
[![NestJS CI](https://github.com/tophbeifong123/mobile-final-project/actions/workflows/server-ci.yml/badge.svg)](https://github.com/tophbeifong123/mobile-final-project/actions/workflows/server-ci.yml)
[![Kanban Board](https://img.shields.io/badge/Project-Kanban%20Board-blueviolet?logo=github)](https://github.com/users/tophbeifong123/projects/2)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-3.44+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![NestJS](https://img.shields.io/badge/NestJS-12.x-E0234E?logo=nestjs&logoColor=white)](https://nestjs.com)

A production-grade mobile application architecture built with **Flutter** (Frontend Mobile App) and **NestJS** (Backend API), following industry-standard **Best Practices**, **Clean Architecture**, and **CI/CD Automation**.

---

## 🔗 Links & Guide

| Resource | Link / Details | Description |
|---|---|---|
| 📌 **Kanban Project Board** | [InternFinder Board](https://github.com/users/tophbeifong123/projects/2) | Visual task management board (Backlog, Ready, In Progress, Done) |
| 🗂️ **Product Backlog** | [Issues Tracker #1–#48](https://github.com/tophbeifong123/mobile-final-project/issues) | Complete list of all 48 epics and user stories |
| 📑 **API Documentation** | [Swagger OpenAPI](http://localhost:3000/api/docs) | Interactive API tester (`/api/docs` on dev server) |
| 🤝 **Contribution Guide** | [CONTRIBUTING.md](CONTRIBUTING.md) | Branching strategy (Git Flow) & Conventional Commits |

### 🏃‍♂️ Sprint & Backlog Breakdown

```
Sprint 1: Foundation, Design & Auth (#1–#13, #27)
 ├── Ready: #1-#6 (Repo, NestJS, Flutter, DB, ERD, Secrets), #11-#13 (Auth API), #27 (Auth UI)
 └── Backlog: #7-#10 (Figma Design System & Flows)

Sprint 2: Profiles & Job Core (#14–#19, #28–#32)
 └── Backlog: Student profile, Resume upload, Job CRUD, Public listing/search & Flutter feeds

Sprint 3: Applications & Company Module (#20–#25, #33–#38)
 └── Backlog: Application workflow, In-app notifications, Company job/applicant management

Sprint 4: Quality, Deployment & Docs (#26, #39–#48)
 └── Backlog: E2E/Widget tests, Docker container, Cloud deploy, Release APK, Docs & Demo script
```

### 📋 Kanban Board Workflow
1. **Backlog**: Tasks planned for upcoming sprints waiting to be picked up.
2. **Ready**: High-priority tasks groomed and ready to start immediately.
3. **In Progress**: Actively being worked on (Branch naming: `feat/<name>` or `fix/<name>`).
4. **In Review**: Pull Request submitted with passing CI checks.
5. **Done**: Code reviewed, merged into `develop`/`main`, and verified.

---

## 🏗️ System Architecture


```
mobile-final-project/
├── .github/                     # GitHub Workflows & Issue/PR Templates
│   ├── ISSUE_TEMPLATE/          # Bug & Feature templates
│   ├── workflows/               # CI/CD pipelines for Flutter & NestJS
│   └── pull_request_template.md # Standard PR checklist
├── client/                      # Flutter Mobile Application
│   ├── lib/
│   │   ├── core/                # Core utilities, theme, network, constants
│   │   ├── features/            # Feature-first modules (auth, home, etc.)
│   │   └── main.dart            # Flutter application entry point
│   ├── test/                    # Unit and Widget tests
│   └── pubspec.yaml
├── server/                      # NestJS Backend API
│   ├── src/
│   │   ├── main.ts              # Server bootstrap + Swagger Docs + CORS
│   │   ├── app.module.ts        # Root module with ConfigModule
│   │   ├── app.controller.ts
│   │   └── app.service.ts
│   ├── test/                    # Unit and E2E tests
│   ├── .env.example             # Environment variables blueprint
│   ├── Dockerfile               # Containerized production build
│   └── package.json
├── docker-compose.yml           # Local dev database (PostgreSQL) + services
├── CONTRIBUTING.md              # Git Flow & Conventional Commits guide
├── LICENSE                      # MIT License
└── README.md
```

---

## 🚀 Tech Stack & Design Patterns

### Mobile Client (`client/`)
- **Framework**: Flutter 3.44+ / Dart 3.12+
- **Architecture**: **Feature-First / Clean Architecture** (`core/` + `features/`)
  - `presentation`: UI Screens & reusable Widgets
  - `domain`: Entities & Use Cases
  - `data`: Repositories & Data Sources
- **Design System**: Material 3 with unified Dark/Light theme tokens
- **Linter**: Official Flutter linter rules via `analysis_options.yaml`

### Backend Server (`server/`)
- **Framework**: NestJS 12.x (TypeScript)
- **Documentation**: OpenAPI / Swagger configured at `/api/docs`
- **Config**: Global `@nestjs/config` for `.env` management
- **Testing**: Vitest & Supertest for Unit and E2E tests
- **Containerization**: Multi-stage Dockerfile

### DevOps & Collaboration
- **CI/CD**: GitHub Actions workflows for automated linting, test runs, and build checks
- **Commit Standard**: [Conventional Commits](https://www.conventionalcommits.org/)
- **Branching Model**: Git Flow (`main`, `develop`, `feat/*`, `fix/*`)

---

## ⚡ Quick Start Guide

### 1. Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`>= 3.27.0`)
- [Node.js](https://nodejs.org/) (`>= 20.0.0` or `22.x`) & npm
- [Docker & Docker Compose](https://www.docker.com/) (Optional, for database)

---

### 2. Backend Setup (`server/`)

1. Navigate to the server folder:
   ```bash
   cd server
   ```

2. Copy the environment file:
   ```bash
   cp .env.example .env
   ```

3. Install dependencies:
   ```bash
   npm install --legacy-peer-deps
   ```

4. Start the development server:
   ```bash
   npm run start:dev
   ```

5. Access the API and interactive documentation:
   - **Base API**: [http://localhost:3000/api](http://localhost:3000/api)
   - **Swagger OpenAPI Docs**: [http://localhost:3000/api/docs](http://localhost:3000/api/docs)

*(Optional: Run PostgreSQL via Docker Compose from project root)*
```bash
docker compose up -d
```

---

### 3. Mobile Client Setup (`client/`)

1. Navigate to the client folder:
   ```bash
   cd client
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Check connected devices / emulators:
   ```bash
   flutter devices
   ```

4. Run the app:
   ```bash
   flutter run
   ```

> **Note for Android Emulator:** The Android emulator accesses host localhost via `http://10.0.2.2:3000/api`. This is pre-configured in [api_constants.dart](client/lib/core/constants/api_constants.dart).

---

## 🧪 Running Tests & Quality Checks

| Component | Task | Command |
|---|---|---|
| **Client** | Check Code Formatting | `cd client && dart format --output=none --set-exit-if-changed .` |
| **Client** | Static Code Analysis | `cd client && flutter analyze` |
| **Client** | Run Unit / Widget Tests | `cd client && flutter test` |
| **Server** | Linting | `cd server && npm run lint` |
| **Server** | Unit Tests | `cd server && npm test` |
| **Server** | Production Build | `cd server && npm run build` |

---

## 🤝 Contribution & Team Workflow

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct, Git branching strategy, and conventional commit format.

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
