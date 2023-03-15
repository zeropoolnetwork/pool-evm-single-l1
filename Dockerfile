FROM node:14-alpine
RUN apk add git
COPY . /app
WORKDIR /app
RUN yarn install --non-interactive --frozen-lockfile

COPY $PWD/docker/entrypoint.sh /usr/local/bin
ENTRYPOINT ["/bin/sh", "/usr/local/bin/entrypoint.sh"]
