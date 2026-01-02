# 🐳 Docker Compose Helper Script (`d`) – Cheatsheet

Quick reference for `d` — manage Docker Compose stacks with ease! ⚡  

---

## ⚡ Install

```bash
sudo curl -fsSL https://raw.githubusercontent.com/886ppak/docker-d-script/main/d -o /sbin/d && sudo chmod +x /sbin/d
```

*(Copy button available on GitHub)*

---

## 🛠 Usage Commands

```bash
d start             # ▶ Start stack
d stop              # ⏹ Stop stack
d restart           # 🔄 Restart stack
d ps | status       # 📋 Show all containers (running + stopped)
d logs [service]    # 📜 Tail logs
d pull              # ⬇ Pull latest images
d nuke [--dry-run]  # 💣 Preview deletion without touching anything
d nuke              # 💣 Execute deletion (after confirmation)
```

---

## 📝 Dry-Run Mode Example

```bash
cd /home/docker/my-stack
d nuke --dry-run
```

- Safe way to check what will be deleted before running the real `d nuke`  

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
d nuke  # confirm deletion 💣
```

---

## ✅ Safety Notes

- `--dry-run` prevents accidental data loss  
- Only removes networks created by the stack 🌐  
- Works across multiple Docker Compose projects — just `cd` into the folder and run d 🐳  

---

## 🏷 Credits

Created with ❤️ by **886ppak** & **Docki 🤖**, your friendly Docker Compose AI helper.

---

Enjoy simple, safe, and portable Docker Compose management! 🐳🎉
