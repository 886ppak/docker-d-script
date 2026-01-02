#!/bin/bash
# ------------------------
# d - Docker Compose helper script
# ------------------------

COMPOSE_FILES=("docker-compose.yml" "docker-compose.yaml" "compose.yml" "compose.yaml")

CMD="$1"
shift

# ------------------------
# Commands that do not need a compose file
# ------------------------
case "$CMD" in
    ps|status)
        echo "📋 All containers on host:"
        docker ps -a
        exit 0
        ;;
esac

# ------------------------
# Find docker-compose file for the rest
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
# Helper: get top-level folders from host paths
# ------------------------
get_top_level_folders() {
    get_host_volumes | while read -r path; do
        path="${path%/}"
        if [[ "$path" = ./* ]]; then
            echo "./${path#./}" | awk -F/ '{print "./"$2}'
        else
            echo "$path" | awk -F/ '{print "/"$2}'
        fi
    done | sort -u
}

# ------------------------
# Main commands
# ------------------------
case "$CMD" in
    start)
        echo "▶ Starting stack using $COMPOSE_FILE"
        docker compose -f "$COMPOSE_FILE" up -d
        ;;

    stop)
        echo "⏹ Stopping stack"
        docker compose -f "$COMPOSE_FILE" down -v --remove-orphans
        ;;

    restart)
        echo "🔄 Restarting stack"
        docker compose -f "$COMPOSE_FILE" down -v --remove-orphans
        docker compose -f "$COMPOSE_FILE" up -d
        ;;

    logs)
        echo "📜 Logs (Ctrl+C to exit)"
        docker compose -f "$COMPOSE_FILE" logs -f "$@"
        ;;

    pull)
        echo "⬇ Pulling latest images"
        docker compose -f "$COMPOSE_FILE" pull
        ;;

    nuke)
        DRY_RUN=0
        if [[ "$1" == "--dry-run" ]]; then
            DRY_RUN=1
        fi

        echo "💣 Nuking stack: containers, volumes, images, orphans"

        if [ $DRY_RUN -eq 1 ]; then
            echo "📝 Dry-run mode: nothing will be deleted"

            echo "📦 Containers that would be stopped and removed:"
            docker compose -f "$COMPOSE_FILE" ps --services --all | sort -u | while read svc; do
                echo "  - $svc"
            done

            echo "🖼 Images that would be removed:"
            docker compose -f "$COMPOSE_FILE" images -q | sort -u | while read img; do
                echo "  - $img"
            done

            echo "💾 Volumes that would be removed:"
            docker compose -f "$COMPOSE_FILE" config --volumes | sort -u | while read vol; do
                echo "  - $vol"
            done

            echo "🗑 Top-level host folders that would be removed:"
            TOP_LEVEL_FOLDERS=$(get_top_level_folders)
            for dir in $TOP_LEVEL_FOLDERS; do
                if [ -d "$dir" ]; then
                    echo "  ✅ $dir"
                else
                    echo "  ⚠ $dir (not found)"
                fi
            done

        else
            # Real deletion
            docker compose -f "$COMPOSE_FILE" down --volumes --rmi all --remove-orphans

            echo "🗑 Top-level host folders used by this stack:"
            TOP_LEVEL_FOLDERS=$(get_top_level_folders)
            for dir in $TOP_LEVEL_FOLDERS; do
                if [ -d "$dir" ]; then
                    read -p "⚠ Are you sure you want to delete $dir? [y/N]: " confirm
                    if [[ "$confirm" =~ ^[Yy]$ ]]; then
                        echo "🗑 Removing folder: $dir"
                        sudo rm -rf "$dir"
                    else
                        echo "⏹ Skipped folder: $dir"
                    fi
                else
                    echo "⚠ Folder not found: $dir"
                fi
            done
        fi
        ;;

    *)
        echo "Usage:"
        echo "  d start             Start stack"
        echo "  d stop              Stop stack"
        echo "  d restart           Restart stack"
        echo "  d ps|status         Show all containers (running + stopped)"
        echo "  d logs [svc]        Follow logs"
        echo "  d pull              Pull latest images"
        echo "  d nuke [--dry-run] Remove containers, volumes, images, orphans, and top-level host folders used by this compose"
        exit 1
        ;;
esac
