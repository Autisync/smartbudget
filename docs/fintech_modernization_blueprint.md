Act as a world-class fintech product team composed of:
- Senior Flutter Architect
- Principal Product Designer
- UX Research Lead
- Design System Engineer
- Python Backend Architect
- DevOps & Scalability Engineer
- Security Engineer
- Performance Optimization Specialist

Your mission is to completely redesign and modernize SmartBudget into a premium, scalable, production-grade fintech platform.

The attached UI references represent the quality, spacing, visual hierarchy, smoothness, and premium fintech experience expected.

DO NOT copy the designs directly.
Instead:
- extract the best UX patterns
- modernize them
- unify them into one polished design system
- improve accessibility
- improve scalability
- improve usability
- improve responsiveness
- improve interaction quality

The final result should feel comparable to:
- Revolut
- Monzo
- Apple Wallet
- Robinhood
- Linear
- Stripe Dashboard
- modern fintech startups

══════════════════════════════════════════
CORE PRODUCT GOAL
══════════════════════════════════════════

SmartBudget helps users:
- manage personal finances
- track expenses
- manage budgets
- create savings goals
- monitor subscriptions
- analyze spending
- receive insights
- manage recurring payments
- view reports
- receive smart financial recommendations

The app must feel:
- trustworthy
- premium
- fast
- calm
- intelligent
- lightweight
- highly polished

══════════════════════════════════════════
PART 1 — COMPLETE UI/UX REDESIGN
══════════════════════════════════════════

Redesign the ENTIRE application UI/UX.

Modernize:
- navigation
- spacing
- typography
- animations
- charts
- cards
- dashboard
- forms
- settings
- transaction flows
- budget management
- onboarding
- authentication
- statistics
- savings goals
- notifications
- profile screens
- reports
- empty states
- loading states
- error states

══════════════════════════════════════════
DESIGN SYSTEM
══════════════════════════════════════════

Build a complete scalable design system.

Create:
- color system
- typography scale
- spacing scale
- elevation system
- animation system
- iconography rules
- reusable components
- accessibility rules
- dark/light theme system

Spacing scale:
4 / 8 / 12 / 16 / 20 / 24 / 32 / 40

Use:
- soft shadows
- layered surfaces
- premium gradients
- rounded-xl/2xl
- minimal borders
- clean separators
- soft cards
- elegant financial data presentation

Avoid:
- clutter
- oversized containers
- hard borders
- inconsistent spacing
- visual noise
- unnecessary text
- outdated neumorphism

══════════════════════════════════════════
COLOR STRATEGY
══════════════════════════════════════════

Primary:
- elegant purple/indigo fintech palette

Secondary:
- soft blue accents
- controlled emerald for positive financial actions
- soft red for expenses/errors
- amber for warnings

Backgrounds:
- warm neutral surfaces
- soft layered grayscale

Dark mode:
- true premium dark mode
- not pure black
- maintain contrast accessibility

══════════════════════════════════════════
TYPOGRAPHY
══════════════════════════════════════════

Use modern fintech typography hierarchy.

Requirements:
- large clean headlines
- compact line heights
- strong numeric readability
- proper currency formatting
- readable transaction data
- reduced text clutter

Financial numbers must visually stand out.

══════════════════════════════════════════
NAVIGATION UX
══════════════════════════════════════════

Redesign navigation completely.

Use:
- modern floating bottom navigation
- animated active states
- smooth transitions
- proper safe-area handling

Navigation must feel:
- native
- fluid
- responsive
- premium

══════════════════════════════════════════
DASHBOARD REDESIGN
══════════════════════════════════════════

Completely redesign dashboard UX.

Dashboard should include:
- financial overview
- monthly balance
- spending summary
- savings progress
- recent transactions
- subscriptions
- quick actions
- smart insights
- budget status
- charts and trends

Use:
- visual hierarchy
- expandable cards
- compact data grouping
- clean charts
- animated statistics
- modern transaction rows

Do NOT overload the screen.

══════════════════════════════════════════
CHARTS & ANALYTICS
══════════════════════════════════════════

Improve all charts.

Requirements:
- smooth animations
- interactive charts
- beautiful gradients
- touch-friendly
- readable labels
- modern fintech visualizations

Support:
- line charts
- donut charts
- category breakdowns
- trend graphs
- monthly/yearly comparisons

══════════════════════════════════════════
TRANSACTION EXPERIENCE
══════════════════════════════════════════

Improve transaction UX completely.

Add:
- transaction categories
- merchant logos
- transaction search
- filters
- swipe actions
- recurring indicators
- smart grouping
- animated transitions

Improve readability:
- amount prominence
- date clarity
- category labels
- visual distinction between income/expense

══════════════════════════════════════════
BUDGET & SAVINGS UX
══════════════════════════════════════════

Modernize:
- savings goals
- budget tracking
- spending limits
- progress indicators
- milestone celebrations

