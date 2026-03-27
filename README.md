# FitFuture 🏋️‍♂️

**See your fitness transformation before it happens.** FitFuture uses AI to generate a photorealistic "Future Self" body transformation image from your baseline photo, fitness goals, and timeline. Then tracks your real progress with weekly photo check-ins and streak motivation.

---

## Architecture

```
FitFuture/
├── ios/                    # SwiftUI iOS app (MVVM)
│   ├── FitFuture/
│   │   ├── App/            # App entry point, root navigation
│   │   ├── Models/         # User, Photo, AIJob, CheckIn
│   │   ├── ViewModels/     # Auth, Onboarding, Dashboard, AIJob
│   │   ├── Views/          # Onboarding, Dashboard, Progress screens
│   │   ├── Services/       # APIService, NotificationService
│   │   └── Resources/      # Info.plist, entitlements
│   ├── project.yml         # XcodeGen project spec
│   └── FitFuture.xcodeproj # Generated Xcode project
│
├── backend/                # Node.js / Express / TypeScript API
│   ├── src/
│   │   ├── api/            # REST routes (auth, users, jobs, check-ins)
│   │   ├── workers/        # BullMQ AI generation worker + reminder scheduler
│   │   ├── providers/      # Swappable AI provider abstraction (Replicate)
│   │   ├── services/       # Supabase Storage, APNs push notifications
│   │   └── db/             # Prisma client singleton
│   ├── prisma/             # Database schema (PostgreSQL)
│   └── package.json
│
└── FitFuture_PRD.docx      # Product Requirements Document
```

## Tech Stack

| Layer | Technology |
|-------|-----------|
| **iOS App** | SwiftUI, MVVM, async/await, Sign in with Apple |
| **Backend API** | Express, TypeScript, Zod validation |
| **Database** | PostgreSQL via Prisma ORM |
| **Job Queue** | BullMQ + Redis (3 retries, exponential backoff) |
| **AI Generation** | Replicate API (swappable provider pattern) |
| **Storage** | Supabase Storage (signed URLs) |
| **Push Notifications** | APNs via apns2 |
| **Auth** | Apple Identity Token → JWT (HS256, 90-day expiry) |

## Getting Started

### Prerequisites

- **Xcode 16+** with iOS 17.0+ SDK
- **Node.js 18+** and npm
- **Redis** (local or hosted)
- **PostgreSQL** database (Supabase recommended)
- **Replicate** API key
- Apple Developer account (for Sign in with Apple + Push Notifications)

### Backend Setup

```bash
cd backend

# Install dependencies
npm install

# Set up environment variables
cp .env.example .env
# Edit .env with your credentials (database, Supabase, Replicate, APNs)

# Generate Prisma client & run migrations
npx prisma generate
npx prisma migrate dev --name init

# Start the API server
npm run dev

# In a separate terminal — start the AI generation worker
npm run worker

# In a separate terminal — start the weekly reminder scheduler
npm run scheduler
```

### iOS Setup

```bash
cd ios

# Generate Xcode project (requires xcodegen: brew install xcodegen)
xcodegen generate

# Open in Xcode
open FitFuture.xcodeproj
```

Then in Xcode:
1. Set your **Development Team** under Signing & Capabilities
2. Select **iPhone 16 Pro** simulator
3. Press **⌘R** to build and run

### API Endpoints

| Method | Route | Description |
|--------|-------|-------------|
| `POST` | `/api/auth/apple` | Sign in with Apple identity token |
| `PATCH` | `/api/users/:userId` | Update user profile (goals, stats, APNs token) |
| `POST` | `/api/users/:userId/photo/baseline` | Upload baseline photo (multipart) |
| `DELETE` | `/api/users/:userId` | Delete account + all data |
| `POST` | `/api/jobs` | Create AI generation job |
| `GET` | `/api/jobs/:jobId` | Poll job status + get result URL |
| `POST` | `/api/check-ins` | Submit weekly progress photo |
| `GET` | `/api/check-ins/:userId` | List all check-ins |

## App Flow

```
Welcome → Photo Capture → Stats Entry → Goal Selection
    → AI Generation (async) → Reveal (before/after)
    → Schedule Check-in Day → Dashboard
        → Weekly Check-ins → Progress Timeline
```

## Environment Variables

See [`backend/.env.example`](backend/.env.example) for the full list. Key variables:

| Variable | Purpose |
|----------|---------|
| `DATABASE_URL` | PostgreSQL connection string |
| `SUPABASE_URL` / `SUPABASE_SERVICE_ROLE_KEY` | Supabase project for photo storage |
| `REPLICATE_API_KEY` / `REPLICATE_MODEL_ID` | AI image generation |
| `JWT_SECRET` | Token signing (min 32 chars) |
| `REDIS_URL` | BullMQ job queue |
| `APNS_KEY_PATH` / `APNS_KEY_ID` / `APNS_TEAM_ID` | Push notifications |

## License

Private — All rights reserved.
