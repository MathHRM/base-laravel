#!/usr/bin/env bash
set -euo pipefail

# Ensure git will accept this mounted repository (ownership may differ)
# Try to add safe.directory for both root and app user
git config --global --add safe.directory /app 2>/dev/null || true
su app -s /bin/bash -c 'git config --global --add safe.directory /app' 2>/dev/null || true

# Ensure directory ownership so composer/git operations work as the 'app' user
chown -R app:app /app || true

# Run composer install if vendor is missing or composer.lock changed
if [ -f /app/composer.json ]; then
  need_install=0
  if [ ! -d /app/vendor ]; then
    need_install=1
  elif [ -f /app/composer.lock ] && [ /app/composer.lock -nt /app/vendor ]; then
    need_install=1
  fi

  if [ "$need_install" -eq 1 ]; then
    echo "Running composer install in container (as 'app' user)..."
    su app -s /bin/bash -c 'composer install --prefer-dist --no-interaction --no-dev --optimize-autoloader' || {
      echo "composer install failed" >&2
      exit 1
    }
      # Ensure the `app` user can write compiled views, cache and vendor
      chown -R app:app /app/storage /app/bootstrap /app/vendor || true
      chmod -R 775 /app/storage /app/bootstrap || true
  fi
fi

# Exec the main process (php-fpm)
exec "$@"
