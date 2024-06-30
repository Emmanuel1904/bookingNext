# Base image with Node.js
FROM node:18-alpine AS base

# Builder stage
FROM base AS builder

WORKDIR /app

# Install dependencies based on the preferred package manager
COPY package.json ./
COPY yarn.lock ./
COPY package-lock.json ./
RUN if [ -f yarn.lock ]; then \
      yarn --frozen-lockfile; \
    else \
      echo "Warning: Lockfile not found. It is recommended to commit lockfiles to version control." && \
      npm install; \
    fi

# Copy application source code
COPY . .

# Set build-time environment variables
ARG ENV_VARIABLE
ENV ENV_VARIABLE=${ENV_VARIABLE}
ARG NEXT_PUBLIC_ENV_VARIABLE
ENV NEXT_PUBLIC_ENV_VARIABLE=${NEXT_PUBLIC_ENV_VARIABLE}

# Build the application with detailed logging
RUN if [ -f yarn.lock ]; then \
      echo "Building with yarn..." && yarn build --verbose; \
    else \
      echo "Building with npm..." && npm run build --verbose; \
    fi

# Production image
FROM base AS runner

WORKDIR /app

# Create non-root user
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 nextjs
USER nextjs

# Copy built assets and node_modules from builder
COPY --from=builder /app/public ./public
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./package.json

# Set runtime environment variables
ARG ENV_VARIABLE
ENV ENV_VARIABLE=${ENV_VARIABLE}
ARG NEXT_PUBLIC_ENV_VARIABLE
ENV NEXT_PUBLIC_ENV_VARIABLE=${NEXT_PUBLIC_ENV_VARIABLE}

# Command to run the application
CMD ["yarn", "start"]