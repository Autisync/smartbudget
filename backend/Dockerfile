FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends build-essential && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# M-3 fix: run as a non-root, unprivileged user. Without this the process
# (and anything an attacker achieves via a future RCE in the app or a
# dependency) has root inside the container, which is unnecessary blast
# radius for a service that only needs to listen on 8000 and talk to
# Postgres/Redis. Create the user after COPY and chown app files to it.
RUN groupadd --gid 1000 app && useradd --uid 1000 --gid app --no-create-home --shell /usr/sbin/nologin app \
    && chown -R app:app /app
USER app

EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
