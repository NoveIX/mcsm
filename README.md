# MineCraft Server Manager (MCSM)

[![Bash](https://img.shields.io/badge/Bash-4%2B-brightgreen?style=for-the-badge)](https://www.gnu.org/software/bash/) [![tmux](https://img.shields.io/badge/tmux-required-blue?style=for-the-badge)](https://github.com/tmux/tmux) [![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue?style=for-the-badge)](https://www.gnu.org/licenses/gpl-3.0)

---

## 📝 Description

**MCSM** is a lightweight Bash script for managing a Minecraft server using [tmux](https://github.com/tmux/tmux). It provides easy commands to start, stop, restart, and access the server console, with built-in EULA handling and session management.

---

## ✨ Features

- Start, stop, and restart your Minecraft server with simple commands
- Open the server console in an interactive tmux session
- Automatic EULA file creation and acceptance prompt
- Session management to prevent duplicate or missing tmux sessions
- Colorful, informative terminal output
- Beginner-friendly usage and help menu

---

## ⚙️ Requirements

- **Bash** (version 4.0 or higher recommended)
- **tmux** (must be installed and available in your PATH)
- **sed**, **grep**, **realpath** (standard on most Unix-like systems)
- Minecraft server files (including `run.sh` and `eula.txt`)

> **Note:** This script is designed for Unix-like environments (Linux, macOS, WSL). It will not run natively on Windows without a compatible shell and tmux.

---

## 🚀 Installation

1. **Install [tmux](https://github.com/tmux/tmux):**

	- On Ubuntu/Debian: `sudo apt-get install tmux`
	- On CentOS/Fedora: `sudo dnf install tmux`
	- On macOS (Homebrew): `brew install tmux`

2. **Clone or download this repository:**

	```bash
	git clone https://github.com/NoveIX/MCSM.git
	cd MCSM
	```

3. **Make the script executable:**

	```bash
	chmod +x mcsm.sh
	```

4. **Place your Minecraft server files** (including `run.sh`) in the same directory as `mcsm.sh`.

---

## 📦 Usage

Run the script with one of the following commands:

```bash
./mcsm.sh <option>
```

| Option            | Description                  |
|-------------------|-----------------------------|
| `-s`, `--start`   | Start the Minecraft server   |
| `-e`, `--exit`    | Stop the Minecraft server    |
| `-r`, `--restart` | Restart the server           |
| `-c`, `--console` | Open the server console      |
| `-h`, `--help`    | Show help message            |

---

## 📄 EULA Handling

On first run, if `eula.txt` does not exist, the script will create it with `eula=false`. If the EULA is not accepted, you will see:

```
The EULA is not accepted. Do you want to accept it now? [y/N]:
```

Type `y` and press Enter to accept the EULA. The script will update `eula.txt` to `eula=true` and continue. If you do not accept, the server will not start.

---

## 📝 Notes

- **Session Naming:** The tmux session name is automatically derived from the script directory name, sanitized for safety.
- **tmux Required:** All server management is handled via tmux. Ensure tmux is installed and accessible.
- **run.sh:** The script expects a `run.sh` file in the same directory to launch the Minecraft server.
- **Unix Shell:** This script is intended for Unix-like shells. For Windows, use WSL or a compatible environment.

---

## 📜 License

This project is licensed under the [GNU General Public License v3.0](LICENSE).

