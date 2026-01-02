#!/bin/bash
# -------------------------------------------------
# d — Docker Stack Helper (Short Command Edition)
# -------------------------------------------------

COMPOSE_FILES=("docker-compose.yml" "docker-compose.yaml" "compose.yml" "compose.yaml")

CMD="$1"
shift || true

# -------------------------------------------------
# Global commands (no compose required)
# -------------------------------------------------
case "$CMD" in
    ps|dps)
        echo "📋 Showing all containers on host:"
        docker ps -a
        exit 0
        ;;
esac

# -------------------------------------------------
# Locate docker-compose file
# -------------------------------------------------
COMPOSE_FILE=""
for f in "${COMPOSE_FILES[@]}"; do
    [[ -f "$f" ]] && COMPOSE_FILE="$f" && break
done

if [[ -z "$COMPOSE_FILE" ]]; then
    echo "❌ No docker-compose file found in $(pwd)"
    exit 1
fi

# -------------------------------------------------
# Helper: Get top-level host folders from volumes
# -------------------------------------------------
get_host_volumes() {
    docker compose -f "$COMPOSE_FILE" config --volumes | while read -r vol; do
        host_path=$(echo "$vol" | cut -d: -f1)
        [[ "$host_path" = /* || "$host_path" = ./* ]] && echo "$host_path"
    done | sort -u
}

# -------------------------------------------------
# Main command router
# -------------------------------------------------
case "$CMD" in

    dup)
        echo "▶ Starting stack..."
        docker compose -f "$COMPOSE_FILE" up -d
        ;;

    dc)
        echo "⏹ Stopping stack..."
        docker compose -f "$COMPOSE_FILE" down
        ;;

    dr)
        echo "🔄 Restarting stack..."
        docker compose -f "$COMPOSE_FILE" down
        docker compose -f "$COMPOSE_FILE" up -d
        ;;

    dl)
        echo "📜 Following logs (Ctrl+C to exit)..."
        docker compose -f "$COMPOSE_FILE" logs -f "$@"
        ;;

    du)
        echo "⬇ Pulling latest images..."
        docker compose -f "$COMPOSE_FILE" pull
        ;;

    dn)
        echo "🧪 Dry-run — preview what would be deleted:"
        echo "📦 Containers:"
        docker compose -f "$COMPOSE_FILE" ps
        echo "🖼 Images:"
        docker compose -f "$COMPOSE_FILE" images
        echo "💾 Volumes:"
        docker compose -f "$COMPOSE_FILE" config --volumes
        echo "🗑 Top-level host folders:"
        get_host_volumes | while read -r dir; do
            [[ -d "$dir" ]] && echo "  ✅ $dir" || echo "  ⚠ $dir (not found)"
        done
        ;;

    DN)
        echo "💣⚠ WARNING: This will permanently remove containers, images, volumes, and host folders!"
        
        # Dry-run preview
        echo "📝 Preview:"
        echo "📦 Containers to be stopped:"
        docker compose -f "$COMPOSE_FILE" ps --services --all | while read svc; do
            echo "  - $svc"
        done

        echo "🖼 Images to be removed:"
        docker compose -f "$COMPOSE_FILE" images -q | while read img; do
            echo "  - $img"
        done

        echo "💾 Volumes to be removed:"
        docker compose -f "$COMPOSE_FILE" config --volumes | while read vol; do
            echo "  - $vol"
        done

        echo "🗑 Host folders to be removed:"
        TOP_FOLDERS=$(get_host_volumes)
        for dir in $TOP_FOLDERS; do
            [[ -d "$dir" ]] && echo "  ✅ $dir" || echo "  ⚠ $dir (not found)"
        done

        # Confirmation
        read -rp "⚠ Type 'YES' to confirm full deletion: " CONFIRM
        if [[ "$CONFIRM" != "YES" ]]; then
            echo "⏹ Aborted. Nothing was deleted."
            exit 0
        fi

        # Delete stack
        docker compose -f "$COMPOSE_FILE" down --volumes --remove-orphans

        # Remove host folders
        for dir in $TOP_FOLDERS; do
            if [[ -d "$dir" ]]; then
                echo "🗑 Removing folder: $dir"
                sudo rm -rf "$dir"
            fi
        done

        echo "✅ Full stack deleted."
        ;;

    uninstall)
        SCRIPT_PATH=$(realpath "$0")
        echo "🗑 This will remove the 'd' script at: $SCRIPT_PATH"
        echo "🗑 This will also remove your 'dh' alias and DOCKER_HOME from ~/.bashrc"

        read -rp "⚠ Type YES to confirm uninstall and revert all changes: " CONFIRM
        if [[ "$CONFIRM" != "YES" ]]; then
            echo "⏹ Aborted. Nothing was deleted."
            exit 0
        fi

        echo "🗑 Removing the 'd' script..."
        sudo rm -f "$SCRIPT_PATH"

        echo "🗑 Removing aliases and DOCKER_HOME from ~/.bashrc..."
        sed -i '/alias dh=/d' ~/.bashrc
        sed -i '/DOCKER_HOME=/d' ~/.bashrc
        source ~/.bashrc

        echo "✅ 'd' script and all related changes have been reverted!"
        exit 0
        ;;

    *)
        echo "Usage:"
        echo "  dps             Show all containers"
        echo "  dup             Start stack (docker compose up -d)"
        echo "  dc              Stop stack"
        echo "  dr              Restart stack"
        echo "  dl              Follow logs"
        echo "  du              Pull latest images"
        echo "  dn              Dry-run (preview deletes)"
        echo "  DN              Full nuke (requires confirmation, uppercase)"
        echo "  d uninstall     Remove script and revert aliases"
        exit 1
        ;;
esac
