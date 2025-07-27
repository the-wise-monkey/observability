FROM docker:25-dind

RUN apk add --no-cache docker-cli-compose

COPY . /observability

WORKDIR /observability

CMD ["docker", "compose", "up", "-d"] 