#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
for command in uv node npm; do
    if ! command -v "$command" >/dev/null 2>&1; then
        printf 'Missing %s. Install uv and Node.js (including npm), then run this script again.\n' "$command" >&2
        exit 1
    fi
done

(cd "$root_dir/backend" && uv sync --locked)
(cd "$root_dir/frontend" && npm ci)

if [[ ! -e "$root_dir/backend/.env" ]]; then
    (cd "$root_dir/backend" && umask 077 && uv run --locked python -c '
from pathlib import Path
import secrets

config = Path(".env.example").read_text()
config = config.replace("SECRET_KEY=change-me-to-a-long-random-string", "SECRET_KEY=" + secrets.token_urlsafe(48))
with open(".env", "x") as env_file:
    env_file.write(config)
')
fi
if [[ ! -e "$root_dir/frontend/.env" ]]; then
    cp -n "$root_dir/frontend/.env.example" "$root_dir/frontend/.env"
fi

cat <<'MESSAGE'
Installation complete. Set GROQ_API_KEY in backend/.env before using chat.
Start the backend:  cd backend && uv run --locked uvicorn app.main:app --reload
Start the frontend: cd frontend && npm run dev
MESSAGE
