# 📦 d — Docker Stack Power Tool

A fast, minimal command wrapper for Docker Compose stacks.  
Built for speed, safety, and clean workflows 🚀

---

## ⚡ One-Line Install

```bash
sudo curl -fsSL https://raw.githubusercontent.com/886ppak/docker-d-script/main/d -o /sbin/d && sudo chmod +x /sbin/d
```

---

## 🧭 First-Time Setup

Set your Docker workspace location (edit the path if needed).  

> **Note:** In your shell, just use a plain path — Markdown formatting like bold/underline won't work in bash.

```bash
# Edit this path to match your Docker folder
DOCKER_HOME="/home/docker"   # 🔹 Change this path to your Docker folder

# Add alias to jump to your Docker folder
echo "alias dh='cd \$DOCKER_HOME'" >> ~/.bashrc
source ~/.bashrc
```

✅ After this, just type:

```bash
dh
```

to jump into your Docker workspace.

---

## 🛠 Usage Commands

```bash
dps             # 📋 Show all containers
dup             # ▶ Start stack (docker compose up -d)
dc              # ⏹ Stop stack
dr              # 🔄 Restart stack
dl              # 📜 Follow logs
du              # ⬇ Pull latest images

dn              # 🧪 Dry-run (preview what would be deleted)
DN              # 💣 Full nuke (requires confirmation, uppercase)

d uninstall     # ⚠ Remove script and revert aliases (safe uninstall)
```

---

### 💥 Example Workflow

```bash
dh
dps
dup
dl
dn    # Preview deletion
DN    # Execute full nuke with confirmation
d uninstall  # Optional: completely remove 'd' script and aliases
```

---

### 👤 Author

Created by **@886ppak**  
Built for people who live in the terminal 🚀

---

### ✅ Notes

- **Dry-run (`dn`)** previews deletions, nothing happens until `DN` is confirmed.  
- **DN** requires typing `YES` before anything is deleted.  
- **d uninstall** safely removes `/sbin/d` and your `dh` alias in `.bashrc`.  
- Bold + underline formatting (`<u>**/home/docker**</u>`) is only for GitHub Markdown display, not bash commands.  

---

### 📝 Copy & Paste

You can safely copy each command block above and paste into your terminal or README — commands are fully ready to use.
