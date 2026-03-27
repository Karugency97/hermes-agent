# ─────────────────────────────────────────────
# Hermes Agent — Dockerfile for Coolify
# Runs the gateway (messaging platform bridges)
# ─────────────────────────────────────────────
FROM python:3.11-slim AS base

# Install system dependencies + Node.js 20
RUN apt-get update && apt-get install -y --no-install-recommends \
    git curl build-essential libffi-dev libssl-dev procps \
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy dependency files first for layer caching
COPY pyproject.toml requirements.txt package.json package-lock.json ./

# Install Python dependencies (core + messaging + cron)
RUN pip install --no-cache-dir -e ".[messaging,cron,pty,mcp,slack,honcho]" 2>/dev/null || \
    pip install --no-cache-dir -e ".[messaging,cron,pty,mcp,slack]" 2>/dev/null || \
    pip install --no-cache-dir -e "."

# Install Node.js dependencies (agent-browser)
RUN npm ci --omit=dev 2>/dev/null || npm install --omit=dev

# Copy the rest of the application
COPY . .

# Re-install in editable mode with full source
RUN pip install --no-cache-dir -e ".[messaging,cron,pty,mcp,slack]" 2>/dev/null || \
    pip install --no-cache-dir -e "."

# Create hermes home directory
RUN mkdir -p /root/.hermes

# Copy custom Karugency config
RUN cp cli-config.yaml.example /root/.hermes/config.yaml
COPY hermes-config-karugency.yaml /root/.hermes/config.yaml

# Copy SOUL.md (agent identity)
COPY SOUL.md /root/.hermes/SOUL.md

# Health check endpoint — the gateway doesn't expose HTTP by default,
# so we check that the Python process is alive
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD pgrep -f "gateway.run" || exit 1

# Ensure Python logs go to stdout/stderr for Coolify log capture
ENV PYTHONUNBUFFERED=1

# Copy entrypoint script
COPY docker-entrypoint.sh /app/docker-entrypoint.sh
RUN chmod +x /app/docker-entrypoint.sh

# Default: run the gateway with log tailing for Coolify
ENTRYPOINT ["/app/docker-entrypoint.sh"]
