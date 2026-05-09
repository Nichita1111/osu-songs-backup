# osu-songs-backup

A simple interactive bash script that automatically finds your osu! Songs folder and backs it up — whether you're migrating to a new distro or just want a backup.
This tool was created with help of AI so there can be plenty of bugs.

---

## ✨ Features

- 🔍 **Auto-detects** your Songs folder (osu-wine, Lutris, Flatpak, Wine, and more)
- 📦 **3 backup modes** — copy as-is, pack as `.osz`, or single `tar.gz`
- 📊 Shows map count and total size before backup
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
chmod +x osu_backup.sh
./osu_backup.sh
```

---

## 🗂️ Backup Modes

| Mode | Description | Speed | Best for |
|------|-------------|-------|----------|
| 1 | Copy Songs folder | ⚡ Fast | Migrating to new distro |
| 2 | Pack each map as `.osz` | 🐢 Slow | Sharing maps / reimporting |
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

If none match, it does a deep `find` search and lets you pick, or enter the path manually.

---

## 🔄 Migrating to a new distro (example: Fedora → Arch)

```bash
# 1. On Fedora — run the script, choose mode 1, save to external drive
./osu_backup.sh
# → choose /media/usb/osu_backup as destination

# 2. Install Arch, install osu! (osu-wine or similar)

# 3. Copy Songs back
rsync -av /media/usb/osu_backup/Songs/ ~/.local/share/osu-wine/osu!/Songs/

# 4. Launch osu! — it will detect the maps automatically
```

---

## 📄 License

MIT — do whatever you want with it.
