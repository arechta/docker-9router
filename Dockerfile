FROM node:22-alpine

ARG NINEROUTER_VERSION=latest

RUN apk add --no-cache bash curl wget \
    && npm i -g "9router@${NINEROUTER_VERSION}" --prefer-online \
    && rm -rf /root/.npm

ENV DATA_DIR=/app/data

# Runtime user set by docker-compose: user: "${DOCKER_UID}:${DOCKER_GID}"
# Host ./data must be chown'd via scripts/init-data-permissions.sh first.

EXPOSE 20128

CMD ["9router", "--skip-update", "--no-browser"]
