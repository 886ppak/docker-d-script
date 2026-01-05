#!/bin/bash
# ============================================================
# d — Docker Compose Helper
# ============================================================
# Features:
# - Auto-detect compose file in current directory
# - Lifecycle helpers (up/down/restart/logs/pull)
# - Safe dry-run + destructive nuke mode
# - Auto shell into containers (d sh)
#   - root by default
#   - --user (container default)
#   - -u USER (specific user)
# ============================================================

set -euo pipefail

# ------------------------------------------------------------
# Config
# ------------------------------------------------------------
COMPOSE_FILES=(
  docker-compose.yml
  docker-compose.yaml
  compose.yml
  compose.yaml
)

CMD="${1:-}"
shift || true

# ------------------------------------------------------------
# Commands that do NOT require compose
# ------------------------------------------------------------
case "$CMD" in
  uninstall)
    echo "⚠ Removing d command..."
    sudo rm -f /sbin/d
    sed -i '/alias dh=/d' ~/.bashrc 2>/dev/null || true
    echo "✅ d removed. Restart shell to apply."
    exit 0
    ;;
  dps|status)
    docker ps -a
    exit 0
    ;;
esac

# ------------------------------------------------------------
# Locate compose file
# ------------------------------------------------------------
COMPOSE_FILE=""
for f in "${COMPOSE_FILES[@]}"; do
  [[ -f "$f" ]] && COMPOSE_FILE="$f" && break
done

if [[ -z "$COMPOSE_FILE" ]]; then
  echo "❌ No docker compose file found in: $(pwd)"
  exit 1
fi

DC="docker compose -f $COMPOSE_FILE"

# ------------------------------------------------------------
# Helpers
# ------------------------------------------------------------
get_host_folders() {
  grep -E '^[[:space:]]*-[[:space:]]*(\.\/|/)' "$COMPOSE_FILE" \
    | sed -E 's/.*-\s*([^:]+).*/\1/' \
    | awk -F/ '{print $1"/"$2}' \
    | sort -u
}

select_service() {
  mapfile -t services < <($DC ps --services 2>/dev/null)

  if [[ "${#services[@]}" -eq 0 ]]; then
    echo "❌ No running services"
    exit 1
  fi

  if [[ "${#services[@]}" -eq 1 ]]; then
    echo "${services[0]}"
    return
  fi

  echo "Select service:"
  select service in "${services[@]}"; do
    [[ -n "$service" ]] && echo "$service" && return
  done
}

shell_into_service() {
  local exec_user="root"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --user)
        exec_user=""
        shift
        ;;
      --root)
        exec_user="root"
        shift
        ;;
      -u)
        exec_user="$2"
        shift 2
        ;;
      *)
        shift
        ;;
    esac
  done

  service="$(select_service)"

  if [[ -n "$exec_user" ]]; then
    $DC exec -u "$exec_user" "$service" bash 2>/dev/null || \
    $DC exec -u "$exec_user" "$service" sh
  else
    $DC exec "$service" bash 2>/dev/null || \
    $DC exec "$service" sh
  fi
}

# ------------------------------------------------------------
# Command handlers
# ------------------------------------------------------------
case "$CMD" in

  dup|up|start)
    $DC up -d
    ;;

  dc|down|stop)
    $DC down
    ;;

  dr|restart)
    $DC down
    $DC up -d
    ;;

  dl|logs)
    $DC logs -f "$@"
    ;;

  du|pull)
    $DC pull
    ;;

  sh|shell)
    shell_into_service "$@"
    ;;

  dn|DN)
    DRY_RUN=1
    [[ "$CMD" == "DN" ]] && DRY_RUN=0

    echo "💣 FULL NUKE MODE"
    echo "------------------------------------"

    CONTAINERS="$($DC ps --services || true)"
    FOLDERS="$(get_host_folders || true)"

    echo "Containers:"
    echo "$CONTAINERS" | sed 's/^/  - /'

    echo "Folders:"
    for f in $FOLDERS; do
      echo "  - $f"
    done

    if [[ "$DRY_RUN" -eq 1 ]]; then
      echo
      echo "🧪 DRY RUN — nothing will be deleted."
      exit 0
    fi

    echo
    read -rp "Type YES to confirm FULL DELETION: " CONFIRM
    [[ "$CONFIRM" != "YES" ]] && echo "Aborted." && exit 1

    $DC down --volumes --remove-orphans

    for dir in $FOLDERS; do
      if [[ -d "$dir" ]]; then
        echo "🗑 Removing $dir"
        rm -rf "$dir"
      fi
    done

    echo "✅ Full stack removed."
    ;;

  *)
    cat <<EOF
Usage:
  d dup | up              → start stack
  d dc  | down            → stop stack
  d dr                    → restart stack
  d dl                    → logs (follow)
  d du                    → pull images
  d sh [--root|--user|-u USER]
                          → shell into container
  d dn                    → dry-run delete preview
  d DN                    → full destructive delete
  d dps | status          → docker ps -a
  d uninstall             → remove d command
EOF
    ;;
esac
