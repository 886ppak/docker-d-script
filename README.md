# 📦 d — Docker Stack Power Tool
A fast, minimal command wrapper for Docker Compose stacks. Built for speed, safety, and clean workflows 🚀
---

## 🧭 First-Time Setup 2 steps
Set your Docker workspace location (edit the path if needed).  

Change `/home/docker` after pasting script below in interactive window to wherever you keep your Docker container compose folders are kept .

## Step 1
```bash
sudo curl -fsSL https://raw.githubusercontent.com/886ppak/docker-d-script/main/d -o /sbin/d && sudo chmod +x /sbin/d && /sbin/d
```
error will appear but script is working fine script is expecting a compose file in same location for other d commands
❌ No docker-compose file found in /root

## Step 2
```bash
source ~/.bashrc
```
---

✅ After this, just type:
```bash
dh
```
to jump into your Docker workspace.
---

## 🛠 Usage Commands
| Command (all require `d`)       | Alias  | Description |
|--------------------------------|--------|-------------|
| d dps                           | status | 📋 Show all containers (running + stopped) |
| d start                         | dup    | ▶ Start stack (`docker compose up -d`) |
| d stop                          | dc     | ⏹ Stop stack |
| d restart                       | dr     | 🔄 Restart stack |
| d logs [svc]                    | dl     | 📜 Follow logs of a service |
| d pull                          | du     | ⬇ Pull latest images |
| d sh [--root|--user|-u USER]    | -      | 🐚 Shell into a container (auto service detection, interactive menu if multiple) |
| d dn                            | -      | 🧪 Dry-run — preview what would be deleted |
| d DN                            | -      | 💣 Full nuke — deletes stack + volumes + folders (requires confirmation) |
| d uninstall                     | -      | ⚠ Remove script and revert aliases (safe uninstall) |
---

### 📝 `d sh` Examples
```bash
d sh            # Root shell (default)
d sh --user     # Container’s default user
d sh --root     # Explicit root shell
d sh -u jellyfin # Specific user
```
- Automatically detects the compose file in the current folder  
- Auto-selects a service if multiple are running  
- Bash → sh fallback for lightweight containers (Alpine, Debian, etc.)
---

### ✅ Notes
- **All commands require the `d` prefix** (`d dup`, `d dc`, `d dn`, etc.)  
- Dry-run (`d dn`) previews deletions — nothing happens until full nuke (`d DN`) is confirmed  
- Full nuke (`d DN`) requires typing `YES` before anything is deleted  
- `d uninstall` safely removes `/sbin/d` and your dh alias in `.bashrc`  
- `d sh` now allows selecting root or user shells without typing service names manually
---

### 📝 Copy & Paste
You can safely select all of this block above and paste into your terminal or README — commands are fully ready to use.
