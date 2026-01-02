#!/bin/bash
# ----------------------------------------
# d — Docker Compose Helper
# ----------------------------------------

COMPOSE_FILES=("docker-compose.yml" "docker-compose.yaml" "compose.yml" "compose.yaml")

# ----------------------------------------
# Find compose file
# ----------------------------------------
for f in "${COMPOSE_FILES[@]}"; do
    [[ -f "$f" ]] && COMPOSE_FILE="$f" && break
done

# Commands that don't require compose
case "$1" in
    uninstall)
        echo "⚠ Removing d command..."
        sudo rm -f /sbin/d
        sed -i '/alias dh=/d' ~/.bashrc
        echo "✅ d removed. Restart shell to finish."
        exit 0
        ;;
    dps)
        docker ps -a
        exit 0
        ;;
esac

if [[ -z "$COMPOSE_FILE" ]]; then
    echo "❌ No docker-compose file found in $(pwd)"
    exit 1
fi

# ----------------------------------------
# Helpers
# ----------------------------------------
get_host_folders() {
    docker compose -f "$COMPOSE_FILE" config \
    | awk '/- \.\// {print $2}' \
    | sed 's|^\./||' \
    | awk -F/ '{print "./"$1}' \
    | sort -u
}

# ----------------------------------------
# Main Commands
# ----------------------------------------
CMD="$1"

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
        docker compose -f "$COMPOSE_FILE" logs -f
        ;;

    du|pull)
        docker compose -f "$COMPOSE_FILE" pull
        ;;

    dn)
        echo "🧪 DRY RUN — nothing will be deleted"
        echo
        echo "📦 Containers:"
        docker compose -f "$COMPOSE_FILE" ps --services

        echo
        echo "🗂 Folders to be removed:"
        get_host_folders | sed 's/^/  - /'
        ;;

    DN)
        echo "💣 FULL NUKE MODE"
        echo
        echo "Containers:"
        docker compose -f "$COMPOSE_FILE" ps --services
        echo
        echo "Folders:"
        get_host_folders | sed 's/^/  - /'
        echo
        read -p "Type YES to continue: " CONFIRM
        [[ "$CONFIRM" != "YES" ]] && echo "Aborted." && exit 1

        docker compose -f "$COMPOSE_FILE" down --volumes --remove-orphans

        for dir in $(get_host_folders); do
            if [[ -d "$dir" ]]; then
                echo "🗑 Removing $dir"
                rm -rf "$dir"
            fi
        done

        echo "✅ Stack fully removed."
        ;;

    *)
        echo "Usage:"
        echo "  d dup        Start stack"
        echo "  d dc         Stop stack"
        echo "  d dr         Restart stack"
        echo "  d dl         Logs"
        echo "  d du         Pull images"
        echo "  d dn         Dry-run nuke"
        echo "  d DN         Full nuke"
        echo "  d uninstall  Remove script"
        ;;
esac
