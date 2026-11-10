#!/usr/bin/env bash
set -euo pipefail

FLUTTER_DIR="/tmp/flutter"
API_BASE_URL="${API_BASE_URL:-https://smartstay-admin.onrender.com/api}"
SUPABASE_URL="${SUPABASE_URL:-https://odasdzyuriucofavonjl.supabase.co}"
SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY:-sb_publishable_GYfWQ4xJCkpgxjI2XBNVmg_6eWoUWP7}"
ADMIN_PORTAL_URL="${ADMIN_PORTAL_URL:-https://smartstay-admin.onrender.com}"

if [[ ! -d "$FLUTTER_DIR" ]]; then
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 "$FLUTTER_DIR"
fi

export PATH="${FLUTTER_DIR}/bin:${PATH}"

flutter --version
flutter config --no-analytics
flutter pub get
flutter build web --release \
  --dart-define="API_BASE_URL=${API_BASE_URL%/}" \
  --dart-define="SUPABASE_URL=${SUPABASE_URL%/}" \
  --dart-define="SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY}" \
  --dart-define="ADMIN_PORTAL_URL=${ADMIN_PORTAL_URL%/}"
