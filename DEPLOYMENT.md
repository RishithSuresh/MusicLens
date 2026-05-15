# MusicLens Deployment Guide (Frontend + Backend)

This project is **deployment-ready for an initial production setup**:
- backend runtime config is environment-driven (`backend/.env.example`)
- CORS is configurable and no longer hardcoded-open by default in production
- backend has API tests and CI checks
- frontend API URL is environment-driven via `--dart-define`
- backend has a Dockerfile for production container builds

---

## 1) Prerequisites

- Docker installed (for backend container deployment)
- Python 3.12+ (optional, for local backend validation)
- Flutter stable (for frontend build)
- A public domain (or hostnames) for:
  - backend API (example: `api.yourdomain.com`)
  - frontend app (example: `app.yourdomain.com`)

---

## 2) Configure backend environment

1. Go to backend directory:
   ```bash
   cd /home/runner/work/MusicLens/MusicLens/backend
   ```
2. Create `.env` from example:
   ```bash
   cp .env.example .env
   ```
3. Update at least:
   - `MUSICLENS_ENV=production`
   - `MUSICLENS_CORS_ORIGINS=https://app.yourdomain.com`
   - `MUSICLENS_MAX_UPLOAD_BYTES` (keep suitable limit, e.g. 20MB)
   - `MUSICLENS_MAX_PROMPT_CHARS` (e.g. 500)
   - `MUSICLENS_ENABLE_COMPOSE=true` (or false if unavailable)
   - `MUSICLENS_ENABLE_LYRICS=true` (or false)
   - `MUSICLENS_LOG_LEVEL=INFO`

> Note: `/compose` needs optional composer dependencies from `requirements-composer.txt`.

---

## 3) Build and run backend container

From `/home/runner/work/MusicLens/MusicLens/backend`:

1. Build image:
   ```bash
   docker build -t musiclens-backend:latest .
   ```
2. Run container:
   ```bash
   docker run -d --name musiclens-backend \
     -p 8000:8000 \
     --env-file .env \
     --restart unless-stopped \
     musiclens-backend:latest
   ```
3. Verify health:
   ```bash
   curl http://127.0.0.1:8000/health
   curl http://127.0.0.1:8000/ready
   ```

If using a reverse proxy (Nginx/Caddy/Cloud LB), route `https://api.yourdomain.com` to container port `8000`.

---

## 4) Build frontend for production

1. Go to frontend directory:
   ```bash
   cd /home/runner/work/MusicLens/MusicLens/frontend
   ```
2. Fetch deps:
   ```bash
   flutter pub get
   ```
3. Build web with production API URL:
   ```bash
   flutter build web --release \
     --dart-define=MUSICLENS_API_BASE_URL=https://api.yourdomain.com
   ```
4. Deploy generated files from:
   - `/home/runner/work/MusicLens/MusicLens/frontend/build/web`

Host these static files on any static host (Nginx, S3+CloudFront, Netlify, Vercel, etc.).

---

## 5) Post-deploy checks

1. Open frontend URL and test:
   - Analyze flow (upload valid audio file)
   - Compose flow (if compose enabled and dependencies present)
2. Confirm backend responses:
   - `GET /health` returns `status: ok`
   - `GET /ready` reports analyzer/composer availability correctly
3. Confirm CORS:
   - Requests from frontend domain succeed
   - Unexpected origins are blocked

---

## 6) CI/CD baseline

Repository workflow at `.github/workflows/ci.yml` already runs:
- backend: install + `pytest`
- frontend: `flutter analyze`, `flutter test`, `flutter build web`

Recommended next step: add environment-specific deploy jobs (staging/prod) after CI succeeds.

---

## 7) Rollback plan (simple)

- Keep previous backend image tags and redeploy last known-good tag:
  ```bash
  docker stop musiclens-backend && docker rm musiclens-backend
  docker run -d --name musiclens-backend \
    -p 8000:8000 \
    --env-file .env \
    --restart unless-stopped \
    musiclens-backend:<previous-tag>
  ```
- Re-deploy previous frontend static build artifact/version.
