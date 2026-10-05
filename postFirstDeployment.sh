#!/usr/bin/env bash

# Script to configure services on a remote server after first deployment.
# Usage: ./postFirstDeployment.sh {server} {app_user}
#   - {server}: SSH target in the form user@host or host
#   - {app_user}: the application user on the remote server
#
# The script validates SSH connectivity and then automates these steps remotely:
#   1) sudo chmod go+rx /home/APP_USER
#   2) sudo cp /home/APP_USER/current/resources/supervisord/APP_USER.ini /etc/supervisor/conf.d/APP_USER.conf
#      sudo systemctl restart supervisor
#      sudo systemctl status supervisor (and supervisorctl status if available)
#   3) Auto-detects the installed PHP version and PHP-FPM pool directory
#      (e.g. /etc/php/8.4/fpm/pool.d on Ubuntu; falls back to /etc/php-fpm.d on RHEL-family layouts)
#      sudo cp /home/APP_USER/current/php-fpm.conf <detected pool dir>/APP_USER.conf
#      sudo php-fpm<ver> -t
#      sudo systemctl restart <detected php-fpm service>
#      sudo systemctl status <detected php-fpm service>
#   4) Detect ENV as one of dev, stage, or production by checking which nginx.ENV.conf exists under /home/APP_USER/current
#      sudo cp /home/APP_USER/current/nginx.ENV.conf /etc/nginx/sites-available/APP_USER.conf
#      sudo ln -s /etc/nginx/sites-available/APP_USER.conf /etc/nginx/sites-enabled/APP_USER.conf (force if exists)
#      sudo nginx -t
#      sudo systemctl restart nginx
#
# Each step reports failures; the script exits non-zero if any step failed.

set -euo pipefail

