#!/bin/bash
# Entrypoint for Coolify: run gateway and tail logs to stdout
set -e

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
