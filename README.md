@ -30,25 +30,11 @@ to jump into your Docker workspace.
| d nuke                    |d DN    | 💣 Full nuke (requires confirmation, uppercase) |
| d uninstall               | -      | ⚠ Remove script and revert aliases (safe uninstall) |
---
### 💥 Example Workflow
dh  
d dps  
d dup  
d dl  
d dn    # Preview deletion  
d DN    # Execute full nuke with confirmation
d sh            # Root shell (default)
d sh --user     # Container’s default user
d sh --root     # Explicit root shell
d sh -u jellyfin # Specific user  
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
- `d uninstall` safely removes `/sbin/d` and your dh alias in `.bashrc`.   
---
### 📝 Copy & Paste
You can safely copy all of this block above and paste into your terminal or README — commands are fully ready to use.