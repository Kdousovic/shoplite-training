#!/bin/bash
set -euo pipefail

# Wait for the instance's first-boot user data (dnf update, httpd, agents) to finish
cloud-init status --wait || true

APP_DIR=/opt/shoplite/web
cd "$APP_DIR"

dnf install -y python3 python3-pip

python3 -m venv "$APP_DIR/.venv"
"$APP_DIR/.venv/bin/pip" install --upgrade pip
"$APP_DIR/.venv/bin/pip" install -r "$APP_DIR/requirements.txt"

# Apache (port 80) -> gunicorn (127.0.0.1:5000) reverse proxy
cat > /etc/httpd/conf.d/shoplite.conf <<'CONF'
ProxyPreserveHost On
ProxyPass / http://127.0.0.1:5000/
ProxyPassReverse / http://127.0.0.1:5000/
CONF

# Remove the default welcome page so it cannot shadow the proxy
rm -f /etc/httpd/conf.d/welcome.conf
systemctl enable httpd
systemctl reload httpd || systemctl restart httpd
