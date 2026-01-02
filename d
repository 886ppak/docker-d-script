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
        docker ps -a
        exit 0
        ;;
esac

# -------------------------------------------------
# Locate compose file
# -------------------------------------------------
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
        docker compose -f "$COMPOSE_FILE" up -d
        ;;

    dc)
        docker compose -f "$COMPOSE_FILE" down
        ;;

    dr)
        docker compose -f "$COMPOSE_FILE" down
        docker compose -f "$COMPOSE_FILE" up -d
        ;;

    dl)
        docker compose -f "$COMPOSE_FILE" logs -f "$@"
        ;;

    du)
        docker compose -f "$COMPOSE_FILE" pull
        ;;

    dn)
        echo "🧪 DRY RUN — nothing will be deleted"
        docker compose -f "$COMPOSE_FILE" ps
        docker compose -f "$COMPOSE_FILE" images
        docker compose -f "$COMPOSE_FILE" config --volumes
        echo "🗑 Top-level host folders that would be removed:"
        get_host_volumes | while read -r dir; do
            echo "  - $dir"
        done
        ;;

    DN)
        echo "💣⚠ WARNING: This will permanently remove containers, images, volumes, and host folders!"
        
        # Dry-run first
        echo "📝 Preview:"
        echo "📦 Containers to be stopped and removed:"
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

        echo "🗑 Host folders that would be removed:"
        TOP_FOLDERS=$(get_host_volumes)
        for dir in $TOP_FOLDERS; do
            [[ -d "$dir" ]] && echo "  ✅ $dir" || echo "  ⚠ $dir (not found)"
        done

        # Confirmation
        read -rp "⚠ Are you sure you want to proceed with full stack deletion? Type 'YES' to confirm: " CONFIRM
        if [[ "$CONFIRM" != "YES" ]]; then
            echo "⏹ Aborted. Nothing was deleted."
            exit 0
        fi

        # Proceed with deletion
        docker compose -f "$COMPOSE_FILE" down --volumes --remove-orphans

        for dir in $TOP_FOLDERS; do
            if [[ -d "$dir" ]]; then
                echo "🗑 Removing folder: $dir"
                sudo rm -rf "$dir"
            fi
        done

        echo "✅ Full stack deleted."
        ;;

    *)
        echo "Usage:"
        echo "  dps             Show all containers"
        echo "  dup             Start stack (docker compose up -d)"
        echo "  dc              Stop stack"
        echo "  dr              Restart stack"
        echo "  dl              Follow logs"
        echo "  du              Pull images"
        echo "  dn              Dry-run (preview deletes)"
        echo "  DN              Full nuke (requires confirmation, uppercase)"
        exit 1
        ;;
esac
