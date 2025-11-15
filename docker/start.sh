#!/usr/bin/env bash
set -e

# Ensure php-fpm socket location matches config: create socket dir
mkdir -p /var/run

# If container is started as root, drop to app user for file perms afterwards
chown -R app:app /app || true

# Start supervisord (runs php-fpm and nginx)
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
