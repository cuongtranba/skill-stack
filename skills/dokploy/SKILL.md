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
  "domain_id": null,
  "request_profile": null
}
```

`request_profile` is `null` until Cloudflare challenges a request. After that it holds the profile that worked; see **Cloudflare Bot Protection**.

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

**If `request_profile` is set, apply it to every curl in this skill**, including the snippets below that do not show it. Inline its `curl_flags` on the same line, and use `http://localhost:{local_port}/api` in place of `api_endpoint` when its `name` is `origin-tunnel`:

```bash
curl -s "https://example.com/api/project.all" -H "Authorization: Bearer ACTUAL_TOKEN_HERE" -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36" -H "Accept: application/json, text/plain, */*" -H "Accept-Language: en-US,en;q=0.9"
```

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
| "refresh api", "check swagger", "api docs" | **Endpoint Discovery** |
| "cloudflare blocked", "just a moment", "bot fight mode", any API call returning a challenge page | **Cloudflare Bot Protection** |

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

Also verify the OpenAPI spec endpoint works (used for dynamic endpoint discovery):

```bash
curl -s -o /dev/null -w "%{http_code}" "https://ENDPOINT/api/settings.getOpenApiDocument" -H "x-api-key: API_KEY"
```

If valid response → write `.dokploy.json` with the provided values. If the response is a Cloudflare challenge (HTML instead of JSON, or a `cf-mitigated: challenge` header), the credentials were never checked: run **Cloudflare Bot Protection** before asking the user about credentials. If error → show the error message and ask user to verify credentials.

Add `.dokploy.json` to `.gitignore` if not already present (it contains secrets).

## Login Flow

Authenticate with username/password to obtain a bearer token.

```bash
curl -s -X POST "{base_url}/api/auth.login" -H "Content-Type: application/json" -d '{"email":"{username}","password":"{password}"}'
```

- **Success**: Extract token from response → save `token` to `.dokploy.json`
- **Failure**: Show error message → ask user to re-enter credentials
- **Auto re-login**: When any API call returns 401 (unauthorized), automatically re-login using stored `username`/`password` without prompting user. If re-login also fails → ask user to update credentials.

## Endpoint Discovery (On-Demand)

**NEVER fabricate endpoint names.** Guessing names like `docker.getLogs` or `compose.getServiceLogs` will always return 404.

Dokploy exposes its full OpenAPI spec (448+ endpoints) via:

```bash
curl -s "{api_endpoint}/settings.getOpenApiDocument" -H "x-api-key: {api_key}"
```

**When to use:**
- Skill needs an endpoint not in `references/api-reference.md` quick-reference section
- User requests an operation not covered by existing flows
- User says "refresh api", "check swagger", or "api docs"

**Discovery workflow:**

1. Fetch the spec from `settings.getOpenApiDocument`
2. Search for keywords matching the user's intent:
   ```bash
   curl -s "{api_endpoint}/settings.getOpenApiDocument" -H "x-api-key: {api_key}" | python3 -c "import json,sys; spec=json.load(sys.stdin); [print(p) for p in sorted(spec.get('paths',{})) if 'KEYWORD' in p.lower()]"
   ```
3. Read the matched endpoint's schema (method, params, body) from the spec
4. Build and execute the curl call based on the schema
5. If NO endpoint exists for the operation → fall back to SSH per the Golden Rule

**Note:** `/swagger` serves an HTML UI only (no JSON). The paths `/swagger/json`, `/api-json`, `/swagger-json` all return 404. Always use `settings.getOpenApiDocument` for programmatic access.

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
4. **For container logs or unknown operations** — use Endpoint Discovery:
   a. Fetch spec from `settings.getOpenApiDocument`, search for relevant endpoints
   b. If an API endpoint exists → use it
   c. If no API endpoint exists → fall back to SSH:
      - Find container via `docker.getContainers` or `docker.getContainersByAppNameMatch`
      - Read logs via SSH: `ssh root@SERVER "docker logs CONTAINER_ID --tail 100"`
5. Apply any fix through the API (e.g., 526 SSL error → `domain.update` with `https: true` and `certificateType: "letsencrypt"`)
6. Link to Dokploy dashboard for full logs

## Cloudflare Bot Protection

When the Dokploy panel sits behind a Cloudflare-proxied hostname with **Bot Fight Mode** on, Cloudflare can challenge the skill's API calls. Bot Fight Mode matches requests against known bot patterns: the User-Agent and other headers (curl sends `curl/8.x`, which is a known bot pattern), the TLS and HTTP fingerprint, and the reputation of the source IP. The challenge is intermittent, so a call that worked a minute ago can fail now. The fix is to change the request profile, not the credentials.

### Detect a challenge

Treat the response as a Cloudflare challenge, not a Dokploy error, when any of these hold:

| Signal | Meaning |
|--------|---------|
| `cf-mitigated: challenge` response header | Cloudflare challenged the request. This header is decisive. |
| Status 403 or 503 with `content-type: text/html` | A Cloudflare block or challenge page. Dokploy's API answers in JSON. |
| Body contains `Just a moment...`, `Attention Required! \| Cloudflare`, `challenge-platform`, or `cf_chl_` | The challenge page HTML. |
| `python3` fails with `JSONDecodeError` / `Expecting value` on a piped API call | Usually the HTML challenge page arriving where JSON was expected. Re-run without the pipe to confirm. |

