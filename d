#!/bin/bash
# =========================================
# d — Docker Compose Helper
# =========================================

COMPOSE_FILES=("docker-compose.yml" "docker-compose.yaml" "compose.yml" "compose.yaml")

CMD="$1"
shift

# ----------------------------
# Commands that do NOT require compose
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
# Find compose file
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

    dn|DN)
        DRY_RUN=1
        [[ "$CMD" == "DN" ]] && DRY_RUN=0

        echo "💣 FULL NUKE MODE"
        echo "------------------------------------"

        CONTAINERS=$(docker compose -f "$COMPOSE_FILE" ps --services)
        IMAGES=$(docker compose -f "$COMPOSE_FILE" images -q)
        FOLDERS=$(get_host_folders)

        echo "Containers:"
        echo "$CONTAINERS" | sed 's/^/  - /'

        echo "Folders:"
        for f in $FOLDERS; do
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

        for dir in $FOLDERS; do
            if [[ -d "$dir" ]]; then
                echo "🗑 Removing $dir"
                rm -rf "$dir"
            fi
        done

        echo "✅ Full stack removed."
        ;;

    *)
        echo "Usage:"
        echo "  d dup        → start stack"
        echo "  d dc         → stop stack"
        echo "  d dr         → restart"
        echo "  d dl         → logs"
        echo "  d du         → pull images"
        echo "  d dn         → dry-run delete preview"
        echo "  d DN         → full destructive delete"
        echo "  d uninstall  → remove script"
        ;;
esac
