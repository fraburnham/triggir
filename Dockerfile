FROM elixir:1.15.7-alpine

# create lower level user and switch off before building?

RUN apk update && apk add telegraf git

RUN mkdir -p /etc/telegraf
COPY telegraf.conf /etc/telegraf/telegraf.conf

WORKDIR /app

COPY mix.* .
RUN mix deps.get && mix deps.compile

COPY . .
