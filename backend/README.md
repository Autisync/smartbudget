# SmartSpend Auth Backend

Production-ready authentication backend scaffold for SmartSpend/smartbudget.

## Stack

- FastAPI
- PostgreSQL
- Redis
- SQLAlchemy 2.x
- Alembic migrations
- JWT access/refresh tokens
- Argon2 password hashing
- Docker Compose

## Endpoints

- `POST /api/v1/auth/signup`
- `POST /api/v1/auth/login`
- `POST /api/v1/auth/refresh`
- `POST /api/v1/auth/logout`
- `POST /api/v1/auth/forgot-password`
- `POST /api/v1/auth/reset-password`
- `POST /api/v1/auth/verify-email`
- `GET /api/v1/auth/me`
- `GET /api/v1/health`

## Mobile Deep-Link Targets

The Flutter app now supports tokenized routes for auth completion:

- `smartbudget://reset-password?token=<token>`
- `smartbudget://verify-email?token=<token>`

Equivalent web-path style routes supported by GoRouter:

- `/reset-password?token=<token>`
- `/verify-email?token=<token>`

Use these in your email templates when replacing the scaffold email service.

### Quick Device Tests

Android (emulator or device):

```bash
adb shell am start -a android.intent.action.VIEW -d "smartbudget://reset-password?token=test-token"
adb shell am start -a android.intent.action.VIEW -d "smartbudget://verify-email?token=test-token"
```

iOS simulator:

```bash
xcrun simctl openurl booted "smartbudget://reset-password?token=test-token"
xcrun simctl openurl booted "smartbudget://verify-email?token=test-token"
```

### Preview Auth Links From Env

Use this script to verify generated reset/verify links using current .env values:

```bash
python -m scripts.preview_auth_links
```

## Local Development (without Docker)

1. Copy env file:

```bash
cp .env.example .env
```

PowerShell:

```powershell
Copy-Item .env.example .env -Force
```

2. Install dependencies:

```bash
pip install -r requirements.txt
```

3. Run migrations:

```bash
alembic upgrade head
```

4. Start API:

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

## Docker Development

1. Copy env file:

```bash
cp .env.example .env
```

PowerShell:

```powershell
Copy-Item .env.example .env -Force
```

2. Start services:

```bash
docker compose -f docker-compose.dev.yml up --build
```

3. Stop services:

```bash
docker compose -f docker-compose.dev.yml down
```

## GitHub Docker CI/CD (GHCR)

This repository includes a GitHub Actions workflow at [.github/workflows/docker-image.yml](../.github/workflows/docker-image.yml).

- For pull requests and pushes touching `backend/**`:
	- Builds and starts the full backend stack with Docker Compose
	- Waits for `http://localhost:8000/api/v1/health`
- For pushes to `main` after smoke tests pass:
	- Builds and publishes backend image to GHCR:
		- `ghcr.io/<owner>/smartbudget-backend:latest`
		- `ghcr.io/<owner>/smartbudget-backend:<commit-sha>`

### Important: Flutter cannot connect directly to GitHub Actions runner containers

GitHub-hosted runners are ephemeral and not publicly routable for your phone/emulator.
Use one of these approaches:

1. Local development (recommended for day-to-day)
	 - Run `docker compose -f docker-compose.dev.yml up --build` locally
	 - Start Flutter with your local API base URL (LAN IP for physical device)

2. Remote deployment for shared/stable backend URL
	 - Pull GHCR image on a VPS or cloud platform and run it there
	 - Point Flutter `AUTH_API_BASE_URL` to that deployed HTTPS URL

### Example: run GHCR image on a server

```bash
docker login ghcr.io -u <github-username>
docker pull ghcr.io/<owner>/smartbudget-backend:latest
docker run -d --name smartbudget-backend -p 8000:8000 --env-file .env ghcr.io/<owner>/smartbudget-backend:latest
```

## Security Notes

- Passwords are hashed with Argon2.
- Refresh tokens are hashed in DB.
- Refresh token rotation is enabled.
- Rate limiting scaffold exists for login attempts via Redis.
- Email verification and password reset are implemented as service abstractions.

## Email Delivery Configuration

The backend can send verification and password reset emails via SMTP.

Set in .env:

- SMTP_ENABLED=true
- SMTP_HOST=your-smtp-host
- SMTP_PORT=587
- SMTP_USERNAME=your-username
- SMTP_PASSWORD=your-password
- SMTP_USE_TLS=true
- SMTP_USE_SSL=false
- SMTP_FROM_EMAIL=noreply@your-domain
- SMTP_FROM_NAME=SmartSpend

If SMTP_ENABLED=false, emails are not sent and message details are logged for development.
