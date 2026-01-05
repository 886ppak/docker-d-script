#!/bin/bash
# =========================================
# d — Docker Compose Helper (Full Rewrite)
# Features:
# - Interactive Docker workspace alias (dh)
# - Auto Bash navigation aliases .. ... .3 .4
# - d sh with user support (-u USER, --root)
# - Interactive DN folder deletion using whiptail
# - Works with Docker Compose v2
# =========================================

# ----------------------------
# Configure Docker workspace interactively (dh alias)
# ----------------------------
if ! grep -q "alias dh=" ~/.bashrc; then
    if ! command -v whiptail >/dev/null 2>&1; then
        echo "❌ whiptail not installed. Using default /home/docker"
        DOCKER_WORKSPACE="/home/docker"
    else
        DOCKER_WORKSPACE=$(whiptail --title "Docker Workspace Setup" \
            --inputbox "Enter your Docker workspace folder:" 10 60 "/home/docker" 3>&1 1>&2 2>&3)
        DOCKER_WORKSPACE=${DOCKER_WORKSPACE:-/home/docker}
    fi
    # Write alias to bashrc and activate immediately
    grep -qxF "alias dh='cd $DOCKER_WORKSPACE'" ~/.bashrc || echo "alias dh='cd $DOCKER_WORKSPACE'" >> ~/.bashrc
    alias dh="cd $DOCKER_WORKSPACE"
    echo "✅ dh alias set to $DOCKER_WORKSPACE"
else
    DOCKER_WORKSPACE=$(grep "alias dh=" ~/.bashrc | cut -d"'" -f2)
fi

# ----------------------------
# Auto add other navigation aliases
# ----------------------------
declare -A aliases=(
    [".."]="cd .."
    ["..."]="cd ../.."
    [".3"]="cd ../../.."
    [".4"]="cd ../../../.."
)

for a in "${!aliases[@]}"; do
    grep -qxF "alias $a='${aliases[$a]}'" ~/.bashrc || echo "alias $a='${aliases[$a]}'" >> ~/.bashrc
    alias $a="${aliases[$a]}"
done

# ----------------------------
# Detect docker compose file
# ----------------------------
COMPOSE_FILES=("docker-compose.yml" "docker-compose.yaml" "compose.yml" "compose.yaml")
COMPOSE_FILE=""
for f in "${COMPOSE_FILES[@]}"; do
    [[ -f "$f" ]] && COMPOSE_FILE="$f" && break
done

# ----------------------------
# Parse command
# ----------------------------
CMD="$1"
shift || true

case "$CMD" in
    uninstall)
        echo "⚠ Removing d command..."
        sudo rm -f /sbin/d
        sed -i '/alias dh=/d' ~/.bashrc
        sed -i '/alias ..=/d' ~/.bashrc
        sed -i '/alias ...=/d' ~/.bashrc
        sed -i '/alias .3=/d' ~/.bashrc
        sed -i '/alias .4=/d' ~/.bashrc
        echo "✅ d removed. Restart shell to apply."
        exit 0
        ;;
    dps|status)
        docker ps -a
        exit 0
        ;;
    dh)
        cd "$DOCKER_WORKSPACE" || { echo "❌ Cannot access $DOCKER_WORKSPACE"; exit 1; }
        pwd
        exit 0
        ;;
esac

if [[ -z "$COMPOSE_FILE" ]]; then
    echo "❌ No docker-compose file found in $(pwd)"
    exit 1
fi

# ----------------------------
# Helper: get host folders
# ----------------------------
get_host_folders() {
    grep -E '^[[:space:]]*-[[:space:]]*(\.\/|/)' "$COMPOSE_FILE" \
    | sed -E 's/.*-\s*([^:]+).*/\1/' \
    | awk -F/ '{print $1"/"$2}' \
    | sort -u
}

# ----------------------------
# d sh - shell into container
# ----------------------------
d_sh() {
    local user="root"
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --root) user="root" ;;
            -u|--user) shift; user="$1" ;;
        esac
        shift
    done

    local services
    services=$(docker compose -f "$COMPOSE_FILE" ps --services)
    [[ -z "$services" ]] && { echo "❌ No services found in $COMPOSE_FILE"; return 1; }

    local service
    if [[ $(echo "$services" | wc -l) -gt 1 ]]; then
        echo "Select service:"
        select service in $services; do
            service=$(echo "$service" | tr -d '\n')
            [[ -n "$service" ]] || continue
            break
        done
    else
        service="$services"
    fi

    if ! docker compose -f "$COMPOSE_FILE" ps -q "$service" &>/dev/null; then
        echo "⚠ Service '$service' not running. Starting..."
        docker compose -f "$COMPOSE_FILE" up -d "$service"
    fi

    docker compose exec -it -u "$user" "$service" sh
}

# ----------------------------
# Commands that require compose
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
    dn)
        echo "🧪 DRY RUN — nothing will be deleted."
        echo "Containers:"
        docker compose -f "$COMPOSE_FILE" ps --services | sed 's/^/  - /'
        echo "Folders:"
        get_host_folders | sed 's/^/  - /'
        ;;
    DN)
        echo "💣 FULL NUKE MODE"
        echo "------------------------------------"

        read -rp "Type YES to proceed: " CONFIRM
        [[ "$CONFIRM" != "YES" ]] && echo "Aborted." && exit 1

        docker compose -f "$COMPOSE_FILE" down --volumes --remove-orphans

        folders=$(get_host_folders)
        if ! command -v whiptail >/dev/null 2>&1; then
            echo "❌ whiptail not installed. Please install: sudo apt install whiptail"
            exit 1
        fi

        CHECKLIST=()
        for dir in $folders; do
            [[ -d "$dir" ]] && CHECKLIST+=("$dir" "$dir" "OFF")
        done

        SELECTED=$(whiptail --title "Select folders to delete" --checklist \
            "Use SPACE to select, ENTER to confirm" 20 78 15 \
            "${CHECKLIST[@]}" 3>&1 1>&2 2>&3)

        [[ -z "$SELECTED" ]] && echo "No folders selected. Aborting." && exit 0
        SELECTED=$(echo $SELECTED | tr -d '"')

        for dir in $SELECTED; do
            [[ -d "$dir" ]] && echo "🗑 Removing $dir" && rm -rf "$dir"
        done

        echo "✅ Selected folders removed."
        ;;
    *)
        echo "Usage:"
        echo "  d dh         → jump to Docker workspace (configurable)"
        echo "  d dup        → start stack"
        echo "  d dc         → stop stack"
        echo "  d dr         → restart stack"
        echo "  d dl         → logs"
        echo "  d du         → pull images"
        echo "  d sh         → shell into container (--root, -u USER)"
        echo "  d dn         → dry-run delete preview"
        echo "  d DN         → full interactive folder deletion"
        echo "  d uninstall  → remove script and aliases"
        ;;
esac
