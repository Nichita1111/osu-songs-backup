#!/bin/bash

# ─────────────────────────────────────────────
#  osu! Songs Backup Script
#  Automatically finds your Songs folder and backs it up
# ─────────────────────────────────────────────

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

echo -e "${CYAN}${BOLD}"
echo "  ╔═══════════════════════════════════════╗"
echo "  ║       osu! Songs Backup Tool          ║"
echo "  ╚═══════════════════════════════════════╝"
echo -e "${RESET}"

# ── 0. Check dependencies ─────────────────────
echo -e "${YELLOW}[0/4] Checking dependencies...${RESET}"
MISSING=()
command -v rsync &>/dev/null || MISSING+=("rsync")
command -v zip   &>/dev/null || MISSING+=("zip")
command -v tar   &>/dev/null || MISSING+=("tar")
command -v find  &>/dev/null || MISSING+=("findutils")

if [ ${#MISSING[@]} -gt 0 ]; then
    echo -e "${RED}  ✗ Missing dependencies: ${MISSING[*]}${RESET}"
    echo -e "${YELLOW}  Install on Arch/Garuda:   sudo pacman -S ${MISSING[*]}${RESET}"
    echo -e "${YELLOW}  Install on Fedora:        sudo dnf install ${MISSING[*]}${RESET}"
    echo -e "${YELLOW}  Install on Debian/Ubuntu: sudo apt install ${MISSING[*]}${RESET}"
    exit 1
fi
echo -e "${GREEN}  ✓ All dependencies found${RESET}"

# ── 1. Find Songs folder ──────────────────────
echo -e "\n${YELLOW}[1/4] Looking for Songs folder...${RESET}"

SONGS_PATH=""

SEARCH_PATHS=(
    "$HOME/.local/share/osu-wine/osu!/Songs"
    "$HOME/.local/share/osu-wine/Songs"
    "$HOME/Games/osu-wine/osu!/Songs"
    "$HOME/Games/osu!/Songs"
    "$HOME/.wine/drive_c/users/$USER/AppData/Local/osu!/Songs"
    "$HOME/.var/app/sh.ppy.osu/data/osu/Songs"
    "$HOME/osu!/Songs"
)

for path in "${SEARCH_PATHS[@]}"; do
    if [ -d "$path" ]; then
        SONGS_PATH="$path"
        echo -e "${GREEN}  ✓ Found: $SONGS_PATH${RESET}"
        break
    fi
done

# Deep search if not found
if [ -z "$SONGS_PATH" ]; then
    echo -e "${YELLOW}  Standard paths didn't match, searching deeper...${RESET}"
    mapfile -t FOUND_PATHS < <(find "$HOME" -maxdepth 8 -type d -name "Songs" 2>/dev/null | grep -i "osu" | head -5)

    if [ ${#FOUND_PATHS[@]} -eq 0 ]; then
        echo -e "${RED}  ✗ Songs folder not found automatically.${RESET}"
        echo -e "${YELLOW}  Enter path manually: ${RESET}"
        read -r SONGS_PATH
    else
        echo -e "${GREEN}  Found the following options:${RESET}"
        for i in "${!FOUND_PATHS[@]}"; do
            echo -e "  ${CYAN}[$((i+1))]${RESET} ${FOUND_PATHS[$i]}"
        done
        echo -e "  ${CYAN}[0]${RESET} Enter path manually"
        echo ""
        read -r -p "  Choose [0-${#FOUND_PATHS[@]}]: " choice

        if [[ "$choice" == "0" ]]; then
            echo -e "  Enter path: "
            read -r SONGS_PATH
        elif [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#FOUND_PATHS[@]}" ]; then
            SONGS_PATH="${FOUND_PATHS[$((choice-1))]}"
        else
            echo -e "${RED}  ✗ Invalid choice.${RESET}"
            exit 1
        fi
    fi
fi

# Validate path
if [ ! -d "$SONGS_PATH" ]; then
    echo -e "${RED}  ✗ Path does not exist: $SONGS_PATH${RESET}"
    exit 1
fi

# ── 2. Count maps ─────────────────────────────
echo -e "\n${YELLOW}[2/4] Counting maps...${RESET}"
MAP_COUNT=$(find "$SONGS_PATH" -maxdepth 1 -mindepth 1 -type d | wc -l)
SONGS_SIZE=$(du -sh "$SONGS_PATH" 2>/dev/null | cut -f1)
echo -e "${GREEN}  ✓ Maps: ${BOLD}$MAP_COUNT${RESET}${GREEN}, Total size: ${BOLD}$SONGS_SIZE${RESET}"

# ── 3. Choose backup mode ─────────────────────
echo -e "\n${YELLOW}[3/4] Choose backup mode:${RESET}"
echo -e "  ${CYAN}[1]${RESET} Copy Songs folder as-is         ${GREEN}(fast, recommended)${RESET}"
echo -e "  ${CYAN}[2]${RESET} Pack each map as .osz            ${YELLOW}(slow, ~$MAP_COUNT archives)${RESET}"
echo -e "  ${CYAN}[3]${RESET} Single tar.gz archive            ${CYAN}(fast, one big file)${RESET}"
echo ""
read -r -p "  Choice [1/2/3]: " MODE

if [[ ! "$MODE" =~ ^[1-3]$ ]]; then
    echo -e "${RED}  ✗ Invalid choice.${RESET}"
    exit 1
fi

# ── 4. Destination ────────────────────────────
echo -e "\n${YELLOW}[4/4] Where to save?${RESET}"
echo -e "  Press Enter for default: ${CYAN}$HOME/osu_backup${RESET}"
read -r -p "  Destination: " DEST

if [ -z "$DEST" ]; then
    DEST="$HOME/osu_backup"
fi

if ! mkdir -p "$DEST" 2>/dev/null; then
    echo -e "${RED}  ✗ Cannot create destination folder: $DEST${RESET}"
    exit 1
fi

# ── Execute ───────────────────────────────────
echo ""
echo -e "${CYAN}${BOLD}  Starting backup...${RESET}"
echo -e "  Source:      ${CYAN}$SONGS_PATH${RESET}"
echo -e "  Destination: ${CYAN}$DEST${RESET}"
echo ""

case $MODE in
    1)
        echo -e "${YELLOW}  Copying Songs folder...${RESET}"
        rsync -a --progress --ignore-errors "$SONGS_PATH/" "$DEST/Songs/"
        EXIT_CODE=$?
        if [ $EXIT_CODE -eq 0 ]; then
            echo -e "\n${GREEN}${BOLD}  ✓ Done! Songs folder copied to:${RESET}"
        else
            echo -e "\n${YELLOW}${BOLD}  ⚠ Done with some errors (exit code $EXIT_CODE). Most files were copied.${RESET}"
        fi
        echo -e "  ${CYAN}$DEST/Songs/${RESET}"
        echo -e "\n${YELLOW}  On Garuda/Arch: place this folder in your osu! Songs directory and launch the game.${RESET}"
        ;;

    2)
        OSZ_DIR="$DEST/osz_maps"
        mkdir -p "$OSZ_DIR"
        echo -e "${YELLOW}  Packing $MAP_COUNT maps into .osz files...${RESET}\n"

        COUNT=0
        ERRORS=0
        while IFS= read -r -d '' dir; do
            dirname=$(basename "$dir")

            # Sanitize filename for .osz using sed (avoids tr bracket interpretation issues)
            safe_name=$(echo "$dirname" | sed 's|[/\\:*?"<>|]|_|g')

            # Append index to avoid collisions between sanitized names
            outfile="$OSZ_DIR/${safe_name}_${COUNT}.osz"

            # zip -nw disables wildcard/glob expansion for special chars like []
            (cd "$SONGS_PATH" && zip -nw -r "$outfile" "$dirname" -q 2>/dev/null)

            if [ $? -eq 0 ]; then
                ((COUNT++))
                printf "  \e[32m✓\e[0m [%d/%d] %s\n" "$COUNT" "$MAP_COUNT" "$dirname"
            else
                ((ERRORS++))
                printf "  \e[31m✗\e[0m Error: %s\n" "$dirname"
            fi
        done < <(find "$SONGS_PATH" -maxdepth 1 -mindepth 1 -type d -print0)

        echo -e "\n${GREEN}${BOLD}  ✓ Done!${RESET}"
        echo -e "  Packed: ${GREEN}$COUNT${RESET} | Errors: ${RED}$ERRORS${RESET}"
        echo -e "  .osz files saved to: ${CYAN}$OSZ_DIR/${RESET}"
        ;;

    3)
        ARCHIVE="$DEST/osu_songs_$(date +%Y%m%d_%H%M%S).tar.gz"
        echo -e "${YELLOW}  Creating tar.gz archive...${RESET}"
        tar -czf "$ARCHIVE" -C "$(dirname "$SONGS_PATH")" "$(basename "$SONGS_PATH")" 2>/dev/null
        EXIT_CODE=$?
        if [ $EXIT_CODE -eq 0 ]; then
            echo -e "\n${GREEN}${BOLD}  ✓ Archive created:${RESET}"
        else
            echo -e "\n${YELLOW}${BOLD}  ⚠ Archive created with some warnings:${RESET}"
        fi
        echo -e "  ${CYAN}$ARCHIVE${RESET}"
        ARCH_SIZE=$(du -sh "$ARCHIVE" 2>/dev/null | cut -f1)
        echo -e "  Archive size: ${BOLD}$ARCH_SIZE${RESET}"
        ;;
esac

echo ""
echo -e "${CYAN}${BOLD}  Backup complete! 🎵${RESET}"
echo ""
