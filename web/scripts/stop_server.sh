#!/bin/bash
# Stop the running application, if any. Must never fail the deployment.
PID_FILE=/run/shoplite.pid

if [ -f "$PID_FILE" ]; then
  kill "$(cat "$PID_FILE")" 2>/dev/null || true
  rm -f "$PID_FILE"
fi
pkill -f "gunicorn.*app:app" 2>/dev/null || true
exit 0
