# Base image with Node.js
FROM node:18-alpine AS base

# Builder stage
FROM base AS builder

WORKDIR /app

# Install dependencies based on the preferred package manager
COPY package.json yarn.lock* ./
RUN if [ -f yarn.lock ]; then \
      yarn --frozen-lockfile; \
    else \
      echo "Warning: Lockfile not found. It is recommended to commit lockfiles to version control." && \
      yarn install; \
    fi

# Copy application source code
COPY src ./src
COPY public ./public
COPY next.config.mjs .
COPY tsconfig.json .

# Set build-time environment variables
ARG ENV_VARIABLE
ENV ENV_VARIABLE=${ENV_VARIABLE}
ARG NEXT_PUBLIC_ENV_VARIABLE
ENV NEXT_PUBLIC_ENV_VARIABLE=${NEXT_PUBLIC_ENV_VARIABLE}

# Build the application
RUN if [ -f yarn.lock ]; then \
      yarn build; \
    else \
      npm run build; \
    fi

# Production image
FROM base AS runner

WORKDIR /app

# Create non-root user
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 nextjs
USER nextjs

# Copy built assets from builder
COPY --from=builder /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

# Set runtime environment variables
ARG ENV_VARIABLE
ENV ENV_VARIABLE=${ENV_VARIABLE}
ARG NEXT_PUBLIC_ENV_VARIABLE
ENV NEXT_PUBLIC_ENV_VARIABLE=${NEXT_PUBLIC_ENV_VARIABLE}

# Command to run the application
CMD ["node", "server.js"]
