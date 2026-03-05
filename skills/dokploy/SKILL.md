---
name: dokploy
description: Deploy and manage applications on Dokploy. Use when user wants to deploy, redeploy, debug deployments, check status, view logs, or configure Dokploy settings. Triggers on "deploy", "redeploy", "dokploy", "push to production", "publish app", "deployment status", "deployment logs".
---

# Dokploy Deployment Skill

Manage application deployments on a self-hosted Dokploy instance.

## Golden Rule: API for Changes, SSH for Verification

Every change to Dokploy — creating projects, deploying applications, updating domains, configuring build settings — goes through the Dokploy API. The API is the single source of truth for mutations.

Server access (SSH, docker exec, direct file edits on the server) is only for **reading state** when debugging: checking container logs, verifying nginx configs, inspecting disk space, confirming a deploy actually landed. If you find yourself wanting to `ssh` into the server to fix something, stop — find the API call that makes that change instead.

Why this matters: API changes are tracked, reversible, and consistent with Dokploy's internal state. Direct server edits bypass Dokploy's awareness, causing state drift where the dashboard shows one thing but the server does another. That drift is the #1 source of mysterious deployment failures.

**In practice:**
- Creating/updating apps, domains, builds → API calls (`application.create`, `domain.update`, etc.)
- Triggering deploys → API call (`application.deploy`)
- Checking why a deploy failed → SSH to read logs, then fix via API
- "The SSL cert isn't working" → `domain.update` via API, not editing nginx on the server

## Configuration

Config file: `.dokploy.json` in project root.

```json
{
  "api_endpoint": "https://example.com/api",
  "api_key": "your-api-key",
  "username": "admin@example.com",
  "password": "user-password",
  "token": null,
  "domain_base": "example.com",
  "app_name": "my-app",
  "project_id": null,
  "environment_id": null,
  "application_id": null,
  "domain_id": null
}
```

### Config Resolution

1. Read `.dokploy.json` from project root
2. If missing or no auth credentials → run **Setup Flow**
3. If `application_id` is present → app already provisioned (skip to deploy/redeploy)

### Auth Resolution

When making any API call, resolve authentication in this order:

1. `token` exists → use `Authorization: Bearer {token}` header
2. Token is null or API returns 401 → have `username`/`password` → run **Login Flow** to get new token → update config
3. No `username`/`password` → fallback to `api_key` with `x-api-key` header
4. No credentials at all → run **Setup Flow**

## Bash Tool Constraints — CRITICAL

The Bash tool breaks curl in two ways. Both cause `curl: option : blank argument where content is expected`.

