FROM docker:25-dind

RUN apk add --no-cache docker-cli-compose

COPY . /observability

WORKDIR /observability
ENV DOCKER_HOST=tcp://127.0.0.1:2375
CMD ["docker", "compose", "up", "-d"] 