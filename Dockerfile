### COMMON STAGE ###
FROM docker:dind as core
# https://hexdocs.pm/phoenix/releases.html#containers looks like a nice starting point

RUN apk add --update --no-cache elixir telegraf git bash doas gettext curl jq yq helm

RUN mkdir -p /etc/telegraf
COPY telegraf.conf /etc/telegraf/telegraf.conf
COPY doas.conf /etc/doas.conf

RUN adduser -D -u 1000 user user
USER 1000

WORKDIR /app

COPY entrypoint.sh .

ENTRYPOINT [ "/app/entrypoint.sh" ]

### DEV STAGE ###
FROM core AS dev

ENV MIX_ENV=dev

USER root
RUN apk add --update --no-cache inotify-tools
USER 1000

COPY mix.* .
RUN mix deps.get && mix deps.compile

COPY . .

CMD [ "mix phx.server" ]

### PROD STAGE ###
FROM core AS prod

ENV MIX_ENV=prod

USER root
RUN apk add --update --no-cache tini

COPY mix.* .
COPY config/ config/

RUN mix deps.get --only "$MIX_ENV" \
    && mix deps.compile

COPY . .

RUN mix assets.deploy \
    && mix compile \
    && mix phx.gen.release \
    && mix release

# TODO!: fix needing root for so long in this stage
USER 1000

CMD [ "_build/prod/rel/triggir/bin/triggir", "start" ]
