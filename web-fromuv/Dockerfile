FROM ghcr.io/astral-sh/uv:0.13.9 AS uv

FROM node:26.13.1-slim AS ui
WORKDIR /ui
COPY web/ui/package.json web/ui/package-lock.json web/ui/.npmrc ./
RUN npm ci

FROM python:3.15.2-slim AS build
COPY --from=uv /uv /uvx /bin/
WORKDIR /app
COPY web/api/pyproject.toml web/api/uv.lock ./
RUN uv sync --locked --no-dev --no-install-project

FROM python:3.15.2-slim
WORKDIR /app
COPY --from=build /app /app
