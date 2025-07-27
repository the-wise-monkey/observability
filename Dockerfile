FROM docker:25-dind

RUN apk add --no-cache docker-cli-compose

COPY . /observability

WORKDIR /observability

CMD ["/bin/sh", "-c", "dockerd --host=unix:///var/run/docker.sock --host=tcp://0.0.0.0:2375 & until docker info > /dev/null 2>&1; do sleep 1; done; docker compose up -d"] 