Add:
- circular progress
- animated budget states
- achievement feedback
- forecasting indicators

══════════════════════════════════════════
ONBOARDING & AUTHENTICATION
══════════════════════════════════════════

Redesign onboarding, sign in, and sign up.

Requirements:
- premium minimal screens
- soft gradients
- reduced text clutter
- modern form fields
- biometric login
- password strength indicators
- social login support
- keyboard-safe layouts
- proper autofill support

Fix:
- focus issues
- keyboard overlap
- blank white overlays
- duplicated validation errors

══════════════════════════════════════════
MICROINTERACTIONS & ANIMATIONS
══════════════════════════════════════════

Add production-grade animations.

Use:
- smooth page transitions
- subtle card animations
- haptic feedback hooks
- button press animations
- loading skeletons
- animated chart updates
- smooth list transitions

Animations must:
- feel premium
- never feel slow
- improve usability
- support 60fps rendering

══════════════════════════════════════════
ERROR HANDLING & UX FEEDBACK
══════════════════════════════════════════

Create centralized UX feedback system.

Requirements:
- clean snackbars
- inline validation
- modern loading states
- skeleton loaders
- retry mechanisms
- offline states
- empty states

Never expose raw backend errors.

Create:
- AppErrorHandler
- ErrorMapper
- reusable feedback widgets

══════════════════════════════════════════
ACCESSIBILITY
══════════════════════════════════════════

Ensure:
- WCAG compliance
- proper contrast ratios
- scalable typography
- screen-reader support
- large touch targets
- semantic widgets
- reduced motion support

══════════════════════════════════════════
PART 2 — BACKEND ARCHITECTURE REBUILD
══════════════════════════════════════════

Completely redesign backend architecture for scalability and performance.

STRICT BACKEND STACK:
- Python only for backend services
- FastAPI for APIs
- PostgreSQL for database
- Redis for caching/session/pub-sub
- Celery for background jobs
- RabbitMQ or Redis broker for Celery
- SQLAlchemy ORM
- Alembic migrations
- Pydantic validation
- JWT auth
- WebSockets for realtime updates

Optional:
- gRPC for internal services
- Nginx reverse proxy
- Docker + Docker Compose
- Kubernetes-ready architecture

══════════════════════════════════════════
BACKEND GOALS
══════════════════════════════════════════

The backend must be:
- highly scalable
- async-first
- modular
- optimized
- secure
- production-ready
- horizontally scalable
- fault tolerant

══════════════════════════════════════════
BACKEND FEATURES
══════════════════════════════════════════

Implement architecture for:
- authentication
- transactions
- budgets
- savings goals
- subscriptions
- analytics
- reports
- notifications
- recurring jobs
- AI insights
- file exports
- realtime balance updates

══════════════════════════════════════════
CELERY TASKS
══════════════════════════════════════════

Use Celery for:
- recurring transaction analysis
- report generation
- notification sending
- scheduled reminders
- subscription checks
- monthly summaries
- AI insight generation
- email jobs
- export processing

══════════════════════════════════════════
REDIS USAGE
══════════════════════════════════════════

Use Redis for:
- caching
- session storage
- rate limiting
- background queues
- pub/sub realtime updates
- analytics caching
- websocket scaling

══════════════════════════════════════════
API DESIGN
══════════════════════════════════════════

Create:
- REST API standards
- OpenAPI documentation
- versioned APIs
- modular route architecture
- DTO validation
- pagination
- filtering
- sorting
- standardized response format

══════════════════════════════════════════
SECURITY
══════════════════════════════════════════

Implement:
- JWT auth
- refresh tokens
- rate limiting
- encryption
- secure password storage
- input sanitization
- CSRF protection where applicable
- SQL injection prevention
- audit logs
- secure secrets management

══════════════════════════════════════════
PERFORMANCE OPTIMIZATION
══════════════════════════════════════════

Optimize:
- DB queries
- caching
- lazy loading
- image optimization
- list virtualization
- pagination
- websocket efficiency
- async operations

Ensure:
- low memory usage
- fast startup
- low latency
- smooth rendering
- scalable concurrency

══════════════════════════════════════════
PROJECT STRUCTURE
══════════════════════════════════════════

Generate:
- scalable monorepo structure
- modular Flutter architecture
- feature-based frontend structure
- backend service structure
- reusable components
- repository pattern
- clean architecture principles

══════════════════════════════════════════
DELIVERABLES
══════════════════════════════════════════

Generate:
1. Complete UI/UX redesign strategy
2. Modern fintech design system
3. Updated Flutter architecture
4. Reusable widget/component system
5. Backend architecture redesign
6. FastAPI modular backend
7. Redis + Celery integration
8. PostgreSQL schema strategy
9. Scalable Docker setup
10. API architecture
11. Security architecture
12. Performance optimization strategy
13. Accessibility checklist
14. Production-readiness checklist
15. Dark/light theme system
16. Navigation redesign
17. Dashboard redesign
18. Analytics redesign
19. Transaction UX redesign
20. Fully modernized fintech experience

