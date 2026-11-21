FROM node:18-bookworm-slim

WORKDIR /app
COPY api/package*.json ./
RUN npm ci
COPY api/knexfile.js ./
COPY api/migrations ./migrations

CMD ["npx", "knex", "migrate:latest"]