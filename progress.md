# FitFuture — Development Progress

_Last updated: 2026-03-28_

---

## Status Summary

The core MVP pipeline is working end-to-end: a user can sign up, upload a baseline photo, enter stats and goals, and receive an AI-generated "Future Self" body transformation image that appears on the dashboard. The onboarding flow and AI generation backend are fully functional. Several MVP screens are stubbed out or partially wired.

---

## Done

### Infrastructure & Backend
- [x] Node.js / Express / TypeScript backend with Prisma ORM
- [x] PostgreSQL database via Supabase (tables: users, photos, ai_generation_jobs, check_ins)
- [x] Supabase Storage for photo uploads with signed URL access
- [x] BullMQ job queue with Redis (local) — 3 retries with exponential backoff
- [x] AI generation worker (Replicate FLUX dev model via provider abstraction layer)
- [x] Provider abstraction: swap AI model via `AI_PROVIDER` env var, no code changes needed
- [x] JWT authentication (HS256, 90-day expiry)
- [x] Rate limiting on API

### Authentication
- [x] Apple Sign-In (identity token → JWT via JWKS verification)
- [x] Email / password auth (bcrypt hashing)
- [x] Dev login bypass for simulator testing
- [x] Session persistence via UserDefaults (token + encoded User)

### Onboarding Flow (all 7 steps)
- [x] Step 1 — Welcome screen with Sign in with Apple + email/password + dev login
- [x] Step 2 — Baseline photo capture (PhotosPicker, compressed + uploaded to Supabase)
- [x] Step 3 — Stats entry (height, weight, body fat %)
- [x] Step 4 — Goal selection (goal type, timeline, training days/week)
- [x] Step 5 — AI generation screen (queues job, polls every 3s, animated loading UI)
- [x] Step 6 — Reveal screen (draggable split-screen: Today vs Future Self)
- [x] Step 7 — Schedule screen (check-in weekday picker, notification permission request)
- [x] Stats + goal saved to backend (PATCH /api/users/:userId) before AI generation starts
- [x] Onboarding routing fix: authViewModel only updated after ScheduleView completes

### Dashboard
- [x] Future Self hero card loads AI-generated image from backend on app launch
- [x] Streak counter (consecutive weekly check-ins)
- [x] Days remaining to goal
- [x] Latest check-in card
- [x] Personalized greeting with display name

### API Endpoints
- [x] `POST /api/auth/apple` — Apple Sign-In
- [x] `POST /api/auth/register` — Email/password register
- [x] `POST /api/auth/login` — Email/password login
- [x] `POST /api/auth/dev` — Dev login (non-production only)
- [x] `PATCH /api/users/:userId` — Update profile (stats, goals, APNs token)
- [x] `GET /api/users/:userId/ai-job/latest` — Fetch latest AI result for dashboard
- [x] `POST /api/users/:userId/photo/baseline` — Upload baseline photo
- [x] `DELETE /api/users/:userId` — Delete account + all storage files
- [x] `POST /api/jobs` — Create AI generation job
- [x] `GET /api/jobs/:jobId` — Poll job status + signed result URL
- [x] `GET /api/check-ins/:userId` — List all check-ins
- [x] `POST /api/check-ins` — Submit weekly progress photo

---

## Partially Done (needs wiring / completion)

### Check-In Flow
- [x] `CheckInView` UI — photo picker + optional weight field
- [ ] Submit button is a stub (`// TODO: upload check-in`) — API call not wired
- [ ] `DashboardViewModel` does not refresh after a new check-in is submitted
- [ ] Check-ins do not store or return the actual photo URL — the `storagePath` is saved in DB but not exposed in the `GET /api/check-ins/:userId` response

### Timeline / Progress View
- [x] `TimelineView` grid layout with tap-to-expand
- [ ] Thumbnails show a grey placeholder instead of the real check-in photo (photo URL not fetched)
- [ ] `CheckInDetailView` is a stub — just shows week number, no image or split comparison

