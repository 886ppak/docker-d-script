# 🐳 Docker Compose Helper Script (`d`) – Quick Start

`d` is a lightweight Bash script to manage Docker Compose stacks easily.  
Start, stop, restart, pull images, view status/logs, or safely “nuke” a stack — all from one command. ⚡

---

## ⚡ Install

Run this one-liner to download the script and make it executable:

```bash
sudo curl -fsSL https://raw.githubusercontent.com/886ppak/docker-d-script/main/d -o /sbin/d && sudo chmod +x /sbin/d
```

---

## 🛠 Usage

```bash
d start             # ▶ Start stack
d stop              # ⏹ Stop stack
d restart           # 🔄 Restart stack
d ps | status       # 📋 Show all containers on host
d logs [service]    # 📜 Tail logs
d pull              # ⬇ Pull latest images
d nuke [--dry-run]  # 💣 Remove containers, volumes, images, networks, and top-level host folders
```

---

## 📝 Dry-Run Mode

```bash
cd /home/docker/my-stack
d nuke --dry-run
```

- Shows containers, images, volumes, networks, and host folders that would be removed  
- Prompts before deleting any top-level host folder ⚠️✅

---

## 🚀 Quick Example

```bash
cd /home/docker/termix
d start
d ps
d logs termix
d pull
d stop
d nuke --dry-run
d nuke  # execute after confirmation 💣
```

---

## ✅ Safety Notes

- `--dry-run` ensures you never delete data accidentally  
- Only networks created by the stack are removed; existing networks remain intact 🌐  
- Works with multiple Docker Compose stacks — just cd into the project directory and run d 🐳

---

Enjoy simple, safe, and portable Docker Compose management! 🐳🎉
