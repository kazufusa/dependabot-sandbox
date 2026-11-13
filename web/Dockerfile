FROM node:26.13.0-slim AS ui
WORKDIR /ui
COPY web/ui/package.json web/ui/package-lock.json web/ui/.npmrc ./
RUN npm ci
COPY web/ui/ ./
RUN npm run check

FROM python:3.15.0-slim AS build
COPY --from=ghcr.io/astral-sh/uv:0.9.8 /uv /uvx /bin/
WORKDIR /app
COPY web/api/pyproject.toml web/api/uv.lock ./
RUN uv sync --locked --no-dev --no-install-project
COPY web/api/ ./
RUN uv sync --locked --no-dev

FROM python:3.15.0-slim
WORKDIR /app
COPY --from=build /app /app
COPY --from=ui /ui/src /app/static
ENV PATH="/app/.venv/bin:$PATH"
CMD ["uvicorn", "api:app", "--host", "0.0.0.0"]
