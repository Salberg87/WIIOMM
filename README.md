# 🖥️ WIIOMM — What Is Installed On My Mac?

<<<<<<< HEAD
| Workflow                | Status                                                                 |
|-------------------------|------------------------------------------------------------------------|
| Inventory & Audit       | ![WIIOMM Inventory & Audit](https://github.com/Salberg87/WIIOMM/actions/workflows/inventory.yml/badge.svg) |
| Dependabot              | ![Dependabot Status](https://img.shields.io/badge/dependabot-enabled-brightgreen?logo=dependabot)         |
| Last Inventory Run      | ![Last Inventory Run](https://img.shields.io/badge/last%20inventory%20run-updating-blue)    |
=======
[![WIIOMM Inventory & Audit](https://github.com/Salberg87/WIIOMM/actions/workflows/inventory.yml/badge.svg)](https://github.com/Salberg87/WIIOMM/actions/workflows/inventory.yml)
[![Dependabot Status](https://img.shields.io/badge/dependabot-enabled-brightgreen?logo=dependabot)](https://github.com/Salberg87/WIIOMM/network/updates)
[![CodeQL](https://github.com/Salberg87/WIIOMM/actions/workflows/codeql.yml/badge.svg)](https://github.com/Salberg87/WIIOMM/security/code-scanning)
**Last Inventory Run:** 2025:05:19 21:18-05 <!--LAST_INVENTORY_RUN-->
>>>>>>> 3a7340d0c1bbbf8b8cbec9442a2e145f3f6245e2

WIIOMM is a fully automated, Git-synced system audit tool for macOS. It answers the question:

> "What is actually installed on this machine?"

Built to be leet, lightweight, and terminal-native, it generates daily reports of system packages, dev tools, and environment config — and diffs them against the last known state.

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

## 🧰 Future Upgrades

- Obsidian vault integration
- Brewfile auto-generation
- Hardware change detection
- Slack/email diff notifications
- Cross-device setup sync via dotfiles

---

## 🧠 Philosophy

> "We don't guess what's on the machine — we **track** it."

WIIOMM is your personal sysadmin and setup historian.  
Built for devs who want to **stay in control**.

---

## 💾 License

MIT — use, fork, remix.