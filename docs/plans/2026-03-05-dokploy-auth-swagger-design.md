# Dokploy Skill: Username/Password Auth + On-Demand Swagger

**Date:** 2026-03-05
**Status:** Approved

## Goal

Update the dokploy skill to support username/password authentication and on-demand Swagger API discovery, so the skill can dynamically learn endpoints from the Dokploy instance instead of relying solely on hardcoded references.

## Design

### 1. Config Changes (`.dokploy.json`)

New fields added:

```json
{
  "api_endpoint": "https://apps.quickable.co/api",
  "api_key": "optional-existing-key",
  "username": "admin@example.com",
  "password": "user-password",
  "token": null,
  "domain_base": "quickable.co",
  "app_name": "my-app",
  "project_id": null,
  "environment_id": null,
  "application_id": null,
  "domain_id": null
}
```

### 2. Auth Priority

When making API calls, auth is resolved in this order:

1. `token` exists in config -> use `Authorization: Bearer {token}`
2. Token expired/null + `username`/`password` exist -> login to get new token -> update config
3. No username/password -> fallback to `api_key` with `x-api-key` header
4. Nothing available -> run Setup Flow

### 3. Setup Flow Update

Ask user to choose auth method:

- **Option A: Username/Password** -> ask for email + password -> login immediately -> store credentials + token
- **Option B: API Key** -> existing flow unchanged

Both options still ask for `api_endpoint` and `domain_base`.

### 4. Login Flow

```bash
curl -s -X POST "{base_url}/api/auth.login" -H "Content-Type: application/json" -d '{"email":"{username}","password":"{password}"}'
```

- Success: extract token from response, save to `.dokploy.json`
- Failure: show error, ask user to re-enter credentials
- Auto re-login: when any API call returns 401, re-login using stored credentials without prompting user

### 5. On-Demand Swagger Fetch

**When triggered:**
- Skill encounters an endpoint not in `references/api-reference.md`
- User requests an action the skill doesn't have a hardcoded flow for
- User explicitly says "refresh api docs" or "check swagger"

**How it works:**
1. Fetch Swagger JSON: `curl -s "{base_url}/swagger/json" -H "Authorization: Bearer {token}"`
2. If path fails, try alternatives: `/api-json`, `/swagger-json`
3. Read JSON directly in conversation context to find needed endpoint
4. Execute API call based on discovered spec

**No file caching** - Swagger is read in-context each time it's needed.

### 6. Action Routing Update

New routes added:

| User says | Action |
|-----------|--------|
| "refresh api", "check swagger" | **Swagger Fetch** |
| "login to dokploy" | **Login Flow** |

### 7. Files to Change

- `skills/dokploy/SKILL.md` - Add Login Flow, Swagger Fetch, update Setup Flow, update auth patterns
- `skills/dokploy/references/api-reference.md` - Add `auth.login` endpoint, Swagger endpoint, note about dynamic discovery

### 8. Backward Compatibility

- Existing projects with `api_key` continue to work unchanged
- New projects can choose either auth method
- Token auth is preferred when both are available
