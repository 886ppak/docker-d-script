#!/bin/bash
# -------------------------------
# Docker Compose helper script — full commands + shortcuts
# -------------------------------

# -------------------------------
# Require Docker
# -------------------------------
if ! command -v docker &>/dev/null; then
    echo "❌ Docker not installed or not in PATH"
    exit 1
fi

# -------------------------------
# Helper functions
# -------------------------------
get_host_volumes() {
    grep -E '^[[:space:]]*- ' "$COMPOSE_FILE" | while read -r line; do
        vol=$(echo "$line" | sed 's/^- //')
        host_path=$(echo "$vol" | cut -d: -f1)
        if [[ "$host_path" = /* || "$host_path" = ./* ]]; then
            echo "$host_path"
        fi
    done
}

# -------------------------------
# Find docker-compose file in current directory
# -------------------------------
COMPOSE_FILE=""
for file in docker-compose.yml docker-compose.yaml compose.yml compose.yaml; do
    if [[ -f "$file" ]]; then
        COMPOSE_FILE="$PWD/$file"
        break
    fi
done

if [[ -z "$COMPOSE_FILE" ]]; then
    echo "❌ No docker-compose file found in $(pwd)"
    exit 1
fi

# -------------------------------
# Parse command
# -------------------------------
CMD="$1"
shift || true

# -------------------------------
# Commands mapping (shortcuts + full)
# -------------------------------
case "$CMD" in
    start|dup)
        echo "▶ Starting stack"
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
        echo "📜 Following logs (Ctrl+C to exit)"
        docker compose -f "$COMPOSE_FILE" logs -f "$@"
        ;;

    pull|du)
        echo "⬇ Pulling latest images"
        docker compose -f "$COMPOSE_FILE" pull
        ;;

    ps|status|dps)
        echo "📋 All containers on host:"
        docker ps -a
        ;;

    dn)  # 🧪 Dry-run preview
        echo "🧪 Dry-run — preview what would happen if you run DN:"
        echo "📦 Containers:"
        docker compose -f "$COMPOSE_FILE" ps --services --all | while read svc; do
            echo "  - $svc"
        done
        echo "🖼 Images:"
        docker compose -f "$COMPOSE_FILE" images -q | while read img; do
            echo "  - $img"
        done
        echo "💾 Volumes:"
        docker compose -f "$COMPOSE_FILE" config --volumes | while read vol; do
            echo "  - $vol"
        done
        echo "🗑 Host folders:"
        get_host_volumes | while read dir; do
            if [[ "$dir" = ./* ]]; then
                dir="$PWD/${dir#./}"
            fi
            if [[ -d "$dir" ]]; then
                echo "  ✅ $dir"
            else
                echo "  ⚠ $dir (not found)"
            fi
        done
        echo "📝 Dry-run complete — no changes made."
        ;;

    DN)     # 💣 Full nuke with confirmation
        echo "💣 WARNING: This will permanently remove containers, images, volumes, and host folders!"
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
        get_host_volumes | while read dir; do
            if [[ "$dir" = ./* ]]; then
                dir="$PWD/${dir#./}"
            fi
            [[ -d "$dir" ]] && echo "  ✅ $dir" || echo "  ⚠ $dir (not found)"
        done
        read -p "⚠ Type 'YES' to confirm full deletion: " confirm
        if [[ "$confirm" != "YES" ]]; then
            echo "⏹ Aborted — nothing was deleted."
            exit 1
        fi
        docker compose -f "$COMPOSE_FILE" down --volumes --rmi all --remove-orphans
        get_host_volumes | while read dir; do
            if [[ "$dir" = ./* ]]; then
                dir="$PWD/${dir#./}"
            fi
            if [[ -d "$dir" ]]; then
                echo "🗑 Removing folder: $dir"
                sudo rm -rf "$dir"
            fi
        done
        echo "✅ Full stack deleted."
        ;;

    uninstall)
        echo "⚠ Uninstalling script..."
        sudo rm -f /sbin/d
        sed -i '/# Docker d script/d' ~/.bashrc
        echo "✅ Script uninstalled!"
        ;;

    *)
        echo "❌ Unknown command: $CMD"
        echo "Usage:"
        echo "  d start|dup          # ▶ Start stack"
        echo "  d stop|dc            # ⏹ Stop stack"
        echo "  d restart|dr         # 🔄 Restart stack"
        echo "  d logs|dl [service]  # 📜 Tail logs"
        echo "  d pull|du            # ⬇ Pull latest images"
        echo "  d ps|status|dps      # 📋 Show all containers (running + stopped)"
        echo "  d dn                 # 🧪 Dry-run preview of full stack removal"
        echo "  d DN                 # 💣 Nuke with confirmation"
        echo "  d uninstall           # ❌ Remove script from system"
        exit 1
        ;;
esac
