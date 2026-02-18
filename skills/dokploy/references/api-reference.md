# Dokploy API Reference

Based on [Dokploy API Documentation](https://docs.dokploy.com/docs/api).

All requests use `x-api-key` header for authentication. Read values from `.dokploy.json`.

## Endpoints

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `project.all` | GET | List all projects |
| `project.create` | POST | Create new project (returns `projectId` + `environmentId`) |
| `application.create` | POST | Create application (requires `environmentId`) |
| `application.update` | POST | Configure source, build type, GitHub repo |
| `application.one` | GET | Get application details and status |
| `application.deploy` | POST | Trigger deployment |
| `domain.create` | POST | Add domain with HTTPS + Let's Encrypt |
| `domain.update` | POST | Update domain config (fix HTTPS) |

## Request Patterns

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
