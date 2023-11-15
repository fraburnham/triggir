FROM elixir:1.15.7-alpine

RUN apk update && apk add telegraf git bash

RUN mkdir -p /etc/telegraf
COPY telegraf.conf /etc/telegraf/telegraf.conf

WORKDIR /app

COPY mix.* .
RUN mix deps.get && mix deps.compile

COPY . .