### Prediction vs Reality Comparison
- [ ] Not built — the PRD requires a split-screen comparing the AI prediction to the user's most recent real progress photo (US-10)

### Settings
- [x] Sign Out works
- [x] Delete account UI + confirmation dialog
- [ ] Delete account button calls `signOut()` instead of `DELETE /api/users/:userId` — data not actually deleted from Supabase

### Push Notifications
- [x] `NotificationService` for local weekly reminder scheduling
- [x] `pushNotificationService` in backend (APNs via apns2 library)
- [x] APNs token registration in user profile (field exists)
- [ ] No APNs `.p8` key configured — push notifications will silently fail in production
- [ ] Milestone notifications not implemented (e.g. 4-week streak celebration per PRD)

### Reminder Scheduler
- [x] `reminderScheduler.ts` worker exists (cron job for weekly check-in reminders)
- [ ] Scheduler is never started — not included in `npm run` scripts or process manager

---

## Not Built — MVP Gaps

| Feature | PRD Ref | Notes |
|---------|---------|-------|
| Prediction vs Reality screen | F-2, US-10 | Split-screen: AI image (left) vs latest real photo (right) |
| Quick-log weight on dashboard | F-3 | One-tap weight entry without full check-in |
| Daily motivational quote/insight | F-3 | Rotates daily on home screen |
| Local image caching | §6.3 | URLCache + FileManager for offline access to AI image |
| Apple Sign-In for production | §6.1 | Requires paid Apple Developer account ($99/yr) |
| Content moderation on generated images | §12.6 | Check output before surfacing to user |
| Data retention policy | §12.6 | Auto-delete after 12 months of inactivity |
| Body fat % clearly marked optional | §4, F-1 | Currently feels required in the UI |

---

## Out of Scope — Post-MVP

Per PRD §8, these are explicitly deferred to after App Store submission:

| Feature | PRD Ref |
|---------|---------|
| Goal regeneration — re-run AI from current progress photo | F-5 |
| Social sharing — Instagram-optimised shareable card | F-6 |
| In-app community feed | F-6 |
| Apple Health / HealthKit integration | §8 |
| Android version | §8 |
| Paid subscription / monetisation | §8 |
| AI-generated workout or nutrition plan | §8 |
| Milestone regenerations (new AI image every major milestone) | F-5 |

---

## Recommended Next Steps (Priority Order)

### 1. Wire up the Check-In submit button _(high impact, low effort)_
`CheckInView` has a fully built UI but the button does nothing. Call `APIService.shared.createCheckIn(userId:imageData:weightKg:)`, refresh `vm.loadData()` on success. This closes the core retention loop.

### 2. Show real photos in TimelineView _(high impact, medium effort)_
The `GET /api/check-ins/:userId` endpoint needs to return a signed photo URL alongside each check-in. Update the backend response, fetch the URL in `TimelineView`, and display the actual image in thumbnails and the detail sheet.

### 3. Wire up Delete Account in Settings _(required for App Store)_
Replace `authViewModel.signOut()` with a call to `DELETE /api/users/:userId`, then sign out. The backend endpoint already exists and deletes all storage files.

### 4. Prediction vs Reality screen _(core PRD requirement, US-10)_
Add a comparison mode to `TimelineView` or `CheckInDetailView` that shows the AI prediction image side-by-side with the user's most recent real check-in photo. This is described as "the app's most powerful retention moment" in the PRD.

### 5. Start the reminder scheduler _(push notification retention)_
Add `npm run scheduler` to the backend startup, or add it to the existing `npm run dev` script. Configure an APNs `.p8` key so reminders actually deliver.

### 6. Production Apple Sign-In _(required for App Store)_
Enroll in the Apple Developer Program ($99/yr), configure the `Sign in with Apple` capability with a real team ID, and test 2FA on a physical device.

### 7. Cache AI-generated image locally _(offline UX)_
Cache the Future Self image to `FileManager` on first load so the dashboard works without a network connection.
