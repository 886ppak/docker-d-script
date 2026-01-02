# 📦 d — Docker Stack Power Tool

A fast, minimal command wrapper for Docker Compose stacks.  
Built for speed, safety, and clean workflows 🚀

---

## ⚡ One-Line Install

```bash
sudo curl -fsSL https://raw.githubusercontent.com/886ppak/docker-d-script/main/d -o /sbin/d && sudo chmod +x /sbin/d
```

---

## 🧭 First-Time Setup (Required)

Set your Docker workspace location (edit the path if needed):

```bash
DOCKER_HOME="<u>**/home/docker**</u>"  # 🔹 Change this path to your Docker folder
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
```

---

### 👤 Author

Created by **@886ppak**  
Built for people who live in the terminal 🚀

