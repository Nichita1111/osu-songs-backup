# osu! Backup Tool (Songs & Skins)

A simple interactive bash script that automatically finds your osu! Songs and Skins folders and backs them up — whether you're migrating to a new distro or just want a backup.
This tool was created with help of AI so there can be plenty of bugs.

---

## ✨ Features

- 🔍 **Auto-detects** your Songs and Skins folders (osu-wine, Lutris, Flatpak, Wine, and more)
- 📦 **3 backup modes** — copy as-is, pack as `.osz`/`.osk`, or single `tar.gz`
- 📊 Shows item count and total size before backup
- 🎯 Works on any Linux distro

---

## 📋 Requirements

- `bash`
- `rsync` (for mode 1)
- `zip` (for mode 2)
- `tar` (for mode 3)

Install on Arch:
```bash
sudo pacman -S rsync zip tar
```

Install on Fedora:
```bash
sudo dnf install rsync zip tar
```

---

## 🚀 Usage

```bash
git clone https://github.com/Nichita1111/osu-songs-backup
cd osu-songs-backup
chmod +x osu_backup_merged.sh
./osu_backup_merged.sh
```

---

## 🗂️ Backup Modes

| Mode | Description | Speed | Best for |
|------|-------------|-------|----------|
| 1 | Copy folder as-is | ⚡ Fast | Migrating to new distro |
| 2 | Pack each into `.osz`/`.osk` | 🐢 Slow | Sharing items / reimporting |
| 3 | Single `tar.gz` archive | ⚡ Fast | Full backup |

---

## 🔍 Auto-detected Paths

The script checks these locations automatically:

```
~/.local/share/osu-wine/osu!/Songs
~/.local/share/osu-wine/Songs
~/Games/osu-wine/osu!/Songs
~/Games/osu!/Songs
~/.wine/drive_c/users/$USER/AppData/Local/osu!/Songs
~/.var/app/sh.ppy.osu/data/osu/Songs
~/osu!/Songs
```
(and equivalent `Skins` folders).

If none match, it does a deep `find` search and lets you pick, or enter the path manually.

---

## 🔄 Migrating to a new distro (example: Fedora → Arch)

```bash
# 1. On Fedora — run the script, choose mode 1, save to external drive
./osu_backup_merged.sh
# → choose /media/usb/osu_backup as destination

# 2. Install Arch, install osu! (osu-wine or similar)

# 3. Copy files back
rsync -av /media/usb/osu_backup/Songs/ ~/.local/share/osu-wine/osu!/Songs/
rsync -av /media/usb/osu_backup/Skins/ ~/.local/share/osu-wine/osu!/Skins/

# 4. Launch osu! — it will detect the maps and skins automatically
```

---

## 📄 License

MIT — do whatever you want with it.
