FROM python:3.12-slim

WORKDIR /app

RUN pip install --no-cache-dir pytest==8.3.3

COPY inventory/ /app/inventory/
COPY tests_public/ /app/tests_public/
COPY README.md /app/README.md

ENV PYTHONPATH=/app
ENV PYTHONUNBUFFERED=1
