FROM node:20 AS deps
RUN npm install -g bun
WORKDIR /app
COPY package.json bun.lockb ./
RUN bun install --frozen-lockfile

FROM node:20 AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
ENV NEXT_TELEMETRY_DISABLED 1
RUN npm install -g bun

# environment variable
ARG VITE_API_BASE_URL
ENV VITE_API_BASE_URL $VITE_API_BASE_URL
ARG VITE_API_TIMEOUT
ENV VITE_API_TIMEOUT $VITE_API_TIMEOUT

# build app
RUN bun run build

FROM node:20 AS runner
RUN npm install -g bun
WORKDIR /app
ENV NODE_ENV production
ENV NEXT_TELEMETRY_DISABLED 1
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs
COPY --from=builder --chown=nextjs:nodejs /app/.next ./.next
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./package.json
USER nextjs
EXPOSE 3000
ENV PORT 3000
CMD ["bun", "run", "start"]
