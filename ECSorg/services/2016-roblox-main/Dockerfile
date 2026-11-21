FROM node:18-bookworm-slim AS dependencies
WORKDIR /app
COPY 2016-roblox-main/package*.json ./
RUN npm ci

FROM dependencies AS build
COPY 2016-roblox-main/ ./
COPY 2016-roblox-main/config.example.json ./config.json
ARG INTERNAL_API_BASE_URL=http://website:5000
RUN INTERNAL_API_BASE_URL="$INTERNAL_API_BASE_URL" node -e "const fs=require('fs'); const p='config.json'; const config=JSON.parse(fs.readFileSync(p)); config.serverRuntimeConfig.backend.baseUrl=process.env.INTERNAL_API_BASE_URL; config.publicRuntimeConfig.backend.baseUrl=''; config.publicRuntimeConfig.backend.apiFormat='/apisite/{0}{1}'; config.publicRuntimeConfig.backend.withCredentials=true; fs.writeFileSync(p, JSON.stringify(config));"
RUN npm run build

FROM node:18-bookworm-slim AS runtime
ENV NODE_ENV=production
ENV PORT=3000
WORKDIR /app
COPY --from=dependencies /app/node_modules ./node_modules
COPY --from=build /app/.next ./.next
COPY --from=build /app/public ./public
COPY --from=build /app/next.config.js ./next.config.js
COPY --from=build /app/config.json ./config.json
COPY --from=build /app/package.json ./package.json
EXPOSE 3000
CMD ["npm", "run", "start"]