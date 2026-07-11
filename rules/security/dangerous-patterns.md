# Dangerous Patterns — Source of Truth

This file documents every pattern category that aegis security hooks intercept.
Hook scripts (`hooks/guard-*.py`) reference the descriptions here.
To add a new pattern: add it here first, then add the regex to the relevant guard script.

---

## Phase 1 (implemented)

### git-force-push
**Guard:** `hooks/guard-git-push.py`
**Triggers:** `git push --force`, `git push -f`, any `git push` with `-f` or `--force` flag
**Risk:** Rewrites remote history. Destroys commits for all collaborators on the remote branch.
**Safe alternative:** `git push --force-with-lease` — fails if the remote has commits you haven't fetched.

### rm-rf
**Guard:** `hooks/guard-dangerous-bash.py`
**Triggers:** `rm -rf`, `rm -fr`, `rm --recursive --force`, `rm --force --recursive`
**Risk:** Recursive force-delete. No undo. Data is permanently gone.
**Safe alternative:** `mv <path> /tmp/backup-$(date +%s)/` — verify first, then delete.

### git-reset-hard
**Guard:** `hooks/guard-dangerous-bash.py`
**Triggers:** `git reset --hard`
**Risk:** Discards all uncommitted changes and removes unstaged files from the working tree.
**Safe alternative:** `git stash` (recoverable) or `git reset --mixed` (keeps changes unstaged).

---

## Phase 2 (implemented)

**Guard:** `hooks/guard-phase2.py`

### git-clean
**Triggers:** `git clean -fd`, `git clean -fdx`, `git clean -fX`, `git clean -f -d`, any `-f` + `-d`/`-x`/`-X` combination
**Risk:** Permanently removes untracked or ignored files. Files not in git history are gone with no undo.
**Safe alternative:** `git clean -n` (dry run) to preview; move important files to a backup first.

### git-branch-delete-protected
**Triggers:** `git branch -D <branch>` where branch matches production patterns in `rules/security/production-scope.md`
**Risk:** Force-deletes a production branch, removing commits reachable only from that ref. Recovery requires reflog or remote backup.
**Safe alternative:** `git branch -d` (lowercase) — refuses to delete unmerged branches.

### terraform-destroy
**Triggers:** `terraform destroy`
**Risk:** Tears down ALL managed infrastructure in the current workspace. Resources may take hours to recreate.
**Safe alternative:** `terraform plan -destroy` to preview; `-target=<resource>` to destroy a specific resource only.

### kubectl-delete-namespace
**Triggers:** `kubectl delete namespace <name>`
**Risk:** Terminates ALL pods, services, deployments, and PVCs in the namespace. Stateful data may be lost.
**Safe alternative:** Scale deployments to 0 first; back up PVCs before deleting.

### docker-system-prune
**Triggers:** `docker system prune -a` / `docker system prune --all`
**Risk:** Removes ALL unused images, containers, networks, and build cache — including images for projects not currently running.
**Safe alternative:** `docker container prune` (containers only) or `docker image prune` (dangling images only); avoid `-a`.

### drop-table
**Triggers:** `DROP TABLE`, `DROP DATABASE`, `DROP SCHEMA`, `TRUNCATE`, `TRUNCATE TABLE` in any shell context
**Risk:** Permanently destroys table data or schema. Cannot be rolled back outside a transaction.
**Safe alternative:** Wrap in a transaction; take a dump first; use `DELETE WHERE` for targeted row removal.

### chmod-777
**Triggers:** `chmod -R 777`, `chmod -R 0777`, `chmod -R a+rwx`
**Risk:** Grants world read+write+execute to every file in the tree. Any user or process on the system can read, modify, or execute those files.
**Safe alternative:** `755` for directories, `644` for files, `600` for secrets; fix ownership issues with `chown`.

### secrets-in-commit
**Triggers:** `git add .env`, `git add .env.*`, `git add id_rsa`, `git add *.key`, `git add *.pem`, `git add credentials.json`, `git add *secrets*.json`; also: AWS access keys (AKIA...), Stripe keys (sk_live_...), GitHub tokens (ghp_...), PEM headers in command strings
**Risk:** Once committed and pushed, secrets in git history are compromised even if deleted in a later commit.
**Safe alternative:** Add to `.gitignore` immediately; use environment variables or a secrets manager; rotate any exposed key.

---

## Phase 2 — not implemented (future)

### git-push-direct-main
`git push origin main` (without --force) when on a production branch — should go through PR.

### migration-down-production
Running a migration `down` while `AEGIS_ENV=production` is set or on a production branch.

---

## Confirmation mechanism

When a dangerous pattern is detected, the hook returns `permissionDecision: "ask"` (exit 0 + JSON stdout). Claude Code opens a **user confirmation dialog** in the interface. The command only executes if the user approves explicitly in that dialog — Claude cannot self-approve.

The hook logs the detection to `~/.aegis/security-hook.log` as `BLOCKED_PENDING_USER`. The user's final decision (approve/deny) happens after the hook exits and is not captured in the log.
