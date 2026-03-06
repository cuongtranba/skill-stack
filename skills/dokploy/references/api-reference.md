# Dokploy API Reference

Based on [Dokploy API Documentation](https://docs.dokploy.com/docs/api).

Authentication: Use `Authorization: Bearer {token}` header (preferred) or `x-api-key` header (fallback). Read values from `.dokploy.json`. See Auth Resolution in SKILL.md.

## Dynamic Endpoint Discovery

Dokploy exposes its full OpenAPI spec via a tRPC endpoint. **Always use this to discover endpoints** rather than guessing names.

### Fetch the full spec

```bash
curl -s "{api_endpoint}/settings.getOpenApiDocument" -H "x-api-key: {api_key}"
```

Returns an OpenAPI 3.x JSON document with all available endpoints under `paths`.

### Find endpoints for a task

Pipe the spec through a filter to find relevant endpoints:

```bash
curl -s "{api_endpoint}/settings.getOpenApiDocument" -H "x-api-key: {api_key}" | python3 -c "import json,sys; spec=json.load(sys.stdin); [print(p) for p in sorted(spec.get('paths',{})) if 'KEYWORD' in p.lower()]"
```

Replace `KEYWORD` with what you're looking for (e.g., `compose`, `docker`, `deploy`, `domain`).

### Get endpoint details (method, params, body schema)

```bash
curl -s "{api_endpoint}/settings.getOpenApiDocument" -H "x-api-key: {api_key}" | python3 -c "import json,sys; spec=json.load(sys.stdin); print(json.dumps(spec['paths'].get('/ENDPOINT_NAME',{}), indent=2))"
```

Replace `ENDPOINT_NAME` with the endpoint path (e.g., `compose.one`, `docker.getContainers`).

### Discovery workflow

1. Identify user intent (e.g., "get compose logs")
2. Fetch spec, search for relevant keywords
3. Read the matched endpoint's schema (method, required params, request body)
4. Build and execute the curl call from the schema
5. If NO endpoint exists for the operation, fall back to SSH (see Golden Rule in SKILL.md)

## Essential Patterns (Quick Reference)

These are the most commonly used patterns. For anything else, use discovery above.

### Login

```bash
curl -s -X POST "{base_url}/api/auth.login" -H "Content-Type: application/json" -d '{"email":"{username}","password":"{password}"}'
```

Response contains a bearer token. Save to `token` in `.dokploy.json`.

### List Projects

```bash
curl -s "{api_endpoint}/project.all" -H "x-api-key: {api_key}"
```

### Create Project

```bash
curl -s -X POST "{api_endpoint}/project.create" -H "Content-Type: application/json" -H "x-api-key: {api_key}" -d '{"name":"{app_name}","description":"Deployed via Claude skill"}'
```

Response contains `projectId` at top level and `environmentId` nested under environments.

### Create Application

```bash
curl -s -X POST "{api_endpoint}/application.create" -H "Content-Type: application/json" -H "x-api-key: {api_key}" -d '{"name":"{app_name}","projectId":"{project_id}","environmentId":"{environment_id}","description":"Auto-deployed from GitHub"}'
```

`environmentId` is REQUIRED. Without it the call fails.

### Update Application (Source & Build)

```bash
curl -s -X POST "{api_endpoint}/application.update" -H "Content-Type: application/json" -H "x-api-key: {api_key}" -d '{"applicationId":"{application_id}","sourceType":"github","repository":"{repo}","owner":"{owner}","branch":"{branch}","buildType":"dockerfile","dockerfile":"Dockerfile"}'
```

### Create Domain

```bash
curl -s -X POST "{api_endpoint}/domain.create" -H "Content-Type: application/json" -H "x-api-key: {api_key}" -d '{"applicationId":"{application_id}","host":"{app_name}.{domain_base}","https":true,"certificateType":"letsencrypt","port":80}'
```

Always include `"https": true`, `"certificateType": "letsencrypt"`, `"port": 80`.

### Fix Domain HTTPS (526 SSL Error)

```bash
curl -s -X POST "{api_endpoint}/domain.update" -H "Content-Type: application/json" -H "x-api-key: {api_key}" -d '{"domainId":"{domain_id}","host":"{app_name}.{domain_base}","https":true,"certificateType":"letsencrypt","port":80}'
```

### Deploy Application

```bash
curl -s -X POST "{api_endpoint}/application.deploy" -H "Content-Type: application/json" -H "x-api-key: {api_key}" -d '{"applicationId":"{application_id}"}'
```

### Check Application Status

```bash
curl -s "{api_endpoint}/application.one?applicationId={application_id}" -H "x-api-key: {api_key}"
```

Key response fields:
- `applicationStatus`: `"idle"` | `"done"` | `"error"`
- `deployments[0].status`: latest deployment status
- `deployments[0].logPath`: path to build logs
