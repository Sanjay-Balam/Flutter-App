# Use the official Bun image
FROM oven/bun:1-alpine AS base
WORKDIR /app

# Install dependencies
COPY package.json bun.lockb* ./
RUN bun install --frozen-lockfile --production

# Copy source code
COPY . .

# Expose port
EXPOSE 3000

# Set environment
ENV NODE_ENV=production
ENV PORT=3000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3000/health || exit 1

# Start the application
CMD ["bun", "run", "start"] 