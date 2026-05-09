#!/bin/bash

# ─────────────────────────────────────────────
#  osu! Songs Backup Script
#  Автоматически находит папку Songs и переносит
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

# ── 1. Поиск папки Songs ──────────────────────
echo -e "${YELLOW}[1/4] Ищу папку Songs...${RESET}"

SONGS_PATH=""

# Стандартные пути (osu-wine, lutris, bottles, flatpak)
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
        echo -e "${GREEN}  ✓ Найдено: $SONGS_PATH${RESET}"
        break
    fi
done

# Если не найдено — ищем через find
if [ -z "$SONGS_PATH" ]; then
    echo -e "${YELLOW}  Стандартные пути не подошли, ищу глубже...${RESET}"
    FOUND=$(find "$HOME" -maxdepth 8 -type d -name "Songs" 2>/dev/null | grep -i "osu" | head -5)

    if [ -z "$FOUND" ]; then
        echo -e "${RED}  ✗ Папка Songs не найдена автоматически.${RESET}"
        echo -e "${YELLOW}  Введи путь вручную:${RESET} "
        read -r SONGS_PATH
    else
        echo -e "${GREEN}  Найдено несколько вариантов:${RESET}"
        i=1
        while IFS= read -r line; do
            echo -e "  ${CYAN}[$i]${RESET} $line"
            FOUND_PATHS[$i]="$line"
            ((i++))
        done <<< "$FOUND"

        echo -e "\n  Выбери номер (или 0 для ручного ввода): "
        read -r choice

        if [ "$choice" == "0" ]; then
            echo -e "  Введи путь: "
            read -r SONGS_PATH
        else
            SONGS_PATH="${FOUND_PATHS[$choice]}"
        fi
    fi
fi

# Проверка
if [ ! -d "$SONGS_PATH" ]; then
    echo -e "${RED}  ✗ Путь не существует: $SONGS_PATH${RESET}"
    exit 1
fi

# ── 2. Подсчёт карт ──────────────────────────
echo -e "\n${YELLOW}[2/4] Считаю карты...${RESET}"
MAP_COUNT=$(find "$SONGS_PATH" -maxdepth 1 -mindepth 1 -type d | wc -l)
SONGS_SIZE=$(du -sh "$SONGS_PATH" 2>/dev/null | cut -f1)
echo -e "${GREEN}  ✓ Карт: ${BOLD}$MAP_COUNT${RESET}${GREEN}, Размер: ${BOLD}$SONGS_SIZE${RESET}"

# ── 3. Выбор режима бэкапа ───────────────────
echo -e "\n${YELLOW}[3/4] Выбери режим бэкапа:${RESET}"
echo -e "  ${CYAN}[1]${RESET} Скопировать папку Songs как есть ${GREEN}(быстро, рекомендуется)${RESET}"
echo -e "  ${CYAN}[2]${RESET} Упаковать каждую карту в .osz ${YELLOW}(медленно, ~$MAP_COUNT архивов)${RESET}"
echo -e "  ${CYAN}[3]${RESET} Один большой tar.gz архив"
echo ""
read -r -p "  Выбор [1/2/3]: " MODE

# ── 4. Куда сохранять ────────────────────────
echo -e "\n${YELLOW}[4/4] Куда сохранить? ${RESET}"
echo -e "  Введи путь (Enter = ${CYAN}$HOME/osu_backup${RESET}): "
read -r DEST

if [ -z "$DEST" ]; then
    DEST="$HOME/osu_backup"
fi

mkdir -p "$DEST"

# ── Выполнение ───────────────────────────────
echo ""
echo -e "${CYAN}${BOLD}  Начинаю бэкап...${RESET}"
echo -e "  Источник: ${CYAN}$SONGS_PATH${RESET}"
echo -e "  Назначение: ${CYAN}$DEST${RESET}"
echo ""

case $MODE in
    1)
        echo -e "${YELLOW}  Копирую папку Songs...${RESET}"
        rsync -av --progress "$SONGS_PATH/" "$DEST/Songs/"
        echo -e "\n${GREEN}${BOLD}  ✓ Готово! Папка Songs скопирована в:${RESET}"
        echo -e "  ${CYAN}$DEST/Songs/${RESET}"
        echo -e "\n${YELLOW}  На Garuda Mokka: положи эту папку в Songs директорию osu! и запусти игру.${RESET}"
        ;;

    2)
        OSZ_DIR="$DEST/osz_maps"
        mkdir -p "$OSZ_DIR"
        echo -e "${YELLOW}  Упаковываю $MAP_COUNT карт в .osz...${RESET}\n"

        COUNT=0
        ERRORS=0
        while IFS= read -r -d '' dir; do
            dirname=$(basename "$dir")
            # Sanitize filename: replace special chars with _ for the .osz filename
            safe_name=$(echo "$dirname" | tr '[][*?:\\/<>"|{}]' '_')
            outfile="$OSZ_DIR/${safe_name}.osz"
            # Use -nw (no wildcards) to prevent glob expansion on special chars
            (cd "$SONGS_PATH" && zip -nw -r "$outfile" "$dirname" -q)
            if [ $? -eq 0 ]; then
                ((COUNT++))
                echo -ne "  ${GREEN}✓${RESET} [$COUNT/$MAP_COUNT] $dirname\r"
            else
                ((ERRORS++))
                echo -e "  ${RED}✗${RESET} Ошибка: $dirname"
            fi
        done < <(find "$SONGS_PATH" -maxdepth 1 -mindepth 1 -type d -print0)

        echo -e "\n\n${GREEN}${BOLD}  ✓ Готово!${RESET}"
        echo -e "  Упаковано: ${GREEN}$COUNT${RESET} | Ошибок: ${RED}$ERRORS${RESET}"
        echo -e "  Файлы .osz в: ${CYAN}$OSZ_DIR/${RESET}"
        ;;

    3)
        ARCHIVE="$DEST/osu_songs_$(date +%Y%m%d_%H%M%S).tar.gz"
        echo -e "${YELLOW}  Создаю архив tar.gz...${RESET}"
        tar -czf "$ARCHIVE" -C "$(dirname "$SONGS_PATH")" "$(basename "$SONGS_PATH")" \
            --checkpoint=100 --checkpoint-action=echo="  Обработано %{r}T"
        echo -e "\n${GREEN}${BOLD}  ✓ Архив создан:${RESET}"
        echo -e "  ${CYAN}$ARCHIVE${RESET}"
        ARCH_SIZE=$(du -sh "$ARCHIVE" | cut -f1)
        echo -e "  Размер архива: ${BOLD}$ARCH_SIZE${RESET}"
        ;;

    *)
        echo -e "${RED}  Неверный выбор.${RESET}"
        exit 1
        ;;
esac

echo ""
echo -e "${CYAN}${BOLD}  Бэкап завершён! 🎵${RESET}"
echo ""
