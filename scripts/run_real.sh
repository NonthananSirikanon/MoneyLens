#!/usr/bin/env bash
# Runs the app against the real Supabase project. The publishable key is read
# from a file outside the repo (default ~/.moneylens.env), never from the repo:
#
#   SUPABASE_PUBLISHABLE_KEY=sb_publishable_...
#
# Usage: scripts/run_real.sh [flutter run args, e.g. -d emulator-5554]
set -euo pipefail

env_file="${MONEYLENS_ENV_FILE:-$HOME/.moneylens.env}"

if [[ ! -f "$env_file" ]]; then
  echo "Missing $env_file" >&2
  echo "Create it with one line: SUPABASE_PUBLISHABLE_KEY=sb_publishable_..." >&2
  exit 1
fi

# Read only the one variable instead of sourcing the file as shell code.
key="$(sed -n 's/^SUPABASE_PUBLISHABLE_KEY=//p' "$env_file" | tail -n 1 | tr -d "\"' \r")"

case "$key" in
  sb_publishable_*) ;;
  sb_secret_*|eyJ*)
    echo "That is not a publishable key. Never put a secret/service_role key in the app." >&2
    exit 1 ;;
  *)
    echo "SUPABASE_PUBLISHABLE_KEY in $env_file must start with sb_publishable_" >&2
    exit 1 ;;
esac

cd "$(dirname "$0")/.."
exec flutter run --dart-define=SUPABASE_PUBLISHABLE_KEY="$key" "$@"
