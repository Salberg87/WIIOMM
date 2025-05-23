# 🖥️ WIIOMM — What Is Installed On My Mac?

| Metric              | Status Badge                                                                 |
|---------------------|------------------------------------------------------------------------------|
| Python              | ![Python](https://img.shields.io/endpoint?url=https://Salberg87.github.io/WIIOMM/badges.json&style=flat&label=python&query=$.python)                   |
| Node.js             | ![Node.js](https://img.shields.io/endpoint?url=https://Salberg87.github.io/WIIOMM/badges.json&style=flat&label=node.js&query=$.node)               |
| Homebrew Packages   | ![Homebrew%20Pkgs](https://img.shields.io/endpoint?url=https://Salberg87.github.io/WIIOMM/badges.json&style=flat&label=homebrew&query=$.homebrew)        |
| Homebrew Casks      | ![Casks](https://img.shields.io/endpoint?url=https://Salberg87.github.io/WIIOMM/badges.json&style=flat&label=casks&query=$.cask)                        |
| npm Global Packages | ![npm%20Pkgs](https://img.shields.io/endpoint?url=https://Salberg87.github.io/WIIOMM/badges.json&style=flat&label=npm%20global&query=$.npm)             |
| VS Code Extensions  | ![VS%20Code%20Ext](https://img.shields.io/endpoint?url=https://Salberg87.github.io/WIIOMM/badges.json&style=flat&label=vscode%20ext&query=$.vscode)   |
| Leetness            | ![Leetness](https://img.shields.io/endpoint?url=https://Salberg87.github.io/WIIOMM/badges.json&style=flat&label=leetness&query=$.leetness)            |
| Last Inventory Run  | ![Last Run](https://img.shields.io/endpoint?url=https://Salberg87.github.io/WIIOMM/badges.json&style=flat&label=last%20run&query=$.last_run)          |

---

WIIOMM is a fully automated, Git-synced system audit tool for macOS. It answers the question:

> "What is actually installed on this machine?"

Built to be lightweight, and terminal-native, it generates daily reports of system packages, dev tools, and environment config — and diffs them against the last known state.

---

## ⚙️ Features

- 📦 Full inventory of:
  - Homebrew packages & casks
  - Python + pip packages
  - Node.js + global npm modules
  - VS Code extensions
  - Xcode CLI tools
  - Launch agents, aliases, and more

- 📋 Markdown-based snapshots
- 📊 Daily diffs of installed tools
- 🧠 Smart symlink tracking (`latest.md`)
- 🔁 Auto-pushes to a private GitHub repo
- 🔐 SSH key auto-load on reboot
- 🧱 Can be bundled into portable dotfiles for new machine setup

---

## 🚀 Usage

```bash
./generate_inventory.sh
```

Or just:

```bash
wiiomm
```

> (If you've aliased it in `~/.zshrc`)

---

## 📁 Folder Structure

```
wiiomm/
├── generate_inventory.sh          # Main runner
├── inventory/
│   ├── inventory_<timestamp>.md   # System snapshot
│   ├── diff_<timestamp>.md        # Delta from previous run
│   ├── latest.md                  # Symlink to latest
│   └── diff_log.md                # (optional) Rolling changelog
├── .gitignore
├── .zshrc                         # Adds SSH auto-loader + alias
└── setup.sh                       # Future: Mac bootstrap script
```

---

## 🔒 SSH Key Persistence (Optional)

Ensures your GitHub SSH key loads after every reboot:

```zsh
# ~/.zshrc
if [ -f ~/.ssh/id_ed25519 ]; then
  eval "$(ssh-agent -s)" > /dev/null
  ssh-add -q ~/.ssh/id_ed25519
fi
```

---

## 🔁 Git Sync Setup

WIIOMM commits and pushes to the `main` branch every time the script runs.

### Remote repo setup:
```bash
git remote add origin git@github.com:YOUR_USERNAME/wiiomm.git
git push -u origin main
```

---

## 🧪 Cron Setup

To run WIIOMM daily at 09:00:

```bash
crontab -e
```

```cron
0 9 * * * /path/to/wiiomm/generate_inventory.sh >> /path/to/wiiomm/inventory/cron_log.txt 2>&1
```

---

## 🧠 Philosophy

> "We don't guess what's on the machine — we **track** it."

WIIOMM is your personal sysadmin and setup historian.  
Built for devs who want to **stay in control**.

---

## 💾 License

MIT — use, fork, remix. 