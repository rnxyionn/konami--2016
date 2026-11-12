FROM node:18-bookworm-slim AS admin-build
WORKDIR /src/admin
COPY admin/package.json ./
RUN npm install --no-audit --no-fund
COPY admin/ ./
RUN npm run build

FROM mcr.microsoft.com/dotnet/sdk:6.0 AS website-build
WORKDIR /src
COPY Roblox/ ./Roblox/
RUN dotnet restore Roblox/Roblox.Website/Roblox.Website.csproj
RUN dotnet publish Roblox/Roblox.Website/Roblox.Website.csproj -c Release -o /app/publish --no-restore

FROM mcr.microsoft.com/dotnet/aspnet:6.0 AS runtime
WORKDIR /app
COPY --from=website-build /app/publish/ ./
COPY --from=website-build /src/Roblox/Roblox.Website/appsettings.example.json ./appsettings.json
COPY --from=website-build /src/Roblox/Roblox.Website/game-servers.json ./game-servers.json
COPY --from=website-build /src/Roblox/Roblox.Website/UnsecuredContent/ ./UnsecuredContent/
COPY --from=website-build /src/Roblox/Roblox.Libraries/Templates/ ./templates/
COPY --from=website-build /src/Roblox/Roblox.Libraries/Json/ ./json/
COPY --from=admin-build /src/admin/public/ ./admin/
RUN mkdir -p /data/storage/asset /data/public/images/thumbnails /data/public/images/groups /data/public/UnsecuredContent /app/economy-chat
ENV ASPNETCORE_URLS=http://0.0.0.0:5000
EXPOSE 5000
ENTRYPOINT ["dotnet", "Roblox.Website.dll"]