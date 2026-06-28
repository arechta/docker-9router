# syntax=docker/dockerfile:1.7
# Build from patched decolua/9router source in ./repository (see scripts/sync-repository.sh).

ARG NODE_IMAGE=node:22-alpine

FROM ${NODE_IMAGE} AS builder
WORKDIR /app

RUN apk --no-cache upgrade \
    && apk --no-cache add python3 make g++ linux-headers

COPY repository/package.json ./
RUN --mount=type=cache,target=/root/.npm npm install

COPY repository/ ./
ENV NEXT_TELEMETRY_DISABLED=1
RUN npm run build

FROM ${NODE_IMAGE} AS runner
WORKDIR /app

LABEL org.opencontainers.image.title="9router-local"
LABEL org.opencontainers.image.description="9Router built from patched decolua/9router source"

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
ENV DATA_DIR=/app/data
ENV PORT=20128
ENV HOSTNAME=0.0.0.0

RUN apk --no-cache upgrade && apk --no-cache add curl bash

COPY --from=builder /app/public ./public
COPY --from=builder /app/.next/static ./.next/static
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/custom-server.js ./custom-server.js
COPY --from=builder /app/open-sse ./open-sse
COPY --from=builder /app/src/mitm ./src/mitm
COPY --from=builder /app/node_modules/node-forge ./node_modules/node-forge
COPY --from=builder /app/node_modules/next ./node_modules/next

COPY --chmod=755 docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

EXPOSE 20128

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["node", "custom-server.js"]
