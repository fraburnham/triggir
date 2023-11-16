FROM elixir:1.15.7-alpine

RUN apk add --update --no-cache telegraf git bash openssh

RUN mkdir -p /etc/telegraf
COPY telegraf.conf /etc/telegraf/telegraf.conf

RUN adduser -D -u 1000 user user
USER 1000

WORKDIR /app

COPY mix.* .
RUN mix deps.get && mix deps.compile

COPY . .
