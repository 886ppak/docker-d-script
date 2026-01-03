# 📦 d — Docker Stack Power Tool
A fast, minimal command wrapper for Docker Compose stacks. Built for speed, safety, and clean workflows 🚀
---
# ⚡ One-Line Install
```bash
sudo curl -fsSL https://raw.githubusercontent.com/886ppak/docker-d-script/main/d -o /sbin/d && sudo chmod +x /sbin/d
```
---
# 🧭 First-Time Setup
Set your Docker workspace location (edit the path if needed).
# Edit this path to match your Docker folder
```bash
echo "alias dh='cd /home/docker'" >> ~/.bashrc && source ~/.bashrc
```
Change /home/docker to where you keep you docker container folders
✅ After this, just type:
dh
to jump into your Docker workspace.
---
## 🛠 Usage Commands
| Command (all require `d`) | Alias | Description |
|---------------------------|-------|-------------|
| d dps                     | status | 📋 Show all containers (running + stopped) |
| d start                   |d dup   | ▶ Start stack (docker compose up -d) |
| d stop                    |d dc    | ⏹ Stop stack |
| d restart                 |d dr    | 🔄 Restart stack |
| d logs [svc]              |d dl    | 📜 Follow logs |
| d pull                    |d du    | ⬇ Pull latest images |
| d nuke --dry-run          |d dn    | 🧪 Dry-run (preview what would be deleted) |
| d nuke                    |d DN    | 💣 Full nuke (requires confirmation, uppercase) |
| d uninstall               | -      | ⚠ Remove script and revert aliases (safe uninstall) |
---
### ✅ Notes
- **All commands require the `d` prefix** (`d dup`, `d dc`, `d dn`, etc.).  
- Dry-run (`d dn`) previews deletions, nothing happens until full nuke (`d DN`) is confirmed.  
- Full nuke (`d DN`) requires typing `YES` before anything is deleted.  
- `d uninstall` safely removes `/sbin/d` and your dh alias in `.bashrc`.   
---
### 📝 Copy & Paste
You can safely copy all of this block above and paste into your terminal or README — commands are fully ready to use.