`server: cloudflare` and `cf-ray` appear on every proxied response, so they only show that Cloudflare is in the path. A Dokploy 401 or 403 with a JSON body is an auth problem: follow Auth Resolution instead.

To see the headers, probe on one line:

```bash
curl -s -o /dev/null -D - "https://ENDPOINT/api/project.all" -H "x-api-key: API_KEY" | grep -iE "^(HTTP/|content-type:|cf-mitigated:|server:)"
```

### Change the request profile

Walk this ladder from the current `request_profile` downward. Try each rung **once** with the same read-only call (`project.all`), stop at the first one that returns JSON, and save it to `.dokploy.json` as `request_profile` so every later call reuses it.

1. **`default`**: plain curl, no extra flags. This is what `request_profile: null` means.
2. **`browser`**: send the headers a browser sends. Replace `141` with the current stable Chrome major version, because an outdated browser version is itself a bot signal:

   ```bash
   curl -s "https://ENDPOINT/api/project.all" -H "x-api-key: API_KEY" -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36" -H "Accept: application/json, text/plain, */*" -H "Accept-Language: en-US,en;q=0.9"
   ```

   Saved as:

   ```json
   "request_profile": {
     "name": "browser",
     "curl_flags": "-A \"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36\" -H \"Accept: application/json, text/plain, */*\" -H \"Accept-Language: en-US,en;q=0.9\""
   }
   ```

3. **`origin-tunnel`**: skip Cloudflare entirely. If the browser profile is still challenged, Cloudflare is scoring the TLS fingerprint or the IP, which no curl header can change, so do not try more User-Agent variants. Dokploy's panel listens on port 3000 on the server, so tunnel to it over SSH. Ask the user for the SSH target if it is not known, and pick another local port if 3000 is taken:

   ```bash
   ssh -fN -o ExitOnForwardFailure=yes -L 3000:localhost:3000 root@SERVER
   ```

   ```bash
   curl -s "http://localhost:3000/api/project.all" -H "x-api-key: API_KEY"
   ```

   Saved as:

   ```json
   "request_profile": {
     "name": "origin-tunnel",
     "curl_flags": "",
     "ssh_target": "root@SERVER",
     "local_port": 3000
   }
   ```

   The tunnel only carries API calls, so the Golden Rule still holds: every change still goes through the Dokploy API. If a call gets `connection refused`, the tunnel has died: start it again. Never call `http://SERVER_IP:3000` over the internet instead, because that sends the API key in plaintext.

4. **Ask the user** with AskUserQuestion when no rung works or the tunnel is not possible. The user owns the Cloudflare zone, so offer the permanent fixes:
   - **IP Access rule**: in Cloudflare, add an IP Access rule with the *Allow* action for the machine's public IP (find it with `curl -s https://cloudflare.com/cdn-cgi/trace` and read the `ip=` line). Bot Fight Mode does not trigger when an IP Access rule matches first.
   - **DNS only**: set the Dokploy panel hostname's DNS record to *DNS only* (grey cloud). This removes Cloudflare from the API path, and the panel then needs its own TLS certificate.
   - **Turn off Bot Fight Mode** for the zone.
   - **Super Bot Fight Mode** (Pro plan and above): switch to it and add a custom rule that *Skips* Super Bot Fight Mode for the machine's IP.

   Do not suggest a WAF custom rule or Page Rule with *Skip*, *Bypass*, or *Allow* for plain Bot Fight Mode. Bot Fight Mode runs outside the Ruleset Engine, so those actions have no effect on it.

### Rules

- **Never try to solve the challenge.** Do not drive a headless browser through it, copy `cf_clearance` cookies, or use challenge solvers. The cookie is bound to the browser's User-Agent and IP and expires, and the user can fix the cause in their own zone.
- **Do not retry in a loop.** Each challenged request adds to the IP's bot score. Try one call per rung.
- **Do not re-login or ask for new credentials on a challenge.** The credentials were never checked, and `auth.login` goes through the same challenge.
- **Apply the saved profile to every call**, including Login Flow and Endpoint Discovery.
- **Re-check when the situation changes.** If a saved profile starts getting challenged, continue down the ladder from it. If the user fixes the zone, set `request_profile` back to `null`.

## Error Handling

- **No config**: Run Setup Flow
- **No git remote**: Tell user to push to GitHub first
- **Cloudflare challenge** (HTML body, `cf-mitigated: challenge`, or a JSON parse error on an API call): Run **Cloudflare Bot Protection**. Do not treat it as an auth failure.
- **API errors**: Show error message from Dokploy response
- **App name taken**: Suggest suffix like `-2` or ask for new name
- **526 SSL error**: Auto-fix domain with `domain.update`
- **Deploy failure**: Check `application.one`, link to dashboard for logs

## References

- [API Reference](references/api-reference.md) — All Dokploy API endpoints and curl patterns
- [Dockerfile Templates](references/dockerfile-templates.md) — Dockerfile, nginx.conf, .dockerignore templates
