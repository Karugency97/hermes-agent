#!/bin/bash
# Entrypoint for Coolify: run gateway and tail logs to stdout
set -e

# Decode Google OAuth client secret if provided
if [ -n "$GOOGLE_CLIENT_SECRET_B64" ]; then
    echo "$GOOGLE_CLIENT_SECRET_B64" | base64 -d > /root/.hermes/google_client_secret.json
    echo "Google client secret decoded to /root/.hermes/google_client_secret.json"
    # Run setup if not already configured
    if [ ! -f /root/.hermes/google_token.json ]; then
        python /app/skills/productivity/google-workspace/scripts/setup.py \
            --client-secret /root/.hermes/google_client_secret.json 2>/dev/null || true
    fi
fi

# Start the gateway in background
python -u -m gateway.run &
GATEWAY_PID=$!

# Wait for log file to appear, then tail it to stdout
LOG_FILE="/root/.hermes/logs/gateway.log"
ERROR_LOG="/root/.hermes/logs/errors.log"

# Give the gateway a moment to start and create log files
sleep 2

# Tail all log files to stdout so Coolify can capture them
tail -F "$LOG_FILE" "$ERROR_LOG" 2>/dev/null &

# Wait for the gateway process
wait $GATEWAY_PID
