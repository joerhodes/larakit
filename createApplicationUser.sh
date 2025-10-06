#!/usr/bin/env bash

# Script to create and set up a remote application user account.
# Automates the following steps with error detection and reporting:
#   scp deploy.id_rsa SERVER:
#   ssh SERVER
#   sudo useradd -m -s /usr/bin/bash APPUSER
#   sudo mkdir /home/APPUSER/.ssh
#   sudo mv deploy.id_rsa /home/APPUSER/.ssh/id_rsa
#   sudo chown -R APPUSER:APPUSER /home/APPUSER/.ssh
#   sudo su - APPUSER
#   chmod -R go-rwx .ssh

# Usage: ./createApplicationUser.sh {server} {application-account}
#   - {server}: SSH target in the form user@host or host (if your local user matches a remote user)
#   - {application-account}: the username to create on the remote server

# Notes:
#   - Requires existing SSH access to the remote server.
#   - The remote account used for SSH must have sudo privileges (may prompt for a password).
#   - Uses the private key located at ./keys/deploy.id_rsa in this repository.

set -euo pipefail

# verify two parameters have been passed and display usage if not, otherwise extract parameters to variables
if [ $# -ne 2 ]; then
    echo "Usage: $0 {server} {application-account}" >&2
    exit 1
fi

SERVER=$1
APP_USER=$2
KEY_PATH="$(cd "$(dirname "$0")" && pwd)/keys/deploy.id_rsa"

# verify key file exists and is readable
if [ ! -f "$KEY_PATH" ]; then
    echo "Error: Private key not found at '$KEY_PATH'." >&2
    exit 1
fi
if [ ! -r "$KEY_PATH" ]; then
    echo "Error: Private key at '$KEY_PATH' is not readable." >&2
    exit 1
fi

# verify user has access to SERVER
if ! ssh -o BatchMode=yes -o ConnectTimeout=10 -q "$SERVER" exit; then
    echo "Error: Unable to connect to server '$SERVER'. Please verify SSH connectivity and permissions." >&2
    exit 1
fi
echo "SSH connectivity to '$SERVER' verified successfully."

# copy the deploy key to the remote home directory as 'deploy.id_rsa'
echo "Transferring deploy key to $SERVER..."
if ! scp -q "$KEY_PATH" "$SERVER:deploy.id_rsa"; then
    echo "Error: Failed to transfer deploy key to $SERVER." >&2
    exit 1
fi
echo "Deploy key transferred successfully."

# run the remote setup commands in a single SSH session
cat <<'REMOTE_SCRIPT' | ssh "$SERVER" bash -s -- "$APP_USER"
set -euo pipefail
APP_USER="$1"

log() { echo "[remote] $*"; }

# Create the user if it doesn't exist
if id -u "$APP_USER" >/dev/null 2>&1; then
  log "User '$APP_USER' already exists; skipping creation."
else
  log "Creating user '$APP_USER'..."
  sudo useradd -m -s /usr/bin/bash "$APP_USER"
  log "User '$APP_USER' created."
fi

# Ensure the .ssh directory exists
log "Ensuring /home/$APP_USER/.ssh exists..."
sudo mkdir -p "/home/$APP_USER/.ssh"

# Move the key into place
if [ -f "$HOME/deploy.id_rsa" ]; then
  log "Placing private key to /home/$APP_USER/.ssh/id_rsa ..."
  sudo mv "$HOME/deploy.id_rsa" "/home/$APP_USER/.ssh/id_rsa"
else
  echo "Error: deploy.id_rsa not found in remote home directory after transfer." >&2
  exit 1
fi

# Ownership and permissions
log "Setting ownership to $APP_USER:$APP_USER ..."
sudo chown -R "$APP_USER:$APP_USER" "/home/$APP_USER/.ssh"

log "Locking down permissions on .ssh ..."
sudo -u "$APP_USER" bash -c 'chmod -R go-rwx ~/.ssh'

# Handle 'envoyer' group membership
if getent group envoyer >/dev/null 2>&1; then
  log "Group 'envoyer' exists; ensuring '$APP_USER' is a member..."
  if id -nG "$APP_USER" | grep -qw envoyer; then
    log "User '$APP_USER' is already a member of 'envoyer'; skipping."
  else
    sudo usermod -a -G envoyer "$APP_USER"
    log "User '$APP_USER' added to 'envoyer' group."
  fi
else
  echo "[remote] Warning: Group 'envoyer' does not exist on this server; user '$APP_USER' not added." >&2
fi

log "Completed setup for user '$APP_USER'."
REMOTE_SCRIPT

RC=$?
if [ $RC -ne 0 ]; then
  echo "Error: Remote setup failed with exit code $RC." >&2
  exit $RC
fi

echo "Success: Application user '$APP_USER' was configured on '$SERVER'."



