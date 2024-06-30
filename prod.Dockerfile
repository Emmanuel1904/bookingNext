FROM node:18-alpine

WORKDIR /app

# Copy all files to the container's working directory
COPY . .

# Install dependencies based on the preferred package manager
RUN \
  if [ -f yarn.lock ]; then \
    yarn --frozen-lockfile; \
  elif [ -f package-lock.json ]; then \
    npm ci; \
  elif [ -f pnpm-lock.yaml ]; then \
    corepack enable pnpm && pnpm install; \
  else \
    echo "Warning: Lockfile not found. It is recommended to commit lockfiles to version control." && \
    yarn install; \
  fi

# Set environment variables for the build process
ARG ENV_VARIABLE
ENV ENV_VARIABLE=${ENV_VARIABLE}
ARG NEXT_PUBLIC_ENV_VARIABLE
ENV NEXT_PUBLIC_ENV_VARIABLE=${NEXT_PUBLIC_ENV_VARIABLE}

# Uncomment the following line to disable Next.js telemetry at build time
# ENV NEXT_TELEMETRY_DISABLED 1

# Build the Next.js application
RUN \
  if [ -f yarn.lock ]; then \
    yarn build; \
  elif [ -f package-lock.json ]; then \
    npm run build; \
  elif [ -f pnpm-lock.yaml ]; then \
    pnpm build; \
  else \
    npm run build; \
  fi

# Set the command to start the Next.js application
CMD \
  if [ -f yarn.lock ]; then \
    yarn start; \
  elif [ -f package-lock.json ]; then \
    npm run start; \
  elif [ -f pnpm-lock.yaml ]; then \
    pnpm start; \
  else \
    npm run start; \
  fi
