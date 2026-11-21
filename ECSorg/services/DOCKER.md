# Docker setup

This Compose stack runs the existing Next.js frontend, ASP.NET website, PostgreSQL database, Redis cache, database migrations, Go asset validator, Node game-server/WebSocket endpoint, and an Nginx reverse proxy. It uses the project services and their existing pages; it does not generate replacement pages.

## Start

From this directory, run the stack with the local `.env` already provided in this workspace. On a fresh checkout, copy `.env.example` to `.env` and change the local-only secrets first. Then run:

```sh
docker compose up --build -d
```

Only the Nginx proxy is published on host port `8080`. Open the frontend at [http://roblox.localhost:8080](http://roblox.localhost:8080). The API/site host is [http://api.roblox.localhost:8080](http://api.roblox.localhost:8080), with the application form at `/auth/application` and admin panel at `/admin`. The frontend, website, game-server, database, and Redis ports stay on the private Compose network. Persistent database, uploaded storage, and public files use named volumes.

For local account setup, the Compose stack enables development-only application auto-approval. Applicants must still verify a supported social profile and pass hCaptcha; underage applications are rejected. The first accepted account receives ID `1`, matching `OWNER_USER_ID=1`. Set `LOCAL_AUTO_APPROVE_APPLICATIONS=false` to restore the normal account-age and reputation checks.

To inspect startup or migration errors, run `docker compose logs -f migrate website frontend proxy`. Stop the services with `docker compose down`; this keeps the named volumes. `docker compose down -v` also deletes database and uploaded data.

## Game services

The Node game-server and render WebSocket start in this stack. The checked-in `RCCService.exe` is Windows-only, while the Linux RCC image build expects an `rcc-docker/` payload that is not present in the repository. Actual rendering and game execution will not work until a compatible Linux `rcc` binary and content payload are provided and mounted at `/opt/rcc/`. Game-server registration and public game joining also need valid game-server entries and a reachable RCC deployment.

The included `.env.example` values are for local testing only. Configure real secrets, domain names, HTTPS termination, hCaptcha, and other external integrations before making the site public. This stack keeps the repository's .NET 6 and Node 18 targets; both runtime lines are out of support, so upgrade and retest them before public exposure.