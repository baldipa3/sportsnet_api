FROM elixir:1.18-alpine

RUN apk update && apk add --no-cache \
  build-base \
  git \
  inotify-tools \
  openssl \
  bash \
  postgresql-client

WORKDIR /app

# install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# install mix dependencies
COPY mix.exs mix.lock ./
RUN mix deps.get

COPY . .

EXPOSE 4000

CMD ["iex", "-S", "mix", "phx.server"]
