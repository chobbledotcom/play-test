#!/bin/bash
set -euo pipefail

DEBIAN_FRONTEND=noninteractive sudo apt-get update -qq
DEBIAN_FRONTEND=noninteractive sudo apt-get install -y -qq \
    ruby-full \
    ruby-bundler \
    build-essential \
    libsqlite3-dev \
    libyaml-dev \
    libvips-dev \
    cmake \
    pkg-config \
    sassc \
    --no-install-recommends

gem install bundler --no-document --quiet

bundle install --jobs 4

bundle exec rails db:create db:migrate db:seed

RAILS_ENV=test bundle exec rails db:create db:migrate

bundle exec rails parallel:prepare
