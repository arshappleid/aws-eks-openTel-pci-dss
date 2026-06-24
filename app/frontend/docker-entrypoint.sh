#!/bin/sh








set -e

ENV_JS=/usr/share/nginx/html/env-config.js

echo "Generating ${ENV_JS} ..."
cat > "${ENV_JS}" <<EOF
window._env_ = {
  API_URL: "${API_URL:-}"
};
EOF

echo "  API_URL = ${API_URL:-<not set>}"

exec nginx -g 'daemon off;'