- **NEVER** use shell variables for API key or endpoint values
- **NEVER** use backslash line continuations (`\`) in curl commands

**The ONLY correct pattern — everything on ONE line, values inlined:**

With token auth:

```bash
curl -s "https://example.com/api/application.one?applicationId=abc" -H "Authorization: Bearer ACTUAL_TOKEN_HERE"
```

```bash
curl -s -X POST "https://example.com/api/application.deploy" -H "Content-Type: application/json" -H "Authorization: Bearer ACTUAL_TOKEN_HERE" -d '{"applicationId":"abc"}'
```

With API key fallback:

```bash
curl -s "https://example.com/api/application.one?applicationId=abc" -H "x-api-key: ACTUAL_KEY_HERE"
```

When piping, keep curl on one line before the pipe:

```bash
curl -s "https://example.com/api/project.all" -H "Authorization: Bearer ACTUAL_TOKEN_HERE" | python3 -c "import json,sys; print(json.dumps(json.load(sys.stdin),indent=2))"
```

**Always read auth credentials from `.dokploy.json` and inline them directly into curl commands. Use token (Bearer) when available, fall back to api_key (x-api-key).**

## Action Routing

Detect user intent and route:

| User says | Action |
|-----------|--------|
| "deploy", "deploy to dokploy", "push to production" | **Deploy Flow** |
| "redeploy", "redeploy {name}" | **Redeploy Flow** |
| "deployment status", "check deploy" | **Status Flow** |
| "deployment logs", "debug deployment" | **Debug Flow** |
| "configure dokploy", "set api key" | **Setup Flow** |
| "login to dokploy" | **Login Flow** |
| "refresh api", "check swagger", "api docs" | **Swagger Fetch** |

## Setup Flow

Prompt user for Dokploy connection details:

1. **API endpoint** — The Dokploy instance URL (e.g., `https://dokploy.example.com/api`)
2. **Auth method** — Ask: "Do you want to authenticate with username/password or API key?"
   - **Username/Password**: Ask for email and password → run Login Flow → store credentials + token
   - **API Key**: Ask for key (generate from Dokploy dashboard → Settings → API)
3. **Domain base** — Base domain for subdomains (e.g., `example.com` → `{app}.example.com`)

Validate the connection (use whichever auth is available):

```bash
curl -s "https://ENDPOINT/api/project.all" -H "Authorization: Bearer TOKEN"
```

or with API key:

```bash
curl -s "https://ENDPOINT/api/project.all" -H "x-api-key: API_KEY"
```

If valid response → write `.dokploy.json` with the provided values. If error → show the error message and ask user to verify credentials.

Add `.dokploy.json` to `.gitignore` if not already present (it contains secrets).

## Login Flow

Authenticate with username/password to obtain a bearer token.

```bash
curl -s -X POST "{base_url}/api/auth.login" -H "Content-Type: application/json" -d '{"email":"{username}","password":"{password}"}'
```

- **Success**: Extract token from response → save `token` to `.dokploy.json`
- **Failure**: Show error message → ask user to re-enter credentials
- **Auto re-login**: When any API call returns 401 (unauthorized), automatically re-login using stored `username`/`password` without prompting user. If re-login also fails → ask user to update credentials.

## Swagger Fetch (On-Demand)

When the skill needs an API endpoint not documented in `references/api-reference.md`, fetch the Swagger spec dynamically.

**When to trigger:**
- Skill encounters an action it doesn't have a hardcoded endpoint for
- User requests an operation not covered by existing flows
- User says "refresh api", "check swagger", or "api docs"

**How to fetch:**

```bash
curl -s "{base_url}/swagger/json" -H "Authorization: Bearer {token}"
```

If that path returns an error, try alternatives: `/api-json`, `/swagger-json`, `/swagger/doc`.

**How to use:**
- Read the Swagger JSON directly in conversation context
- Find the relevant endpoint, method, parameters, and request body schema
- Execute the API call based on the discovered spec
- Do NOT save the Swagger JSON to a file — fetch fresh each time needed

## Deploy Flow

### Step 1: Load Config

Read `.dokploy.json`. If missing or no `api_key` → run Setup Flow first.

### Step 2: Validate Prerequisites

```bash
git remote get-url origin
```

If no remote → stop: "Push your code to GitHub first: `git remote add origin <url> && git push -u origin main`"

Extract `owner` and `repo` from remote URL. Detect branch with `git branch --show-current`.

### Step 3: Prompt for App Name

If `app_name` not in config, ask:

```
What should this deployment be called?
(Will be available at {name}.{domain_base})
```

Validate: lowercase, alphanumeric, hyphens only. Save to config.

### Step 4: Ensure Dockerfile Exists

Check for `Dockerfile` and `nginx.conf` in project root. If missing, generate them.
See [references/dockerfile-templates.md](references/dockerfile-templates.md) for templates.

### Step 5: Create Project

```bash
curl -s -X POST "{api_endpoint}/project.create" -H "Content-Type: application/json" -H "x-api-key: {api_key}" -d '{"name":"{app_name}","description":"Deployed via Claude skill"}'
```

Save `projectId` AND `environmentId` from response to config. Both are required.

If project exists (error) → fetch with `project.all`, find by name, extract both IDs.

### Step 6: Create Application

```bash
curl -s -X POST "{api_endpoint}/application.create" -H "Content-Type: application/json" -H "x-api-key: {api_key}" -d '{"name":"{app_name}","projectId":"{project_id}","environmentId":"{environment_id}","description":"Auto-deployed from GitHub"}'
```

Save `applicationId` to config. `environmentId` is REQUIRED — extract from Step 5.

### Step 7: Configure Source & Build

```bash
curl -s -X POST "{api_endpoint}/application.update" -H "Content-Type: application/json" -H "x-api-key: {api_key}" -d '{"applicationId":"{application_id}","sourceType":"github","repository":"{repo}","owner":"{owner}","branch":"{branch}","buildType":"dockerfile","dockerfile":"Dockerfile"}'
```

### Step 8: Configure Domain

```bash
curl -s -X POST "{api_endpoint}/domain.create" -H "Content-Type: application/json" -H "x-api-key: {api_key}" -d '{"applicationId":"{application_id}","host":"{app_name}.{domain_base}","https":true,"certificateType":"letsencrypt","port":80}'
```

**CRITICAL:** Always set `https: true`, `certificateType: "letsencrypt"`, `port: 80`. Without these → 526 SSL error with Cloudflare.

Save `domainId` to config. If domain exists without HTTPS, fix with `domain.update`. See [references/api-reference.md](references/api-reference.md).

### Step 9: Trigger Deploy

```bash
curl -s -X POST "{api_endpoint}/application.deploy" -H "Content-Type: application/json" -H "x-api-key: {api_key}" -d '{"applicationId":"{application_id}"}'
```

### Step 10: Verify & Report

Poll `application.one` for status. Report:

```
Deployed successfully!
URL: https://{app_name}.{domain_base}
Dashboard: {api_endpoint} (remove /api)
To redeploy after changes, push to GitHub or say "redeploy"
```

**After successful deploy, write all IDs back to `.dokploy.json`.**

## Redeploy Flow

1. Load config — requires `application_id` in `.dokploy.json`
2. If no `application_id` → run full Deploy Flow instead
3. Trigger deploy: `POST {api_endpoint}/application.deploy`
4. Poll status and report

## Status Flow

1. Load config — requires `application_id`
2. Fetch: `GET {api_endpoint}/application.one?applicationId={application_id}`
3. Report: `applicationStatus`, last deployment status, domain URL

## Debug Flow

Use SSH/server access here to **diagnose**, then fix via API. Never edit server files directly to resolve issues.

1. Load config — requires `application_id`
2. Fetch application details from `application.one`
3. Check and report:
   - `applicationStatus` (idle/done/error)
   - Latest deployment status and error messages
   - Domain configuration (HTTPS enabled?)
   - Source configuration (correct repo/branch?)
4. If deeper investigation needed → SSH to read container logs, check nginx config, verify port bindings
5. Apply any fix through the API (e.g., 526 SSL error → `domain.update` with `https: true` and `certificateType: "letsencrypt"`)
6. Link to Dokploy dashboard for full logs

## Error Handling

- **No config**: Run Setup Flow
- **No git remote**: Tell user to push to GitHub first
- **API errors**: Show error message from Dokploy response
- **App name taken**: Suggest suffix like `-2` or ask for new name
- **526 SSL error**: Auto-fix domain with `domain.update`
- **Deploy failure**: Check `application.one`, link to dashboard for logs

## References

- [API Reference](references/api-reference.md) — All Dokploy API endpoints and curl patterns
- [Dockerfile Templates](references/dockerfile-templates.md) — Dockerfile, nginx.conf, .dockerignore templates
