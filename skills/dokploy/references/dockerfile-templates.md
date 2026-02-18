# Dockerfile Templates

Generate these files when they don't exist in the project root.

## Dockerfile (Vite/React)

```dockerfile
# Build stage
FROM node:20-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Production stage
FROM nginx:alpine
COPY --from=build /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

## nginx.conf (SPA Routing)

```nginx
server {
    listen 80;
    root /usr/share/nginx/html;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

## .dockerignore

Do NOT blanket-exclude `*.md` or `docs/` — the app may import markdown or data files at build time.

```
node_modules
dist
.git
.gitignore
.claude
.env*
.DS_Store
.dokploy.json
README.md
CLAUDE.md
```
