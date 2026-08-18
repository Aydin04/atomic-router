#!/usr/bin/env bash
export PORT=${PORT:-20128}
if [ ! -f .env ]; then
  if [ -f .env.example ]; then
    cp .env.example .env
  else
    echo "PORT=$PORT" > .env
  fi
fi
exec node server.js
