#!/bin/bash
set -euo pipefail

# Give gunicorn a moment to boot, then check through Apache on port 80
for i in $(seq 1 10); do
  if curl -fsS http://localhost/ > /dev/null; then
    exit 0
  fi
  sleep 3
done

curl -fsS http://localhost/ > /dev/null
