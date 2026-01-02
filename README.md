# 📦 d — Docker Stack Power Tool
A fast, minimal command wrapper for Docker Compose stacks. Built for speed, safety, and clean workflows 🚀
---
## ⚡ One-Line Install
```bash
sudo curl -fsSL https://raw.githubusercontent.com/886ppak/docker-d-script/main/d -o /sbin/d && sudo chmod +x /sbin/d
```
---
## 🧭 First-Time Setup
Set your Docker workspace location (edit the path if needed).  
> **Note:** In your shell, just use a plain path — Markdown formatting like bold/underline won't work in bash.
# Edit this path to match your Docker folder
DOCKER_HOME="/home/docker"   # 🔹 Change this path to your Docker folder
# Add alias to jump to your Docker folder
echo "alias dh='cd \$DOCKER_HOME'" >> ~/.bashrc
source ~/.bashrc
✅ After this, just type:
dh
to jump into your Docker workspace.
---
## 🛠 Usage Commands
| Command (all require `d`) | Alias | Description |
|---------------------------|-------|-------------|
| d dps                     | status | 📋 Show all containers (running + stopped) |
| d start                   | dup    | ▶ Start stack (docker compose up -d) |
| d stop                    | dc     | ⏹ Stop stack |
| d restart                 | dr     | 🔄 Restart stack |
| d logs [svc]              | dl     | 📜 Follow logs |
| d pull                    | du     | ⬇ Pull latest images |
| d nuke --dry-run          | dn     | 🧪 Dry-run (preview what would be deleted) |
| d nuke                    | DN     | 💣 Full nuke (requires confirmation, uppercase) |
| d uninstall               | -      | ⚠ Remove script and revert aliases (safe uninstall) |
---
### 💥 Example Workflow
dh  
d dps  
d dup  
d dl  
d dn    # Preview deletion  
d DN    # Execute full nuke with confirmation  
d uninstall  # Optional: completely remove 'd' script and aliases
---
### 👤 Author
Created by **@886ppak**  
Built for people who live in the terminal 🚀
---
### ✅ Notes
- **All commands require the `d` prefix** (`d dup`, `d dc`, `d dn`, etc.).  
- Dry-run (`d dn`) previews deletions, nothing happens until full nuke (`d DN`) is confirmed.  
- Full nuke (`d DN`) requires typing `YES` before anything is deleted.  
- `d uninstall` safely removes `/sbin/d` and your dh alias in `.bashrc`.  
- Bold + underline formatting (`<u>**/home/docker**</u>`) is only for GitHub Markdown display, not bash commands.  
---
### 📝 Copy & Paste
You can safely copy all of this block above and paste into your terminal or README — commands are fully ready to use.
