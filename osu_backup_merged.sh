#!/bin/bash

# ─────────────────────────────────────────────
#  osu! Songs & Skins Backup Script
#  Automatically finds your folders and backs them up
# ─────────────────────────────────────────────

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
RESET='\033[0m'

echo -e "${CYAN}${BOLD}"
echo "  ╔═══════════════════════════════════════╗"
echo "  ║     osu! Songs & Skins Backup Tool    ║"
echo "  ╚═══════════════════════════════════════╝"
echo -e "${RESET}"

# ── 0. Check dependencies ─────────────────────
echo -e "${YELLOW}[0/5] Checking dependencies...${RESET}"
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

# ── 1. Select what to backup ──────────────────
echo -e "\n${YELLOW}[1/5] What do you want to backup?${RESET}"
echo -e "  ${CYAN}[1]${RESET} Songs only"
echo -e "  ${CYAN}[2]${RESET} Skins only"
echo -e "  ${CYAN}[3]${RESET} Both Songs and Skins"
echo -e "  ${CYAN}[0]${RESET} Exit"
echo ""
read -r -p "  Choice [0-3]: " TARGET_CHOICE

if [[ "$TARGET_CHOICE" == "0" ]]; then
    echo -e "\n${YELLOW}  Exiting...${RESET}"
    exit 0
fi

BACKUP_SONGS=false
BACKUP_SKINS=false

if [[ "$TARGET_CHOICE" == "1" || "$TARGET_CHOICE" == "3" ]]; then BACKUP_SONGS=true; fi
if [[ "$TARGET_CHOICE" == "2" || "$TARGET_CHOICE" == "3" ]]; then BACKUP_SKINS=true; fi

if [[ "$BACKUP_SONGS" == false && "$BACKUP_SKINS" == false ]]; then
    echo -e "${RED}  ✗ Invalid choice.${RESET}"
    exit 1
fi

# ── 2. Destination ────────────────────────────
DEST="$HOME/osu_backup"
echo -e "\n${YELLOW}[2/5] Where to save?${RESET}"
echo -e "  Press Enter for default: ${CYAN}$DEST${RESET}"
read -r -p "  Destination: " USER_DEST

if [ -n "$USER_DEST" ]; then
    DEST="$USER_DEST"
fi

if ! mkdir -p "$DEST" 2>/dev/null; then
    echo -e "${RED}  ✗ Cannot create destination folder: $DEST${RESET}"
    exit 1
fi