The final product should feel like a top-tier venture-backed fintech platform ready for production deployment and long-term scale.# SmartBudget Fintech Modernization Blueprint

## Product Experience

SmartBudget should feel like a calm financial command center: one glance for balance, spend velocity, budget health, upcoming commitments, savings momentum, and recommended next action. Primary navigation is a floating mobile bar with a compact "More" sheet, while tablet and desktop use a rail for scanning-heavy workflows.

## Design System

- Color: indigo/purple primary, blue secondary, emerald for income/progress, red for expenses/errors, amber for warnings, warm neutral light surfaces, near-black violet dark surfaces.
- Typography: Plus Jakarta Sans with zero negative letter spacing, compact line heights, and tabular financial numbers through `FinanceAmount`.
- Spacing: 4, 8, 12, 16, 20, 24, 32, 40 via `UiTokens`.
- Radius: 12, 16, 20, 24, 28 for controls, cards, and floating navigation.
- Elevation: soft shadows from `AppSurfaces.elevated`; gradient financial hero cards from `AppSurfaces.gradientCard`.
- Motion: 160/240/360ms with `UiTokens.motionCurve`; keep animations subtle and disable or reduce decorative movement when platform reduced-motion settings are detected.
- Components: `PremiumCard`, `FinanceAmount`, `AppEmptyState`, `AppSkeleton`, centralized `AppFeedback`.

## Core Screens

- Dashboard: hero balance, month metrics, financial health, spend velocity, budget alerts, recent transactions, live FX quote, and quick add.
- Transactions: search, category/date filtering, recurring indicators, merchant-style avatars, swipe actions, prominent signed amounts, and clean empty states.
- Budgets and Savings: circular or linear progress, threshold states, forecasts, milestone feedback, and one-tap adjustments.
- Auth and Onboarding: minimal gradient shell, keyboard-safe forms, autofill, biometric sign-in, password strength, social login, and mapped error copy.
- Analytics and Reports: interactive line/donut/category breakdowns, date range controls, export queue status, and cached summaries.

## Flutter Architecture

- Keep feature-first clean architecture under `lib/features/*`.
- Shared product UI belongs in `lib/core/widgets`; visual primitives belong in `lib/core/theme`.
- Riverpod providers own orchestration; repositories remain the persistence/API boundary.
- Screens should compose reusable cards and skeletons rather than hand-building surfaces.
- Large lists should use lazy builders, pagination, and lightweight rows.

## Backend Architecture

- FastAPI versioned routes under `/api/v1`.
- PostgreSQL is the source of truth with SQLAlchemy models and Alembic migrations.
- Redis handles cache, rate limiting, Celery broker/result backend, session/cache expansion, and WebSocket pub-sub.
- Celery handles recurring transaction analysis, reports, notifications, subscription checks, monthly summaries, exports, and AI insight generation.
- WebSockets publish realtime balance and notification updates through Redis channels for horizontal scaling.
- Finance mutations invalidate cached analytics summaries, publish realtime balance events, and write audit-log records.
- New read-heavy endpoints should move toward `AsyncSession` and async Redis clients as they are expanded.

## API Standards

- Use Pydantic request/response DTOs.
- Every collection supports `limit`, `offset`, filtering, and deterministic sorting.
- Never expose raw backend exceptions to clients.
- Keep OpenAPI tags domain-oriented: auth, finance, analytics, reports, notifications.

## Security

- JWT access and refresh tokens, Argon2 password hashing, refresh-token revocation.
- Rate-limit sensitive endpoints with Redis.
- Validate all DTOs with Pydantic; use ORM query parameters to avoid SQL injection.
- Store secrets in environment variables only.
- Add audit logs for auth, export, destructive, and payment-adjacent actions.

## Performance

- Index user/date/category fields for finance queries.
- Cache expensive analytics summaries in Redis with short TTL and event invalidation.
- Queue reports/exports/AI insights instead of blocking API requests.
- Keep Flutter cards const-friendly and lazy-rendered; avoid expensive chart rebuilds.

## Accessibility Checklist

- Minimum 48px touch targets.
- Sufficient contrast in light/dark themes.
- Semantic labels for navigation, transaction rows, charts, and financial status.
- Scalable text without clipped numbers.
- Reduced-motion support for transitions and chart animations.

## Production Readiness

- Docker Compose includes API, Postgres, Redis, Celery worker, and Celery beat.
- Alembic migrations cover auth and finance tables.
- Health checks remain under `/api/v1/health`.
- Add CI for `flutter analyze`, Flutter tests, Python lint/type checks, migrations, and API contract tests.
- Add observability: structured logs, request IDs, metrics, queue depth, worker failures, and slow query tracking.
