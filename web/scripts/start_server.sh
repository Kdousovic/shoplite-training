#!/bin/bash
set -euo pipefail

APP_DIR=/opt/shoplite/web
cd "$APP_DIR"

export FLASK_SECRET_KEY=$(aws secretsmanager get-secret-value \
  --secret-id shoplite/dev/web/flask-secret-key \
  --query SecretString --output text --region us-east-1)

"$APP_DIR/.venv/bin/gunicorn" \
  --bind 127.0.0.1:5000 \
  --workers 2 \
  --daemon \
  --pid /run/shoplite.pid \
  --access-logfile /var/log/shoplite-access.log \
  --error-logfile /var/log/shoplite-error.log \
  app:app