# Function to search and return path in a global variable
find_folder() {
    local target_name=$1
    local search_paths=(
        "$HOME/.local/share/osu-wine/osu!/$target_name"
        "$HOME/.local/share/osu-wine/$target_name"
        "$HOME/Games/osu-wine/osu!/$target_name"
        "$HOME/Games/osu!/$target_name"
        "$HOME/.wine/drive_c/users/$USER/AppData/Local/osu!/$target_name"
        "$HOME/.var/app/sh.ppy.osu/data/osu/$target_name"
        "$HOME/osu!/$target_name"
    )
    
    FOUND_PATH=""
    for path in "${search_paths[@]}"; do
        if [ -d "$path" ]; then
            FOUND_PATH="$path"
            echo -e "${GREEN}  ✓ Found: $FOUND_PATH${RESET}"
            break
        fi
    done

    if [ -z "$FOUND_PATH" ]; then
        echo -e "${YELLOW}  Standard paths didn't match, searching deeper...${RESET}"
        mapfile -t found_paths < <(find "$HOME" -maxdepth 8 -type d -name "$target_name" 2>/dev/null | grep -i "osu" | head -5)

        if [ ${#found_paths[@]} -eq 0 ]; then
            echo -e "${RED}  ✗ $target_name folder not found automatically.${RESET}"
            read -r -p "  Enter path manually: " FOUND_PATH
        else
            echo -e "${GREEN}  Found the following options:${RESET}"
            for i in "${!found_paths[@]}"; do
                echo -e "  ${CYAN}[$((i+1))]${RESET} ${found_paths[$i]}"
            done
            echo -e "  ${CYAN}[0]${RESET} Enter path manually"
            echo ""
            read -r -p "  Choose [0-${#found_paths[@]}]: " choice

            if [[ "$choice" == "0" ]]; then
                read -r -p "  Enter path: " FOUND_PATH
            elif [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#found_paths[@]}" ]; then
                FOUND_PATH="${found_paths[$((choice-1))]}"
            else
                echo -e "${RED}  ✗ Invalid choice.${RESET}"
                exit 1
            fi
        fi
    fi

    if [ ! -d "$FOUND_PATH" ]; then
        echo -e "${RED}  ✗ Path does not exist: $FOUND_PATH${RESET}"
        exit 1
    fi
}

execute_backup() {
    local target_name=$1
    local source_path=$2
    local dest_path=$3
    local ext_name=$4

    echo -e "\n${YELLOW}--- Backing up $target_name ---${RESET}"
    local count=$(find "$source_path" -maxdepth 1 -mindepth 1 -type d | wc -l)
    local total_size=$(du -sh "$source_path" 2>/dev/null | cut -f1)
    echo -e "${GREEN}  ✓ Items: ${BOLD}$count${RESET}${GREEN}, Total size: ${BOLD}$total_size${RESET}"

    echo -e "\n  Choose backup mode for $target_name:"
    echo -e "  ${CYAN}[1]${RESET} Copy folder as-is         ${GREEN}(fast, recommended)${RESET}"
    echo -e "  ${CYAN}[2]${RESET} Pack each into .$ext_name           ${YELLOW}(slow, ~$count archives)${RESET}"
    echo -e "  ${CYAN}[3]${RESET} Single tar.gz archive       ${CYAN}(fast, one big file)${RESET}"
    echo ""
    read -r -p "  Choice [1/2/3]: " mode

    case $mode in
        1)
            echo -e "${YELLOW}  Copying $target_name folder...${RESET}"
            rsync -a --progress --ignore-errors "$source_path/" "$dest_path/$target_name/"
            echo -e "${GREEN}${BOLD}  ✓ Done! Copied to $dest_path/$target_name/${RESET}"
            ;;
        2)
            local pack_dir="$dest_path/packed_${target_name,,}"
            mkdir -p "$pack_dir"
            echo -e "${YELLOW}  Packing $count items into .$ext_name files...${RESET}"
            local i=0
            local errors=0
            while IFS= read -r -d '' dir; do
                local dirname=$(basename "$dir")
                local safe_name=$(echo "$dirname" | sed 's|[/\\:*?"<>|]|_|g')
                local outfile="$pack_dir/${safe_name}_${i}.$ext_name"
                (cd "$source_path" && zip -nw -r "$outfile" "$dirname" -q 2>/dev/null)
                if [ $? -eq 0 ]; then
                    ((i++))
                    printf "  \e[32m✓\e[0m [%d/%d] %s\n" "$i" "$count" "$dirname"
                else
                    ((errors++))
                    printf "  \e[31m✗\e[0m Error: %s\n" "$dirname"
                fi
            done < <(find "$source_path" -maxdepth 1 -mindepth 1 -type d -print0)
            echo -e "${GREEN}${BOLD}  ✓ Done! Packed: $i | Errors: $errors${RESET}"
            ;;
        3)
            local archive="$dest_path/osu_${target_name,,}_$(date +%Y%m%d_%H%M%S).tar.gz"
            echo -e "${YELLOW}  Creating tar.gz archive...${RESET}"
            tar -czf "$archive" -C "$(dirname "$source_path")" "$(basename "$source_path")" 2>/dev/null
            echo -e "${GREEN}${BOLD}  ✓ Archive created: $archive${RESET}"
            ;;
        *)
            echo -e "${RED}  ✗ Invalid choice. Skipping $target_name backup.${RESET}"
            ;;
    esac
}

if [ "$BACKUP_SONGS" = true ]; then
    echo -e "\n${YELLOW}[3/5] Looking for Songs folder...${RESET}"
    find_folder "Songs"
    SONGS_PATH="$FOUND_PATH"
fi

if [ "$BACKUP_SKINS" = true ]; then
    echo -e "\n${YELLOW}[4/5] Looking for Skins folder...${RESET}"
    find_folder "Skins"
    SKINS_PATH="$FOUND_PATH"
fi

echo -e "\n${YELLOW}[5/5] Executing backups...${RESET}"

if [ "$BACKUP_SONGS" = true ]; then
    execute_backup "Songs" "$SONGS_PATH" "$DEST" "osz"
fi

if [ "$BACKUP_SKINS" = true ]; then
    execute_backup "Skins" "$SKINS_PATH" "$DEST" "osk"
fi

echo -e "\n${CYAN}${BOLD}  All selected backups complete! 🎉${RESET}\n"
