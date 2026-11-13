FROM ghcr.io/astral-sh/uv:0.9.8 AS uv

FROM node:24.11.0-slim AS ui
WORKDIR /ui
COPY web/ui/package.json web/ui/package-lock.json web/ui/.npmrc ./
RUN npm ci

FROM python:3.14.0-slim AS build
COPY --from=uv /uv /uvx /bin/
WORKDIR /app
COPY web/api/pyproject.toml web/api/uv.lock ./
RUN uv sync --locked --no-dev --no-install-project

FROM python:3.14.0-slim
WORKDIR /app
COPY --from=build /app /app
