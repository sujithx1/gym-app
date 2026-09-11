#!/bin/bash

set -e

echo "========================================="
echo "🚀 AuthGate Backend Deployment"
echo "========================================="

# ==============================
# VM Configuration
# ==============================

if [ -f .vm.env ]; then
  echo "📄 Loading configuration from .vm.env..."
  source .vm.env
fi

VM_USER="${VM_USER:-sujith}"
VM_IP="${VM_IP:-20.192.16.95}"
VM_PASS="${VM_PASS:-}"

DEST_DIR="${DEST_DIR:-/home/sujith/servers/gym-server}"
APP_NAME="gym-server:3001"

# ==============================
# Remote executable paths
# ==============================

run_ssh() {
  if [ -n "$VM_PASS" ]; then
    sshpass -p "$VM_PASS" ssh -o StrictHostKeyChecking=no "$@"
  else
    ssh "$@"
  fi
}

run_scp() {
  if [ -n "$VM_PASS" ]; then
    sshpass -p "$VM_PASS" scp -o StrictHostKeyChecking=no "$@"
  else
    scp "$@"
  fi
}

# PM2 is installed through NVM
PM2="/home/sujith/.nvm/versions/node/v24.19.0/bin/pm2"

# Bun is installed here
BUN="/home/sujith/.bun/bin/bun"

REMOTE_INDEX="$DEST_DIR/index.js"

# ==============================
# 1. Build
# ==============================

echo ""
echo "📦 1. Building auth-server..."

bun build ./apps/auth-server/src/index.ts \
  --outdir ./dist \
  --target=node

echo "✅ Build successful!"
echo "   Bundle: ./dist/index.js"

# ==============================
# 2. Verify remote environment
# ==============================

echo ""
echo "🔍 2. Checking remote environment..."

run_ssh "$VM_USER@$VM_IP" "
  export PATH=\"/home/sujith/.nvm/versions/node/v24.19.0/bin:\$PATH\"
  echo 'Remote user:'
  whoami

  echo ''
  echo 'PM2:'
  if [ -x '$PM2' ]; then
    echo '✅ PM2 found at $PM2'
    '$PM2' -v
  else
    echo '❌ PM2 not found at $PM2'
    exit 1
  fi

  echo ''
  echo 'Bun:'
  if [ -x '$BUN' ]; then
    echo '✅ Bun found at $BUN'
    '$BUN' --version
  else
    echo '❌ Bun not found at $BUN'
    exit 1
  fi
"

echo "✅ Remote environment OK"

# ==============================
# 3. Create destination directory
# ==============================

echo ""
echo "📁 3. Creating remote directory..."

run_ssh "$VM_USER@$VM_IP" \
  "mkdir -p '$DEST_DIR'"

echo "✅ Directory ready: $DEST_DIR"

# ==============================
# 4. Upload bundle
# ==============================

echo ""
echo "📤 4. Uploading JS bundle..."

run_scp ./dist/index.js \
  "$VM_USER@$VM_IP:$REMOTE_INDEX"

echo "✅ Upload successful!"

# ==============================
# 5. Restart PM2
# ==============================

echo ""
echo "🔄 5. Restarting PM2..."

run_ssh "$VM_USER@$VM_IP" "
  export PATH=\"/home/sujith/.nvm/versions/node/v24.19.0/bin:\$PATH\"
  PM2='$PM2'
  BUN='$BUN'
  APP_NAME='$APP_NAME'
  INDEX='$REMOTE_INDEX'

  echo 'Checking PM2 process...'

  if \$PM2 describe \"\$APP_NAME\" > /dev/null 2>&1; then

    echo '♻️ Existing PM2 process found.'
    echo 'Reloading \$APP_NAME...'

    \$PM2 reload \"\$APP_NAME\"

  else

    echo '🆕 PM2 process does not exist.'
    echo 'Starting application with Bun...'

    \$PM2 start \"\$BUN\" \
      --name \"\$APP_NAME\" \
      --cwd '$DEST_DIR' \
      -- run \"\$INDEX\"

  fi

  echo ''
  echo '📋 PM2 status:'

  \$PM2 status

  echo ''
  echo '💾 Saving PM2 process list...'

  \$PM2 save

  echo ''
  echo '✅ PM2 operation completed.'
"

# ==============================
# 6. Final status
# ==============================

echo ""
echo "========================================="
echo "🎉 Deployment complete!"
echo "========================================="

echo ""
echo "Application:"
echo "  $APP_NAME"

echo ""
echo "Server:"
echo "  $VM_USER@$VM_IP"

echo ""
echo "Remote bundle:"
echo "  $REMOTE_INDEX"

echo ""
echo "To view logs:"
echo "  ssh $VM_USER@$VM_IP '$PM2 logs \"$APP_NAME\"'"

echo ""
echo "To check status:"
echo "  ssh $VM_USER@$VM_IP '$PM2 status'"

echo ""