if [ $# -ne 2 ]; then
  echo "Usage: $0 {server} {app_user}" >&2
  exit 1
fi

SERVER=$1
APP_USER=$2

if ! [[ "$APP_USER" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
  echo "Error: '$APP_USER' is not a valid Linux username." >&2
  exit 1
fi

# Verify we can SSH to the server (non-interactive)
if ! ssh -o BatchMode=yes -o ConnectTimeout=10 -q "$SERVER" exit; then
  echo "Error: Unable to SSH into '$SERVER'. Please verify connectivity and credentials." >&2
  exit 1
fi

echo "SSH connectivity to '$SERVER' verified. Proceeding with remote configuration for user '$APP_USER'."

# Run remote configuration
set +e
ssh "$SERVER" bash -s -- "$APP_USER" <<'REMOTE_SCRIPT'
set -euo pipefail
APP_USER="$1"

# Helper to run steps and collect failures without aborting the whole script immediately.
FAIL=0
step() {
  local desc="$1"; shift
  echo "[step] $desc"
  if "$@"; then
    echo "[ok]   $desc"
  else
    local rc=$?
    echo "[fail] $desc (exit $rc)" >&2
    FAIL=1
  fi
}

# Run a sudo shell command via bash -lc to allow pipes and globs.
run_sudo_sh() {
  local cmd="$1"
  sudo bash -lc "$cmd"
}

# 1) Ensure home directory is accessible
step "Adjust home dir permissions for /home/$APP_USER" run_sudo_sh "chmod go+rx /home/$APP_USER"

# 2) Supervisor configuration
SUP_INI_SRC="/home/$APP_USER/current/resources/supervisord/$APP_USER.ini"
SUP_INI_DST="/etc/supervisor/conf.d/$APP_USER.conf"

step "Verify supervisor ini exists at $SUP_INI_SRC" test -f "$SUP_INI_SRC"
step "Copy supervisor ini to $SUP_INI_DST" run_sudo_sh "cp '$SUP_INI_SRC' '$SUP_INI_DST'"
step "Restart supervisor" run_sudo_sh "systemctl restart supervisor"
step "Check supervisor service status" run_sudo_sh "systemctl --no-pager --full status supervisor"
# Also try supervisorctl status if available, but don't fail if it's missing.
if command -v supervisorctl >/dev/null 2>&1; then
  step "Check supervisorctl status" run_sudo_sh "supervisorctl status || true"
fi

# 3) PHP-FPM pool configuration (auto-detect version and paths)
PHP_POOL_SRC="/home/$APP_USER/current/php-fpm.conf"

# Detect PHP version from CLI if available, else from php-fpm binary
PHP_VER="$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;' 2>/dev/null || true)"
if [ -z "$PHP_VER" ]; then
  PHP_VER="$(php-fpm -v 2>/dev/null | sed -n 's/^PHP \([0-9]\+\.[0-9]\+\).*/\1/p' | head -n1 || true)"
fi

# Determine PHP-FPM pool directory
POOL_DIR=""
if [ -n "$PHP_VER" ] && [ -d "/etc/php/$PHP_VER/fpm/pool.d" ]; then
  POOL_DIR="/etc/php/$PHP_VER/fpm/pool.d"
elif [ -d "/etc/php-fpm.d" ]; then
  POOL_DIR="/etc/php-fpm.d"
else
  CAND=$(ls -d /etc/php/*/fpm/pool.d 2>/dev/null | head -n1 || true)
  if [ -n "$CAND" ]; then POOL_DIR="$CAND"; fi
fi

if [ -z "$POOL_DIR" ]; then
  echo "[fail] Could not detect PHP-FPM pool directory (checked /etc/php/<ver>/fpm/pool.d and /etc/php-fpm.d)" >&2
  FAIL=1
else
  PHP_POOL_DST="$POOL_DIR/$APP_USER.conf"
  step "Verify php-fpm pool file exists at $PHP_POOL_SRC" test -f "$PHP_POOL_SRC"
  step "Copy php-fpm pool to $PHP_POOL_DST" run_sudo_sh "cp '$PHP_POOL_SRC' '$PHP_POOL_DST'"

  # Find a php-fpm test command
  FPM_TEST=""
  # PHP_VERSION_SYNC: keep this list in sync with larakit's changePhpVersion() version list
  for c in "php-fpm$PHP_VER" php-fpm php-fpm8.5 php-fpm8.4 php-fpm8.3 php-fpm8.2 php-fpm8.1; do
    if command -v "$c" >/dev/null 2>&1; then FPM_TEST="$c -t"; break; fi
  done
  if [ -n "$FPM_TEST" ]; then
    step "Validate php-fpm configuration" run_sudo_sh "$FPM_TEST"
  else
    # Last resort: try common test patterns without failing the whole flow here
    step "Validate php-fpm configuration (best effort)" run_sudo_sh "php-fpm -t || php-fpm$PHP_VER -t || true"
  fi

  # Determine systemd service name (robustly)
  SERVICE=""
  # Prefer exact matches from systemd unit files
  for s in "php$PHP_VER-fpm" php-fpm php8.3-fpm php8.2-fpm php8.1-fpm; do
    if run_sudo_sh "systemctl list-unit-files --type=service --all | awk '{print \$1}' | grep -Fxq '$s.service'"; then
      SERVICE="$s"; break
    fi
  done
  # Infer from filesystem layout if still unknown
  if [ -z "$SERVICE" ]; then
    if [ -n "${PHP_VER:-}" ] && [ -d "/etc/php/$PHP_VER/fpm" ]; then
      if run_sudo_sh "systemctl list-unit-files --type=service --all | awk '{print \$1}' | grep -Fxq 'php$PHP_VER-fpm.service'"; then
        SERVICE="php$PHP_VER-fpm"
      fi
    elif [ -d "/etc/php-fpm.d" ]; then
      if run_sudo_sh "systemctl list-unit-files --type=service --all | awk '{print \$1}' | grep -Fxq 'php-fpm.service'"; then
        SERVICE="php-fpm"
      fi
    fi
  fi
  # As a last resort, pick any php*-fpm service if present
  if [ -z "$SERVICE" ]; then
    CAND=$(run_sudo_sh "systemctl list-unit-files --type=service --all | awk '{print \$1}' | grep -E '^php([0-9]+\\.[0-9]+)?-fpm\\.service$' | head -n1" || true)
    if [ -n "$CAND" ]; then
      SERVICE="${CAND%.service}"
    fi
  fi

  if [ -n "$SERVICE" ]; then
    step "Restart $SERVICE service" run_sudo_sh "systemctl restart '$SERVICE'"
    step "Check $SERVICE service status" run_sudo_sh "systemctl --no-pager --full status '$SERVICE'"
  else
    echo "[fail] Could not identify a php-fpm systemd service to restart (tried php$PHP_VER-fpm, php-fpm, and scanned installed services)." >&2
    FAIL=1
  fi
fi

# 4) Nginx site configuration
# Detect ENV from available nginx.ENV.conf files (prefer production, then stage, then dev)
ENV=""
for e in production stage dev; do
  if [ -f "/home/$APP_USER/current/nginx.$e.conf" ]; then
    ENV="$e"; break
  fi
done
if [ -z "$ENV" ]; then
  echo "[fail] Could not find any of nginx.production.conf, nginx.stage.conf, or nginx.dev.conf under /home/$APP_USER/current" >&2
  FAIL=1
else
  NGINX_SRC="/home/$APP_USER/current/nginx.$ENV.conf"
  NGINX_AVAIL="/etc/nginx/sites-available/$APP_USER.conf"
  NGINX_ENABLED="/etc/nginx/sites-enabled/$APP_USER.conf"
  step "Copy nginx $ENV config to $NGINX_AVAIL" run_sudo_sh "cp '$NGINX_SRC' '$NGINX_AVAIL'"
  # Ensure symlink exists and points to the right file (force replace if needed)
  step "Ensure nginx site is enabled at $NGINX_ENABLED" run_sudo_sh "ln -sf '$NGINX_AVAIL' '$NGINX_ENABLED'"
  step "Validate nginx configuration" run_sudo_sh "nginx -t"
  step "Restart nginx" run_sudo_sh "systemctl restart nginx"
  step "Check nginx service status" run_sudo_sh "systemctl --no-pager --full status nginx"
fi

# Final result
if [ "$FAIL" -ne 0 ]; then
  echo "One or more steps failed. Please review the logs above." >&2
  exit 1
else
  echo "All steps completed successfully."
fi
REMOTE_SCRIPT
RC=$?
set -e

if [ $RC -ne 0 ]; then
  echo "postFirstDeployment failed with exit code $RC" >&2
  exit $RC
fi

echo "postFirstDeployment completed successfully for '$APP_USER' on '$SERVER'."
