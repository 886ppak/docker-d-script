#!/bin/bash
# =========================================
# d — Docker Compose Helper (Complete Rewrite)
# =========================================

# Look for compose files in this order
COMPOSE_FILES=("docker-compose.yml" "docker-compose.yaml" "compose.yml" "compose.yaml")

CMD="$1"
shift || true

# ----------------------------
# Commands that do NOT require a compose file
# ----------------------------
case "$CMD" in
    uninstall)
        echo "⚠ Removing d command..."
        sudo rm -f /sbin/d
        sed -i '/alias dh=/d' ~/.bashrc
        echo "✅ d removed. Restart shell to apply."
        exit 0
        ;;
    dps|status)
        docker ps -a
        exit 0
        ;;
esac

# ----------------------------
# Find the compose file
# ----------------------------
COMPOSE_FILE=""
for f in "${COMPOSE_FILES[@]}"; do
    [[ -f "$f" ]] && COMPOSE_FILE="$f" && break
done

if [[ -z "$COMPOSE_FILE" ]]; then
    echo "❌ No docker-compose file found in $(pwd)"
    exit 1
fi

# ----------------------------
# Extract top-level host folders (SAFE)
# ----------------------------
get_host_folders() {
    grep -E '^[[:space:]]*-[[:space:]]*(\.\/|/)' "$COMPOSE_FILE" \
    | sed -E 's/.*-\s*([^:]+).*/\1/' \
    | awk -F/ '{print $1"/"$2}' \
    | sort -u
}

# ----------------------------
# Shell into a container
# ----------------------------
d_sh() {
    local user="root"
    # Parse optional args
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --user) user="" ;;   # default container user
            --root) user="root" ;;
            -u) shift; user="$1" ;;
        esac
        shift
    done

    # Get list of services
    local services
    services=$(docker compose -f "$COMPOSE_FILE" ps --services)
    if [[ -z "$services" ]]; then
        echo "❌ No services found in $COMPOSE_FILE"
        return 1
    fi

    # Select service if multiple
    local service
    if [[ $(echo "$services" | wc -l) -gt 1 ]]; then
        echo "Select service:"
        select service in $services; do
            service=$(echo "$service" | tr -d '\n')  # trim newlines
            [[ -n "$service" ]] || continue
            break
        done
    else
        service="$services"
    fi

    # Start container if not running
    if ! docker compose -f "$COMPOSE_FILE" ps -q "$service" &>/dev/null; then
        echo "⚠ Service '$service' is not running. Starting it..."
        docker compose -f "$COMPOSE_FILE" up -d "$service"
    fi

    # Exec into container interactively with TTY
    if [[ -z "$user" ]]; then
        docker compose exec -it "$service" sh
    else
        docker compose exec -it -u "$user" "$service" sh
    fi
}

# ----------------------------
# Command handlers
# ----------------------------
case "$CMD" in
    dup|start)
        docker compose -f "$COMPOSE_FILE" up -d
        ;;

    dc|stop)
        docker compose -f "$COMPOSE_FILE" down
        ;;

    dr|restart)
        docker compose -f "$COMPOSE_FILE" down
        docker compose -f "$COMPOSE_FILE" up -d
        ;;

    dl|logs)
        docker compose -f "$COMPOSE_FILE" logs -f "$@"
        ;;

    du|pull)
        docker compose -f "$COMPOSE_FILE" pull
        ;;

    sh)
        d_sh "$@"
        ;;

    dn|DN)
        DRY_RUN=1
        [[ "$CMD" == "DN" ]] && DRY_RUN=0

        echo "💣 FULL NUKE MODE"
        echo "------------------------------------"

        local containers images folders
        containers=$(docker compose -f "$COMPOSE_FILE" ps --services)
        images=$(docker compose -f "$COMPOSE_FILE" images -q)
        folders=$(get_host_folders)

        echo "Containers:"
        echo "$containers" | sed 's/^/  - /'

        echo "Folders:"
        for f in $folders; do
            echo "  - $f"
        done

        if [[ $DRY_RUN -eq 1 ]]; then
            echo
            echo "🧪 DRY RUN — nothing will be deleted."
            exit 0
        fi

        echo
        read -rp "Type YES to confirm FULL DELETION: " CONFIRM
        [[ "$CONFIRM" != "YES" ]] && echo "Aborted." && exit 1

        docker compose -f "$COMPOSE_FILE" down --volumes --remove-orphans

        for dir in $folders; do
            [[ -d "$dir" ]] && echo "🗑 Removing $dir" && rm -rf "$dir"
        done

        echo "✅ Full stack removed."
        ;;

    *)
        echo "Usage:"
        echo "  d dup        → start stack"
        echo "  d dc         → stop stack"
        echo "  d dr         → restart stack"
        echo "  d dl         → logs"
        echo "  d du         → pull images"
        echo "  d sh         → shell into a container"
        echo "       --root | --user | -u USER"
        echo "  d dn         → dry-run delete preview"
        echo "  d DN         → full destructive delete"
        echo "  d uninstall  → remove script"
        ;;
esac
