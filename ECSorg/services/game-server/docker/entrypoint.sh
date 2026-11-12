#!/bin/sh
set -eu

node -e 'const fs = require("fs"); fs.writeFileSync("config.json", JSON.stringify({
  authorization: process.env.RENDER_AUTHORIZATION,
  baseUrl: process.env.WEBSITE_BASE_URL,
  rccPort: Number(process.env.RCC_PORT || 64989),
  port: Number(process.env.GAME_SERVER_PORT || 3040),
  thumbnailWebsocketPort: Number(process.env.THUMBNAIL_WEBSOCKET_PORT || 3189),
  rcc: "/opt/rcc/",
  rccExecutable: "wine",
  content: "/opt/rcc/content/",
  dockerDisabled: true,
  websiteBotAuth: process.env.WEBSITE_BOT_AUTH,
}, null, 2));'

export DISPLAY=:99
export WINEARCH=win32
export WINEPREFIX=/opt/wine-prefix32
export WINEDEBUG=-all
export LIBGL_ALWAYS_SOFTWARE=1
export GALLIUM_DRIVER=llvmpipe
Xvfb "$DISPLAY" -screen 0 1600x1200x24+32 &
wineboot --init

exec npm run start