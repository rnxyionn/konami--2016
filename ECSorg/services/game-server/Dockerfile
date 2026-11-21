FROM node:18-bookworm-slim

RUN dpkg --add-architecture i386 \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends wine wine32:i386 xvfb libgl1:i386 libgl1-mesa-dri:i386 libglx-mesa0:i386 libosmesa6:i386 libglu1-mesa:i386 libx11-6:i386 \
	&& rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . ./
RUN npm run build

COPY docker/entrypoint.sh /usr/local/bin/game-server-entrypoint
RUN chmod +x /usr/local/bin/game-server-entrypoint
EXPOSE 3040 3189
ENTRYPOINT ["/usr/local/bin/game-server-entrypoint"]