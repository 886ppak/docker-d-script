#!/bin/bash
# ------------------------
# d - Docker Compose helper script
# ------------------------

COMPOSE_FILES=("docker-compose.yml" "docker-compose.yaml" "compose.yml" "compose.yaml")
CMD="$1"
shift

# ------------------------
# Commands that do NOT need a compose file
# ------------------------
case "$CMD" in
    uninstall)
        echo "⚠ Removing 'd' script and dh alias..."
        sudo rm -f /sbin/d
        sed -i '/alias dh=/d' ~/.bashrc
        echo "✅ 'd' script removed. Reload shell to remove alias: source ~/.bashrc"
        exit 0
        ;;
    dps|status)
        echo "📋 All containers on host:"
        docker ps -a
        exit 0
        ;;
esac

# ------------------------
# Find Docker Compose file for the rest
# ------------------------
COMPOSE_FILE=""
for file in "${COMPOSE_FILES[@]}"; do
    if [[ -f "$file" ]]; then
        COMPOSE_FILE="$file"
        break
    fi
done

if [[ -z "$COMPOSE_FILE" ]]; then
    echo "❌ No docker-compose file found in $(pwd)"
    exit 1
fi

# ------------------------
# Require Docker
# ------------------------
if ! command -v docker &>/dev/null; then
    echo "❌ Docker not installed or not in PATH"
    exit 1
fi

# ------------------------
# Helper: get host folders from compose volumes
# ------------------------
get_host_volumes() {
    grep -E '^[[:space:]]*- ' "$COMPOSE_FILE" | while read -r line; do
        vol=$(echo "$line" | sed 's/^- //')
        host_path=$(echo "$vol" | cut -d: -f1)
        if [[ "$host_path" = /* || "$host_path" = ./* ]]; then
            echo "$host_path"
        fi
    done
}

# ------------------------
# Main commands
# ------------------------
case "$CMD" in
    start|dup)
        echo "▶ Starting stack using $COMPOSE_FILE"
        docker compose -f "$COMPOSE_FILE" up -d
        ;;

    stop|dc)
        echo "⏹ Stopping stack"
        docker compose -f "$COMPOSE_FILE" down -v --remove-orphans
        ;;

    restart|dr)
        echo "🔄 Restarting stack"
        docker compose -f "$COMPOSE_FILE" down -v --remove-orphans
        docker compose -f "$COMPOSE_FILE" up -d
        ;;

    logs|dl)
        echo "📜 Logs (Ctrl+C to exit)"
        docker compose -f "$COMPOSE_FILE" logs -f "$@"
        ;;

    pull|du)
        echo "⬇ Pulling latest images"
        docker compose -f "$COMPOSE_FILE" pull
        ;;

    nuke|dn|DN)
        DRY_RUN=0
        if [[ "$CMD" == "dn" || "$1" == "--dry-run" ]]; then
            DRY_RUN=1
        fi

        echo "💣 Nuking stack: containers, volumes, images, orphans"

        # Gather containers, images, volumes, host folders
        CONTAINERS=$(docker compose -f "$COMPOSE_FILE" ps --services --all | sort -u)
        IMAGES=$(docker compose -f "$COMPOSE_FILE" images -q | sort -u)
        VOLUMES=$(docker compose -f "$COMPOSE_FILE" config --volumes | sort -u)
        HOST_FOLDERS=$(get_host_volumes)

        if [ $DRY_RUN -eq 1 ]; then
            echo "📝 Dry-run mode: nothing will be deleted"

            echo "📦 Containers:"
            echo "$CONTAINERS" | while read c; do echo "  - $c"; done

            echo "🖼 Images:"
            echo "$IMAGES" | while read i; do echo "  - $i"; done

            echo "💾 Volumes:"
            echo "$VOLUMES" | while read v; do echo "  - $v"; done

            echo "🗑 Host folders:"
            echo "$HOST_FOLDERS" | while read f; do
                if [ -d "$f" ]; then echo "  ✅ $f"; else echo "  ⚠ $f (not found)"; fi
            done

        else
            # Real deletion
            echo "⚠ WARNING: This will permanently remove containers, images, volumes, and host folders!"
            echo "📝 Preview:"
            echo "📦 Containers:"
            echo "$CONTAINERS" | while read c; do echo "  - $c"; done
            echo "🖼 Images:"
            echo "$IMAGES" | while read i; do echo "  - $i"; done
            echo "💾 Volumes:"
            echo "$VOLUMES" | while read v; do echo "  - $v"; done
            echo "🗑 Host folders:"
            echo "$HOST_FOLDERS" | while read f; do echo "  - $f"; done

            read -p "⚠ Type 'YES' to confirm full deletion: " confirm
            if [[ "$confirm" != "YES" ]]; then
                echo "⏹ Aborted by user."
                exit 0
            fi

            # Remove containers/images/volumes/networks
            docker compose -f "$COMPOSE_FILE" down --volumes --rmi all --remove-orphans

            # Remove host folders completely
            for dir in $HOST_FOLDERS; do
                if [ -d "$dir" ]; then
                    echo "🗑 Removing folder and all contents: $dir"
                    sudo rm -rf "$dir"
                fi
            done

            echo "✅ Full stack deleted."
        fi
        ;;

    *)
        echo "Usage:"
        echo "  d start|dup       Start stack"
        echo "  d stop|dc        Stop stack"
        echo "  d restart|dr     Restart stack"
        echo "  d dps|status     Show all containers"
        echo "  d logs|dl [svc]  Follow logs"
        echo "  d pull|du        Pull latest images"
        echo "  d dn             Preview nuke (dry-run)"
        echo "  d DN             Full nuke (requires YES confirmation)"
        echo "  d uninstall      Remove script and dh alias"
        ;;
esac
