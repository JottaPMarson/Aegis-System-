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

## Phase 2 (planned — not yet implemented)

### git-clean
`git clean -fd`, `git clean -fdx` — removes untracked files and directories.

### git-branch-delete-protected
`git branch -D <protected>` — force-deletes a branch matching production-scope patterns.

### git-push-direct-main
`git push origin main` (without --force) when on a production branch — should go through PR.

### terraform-destroy
`terraform destroy` — tears down all managed infrastructure.

### kubectl-delete-namespace
`kubectl delete namespace <name>` — removes all resources in a namespace.

### docker-system-prune
`docker system prune -a` — removes all images, containers, volumes, and networks.

### drop-table
`DROP TABLE`, `DROP DATABASE`, `TRUNCATE` in any SQL context.

### migration-down-production
Running a migration `down` while `AEGIS_ENV=production` is set or on a production branch.

### secrets-in-commit
`git add .env`, `git commit` with patterns matching API keys, tokens, private keys.

### chmod-777
`chmod -R 777` — opens all permissions recursively.

---

## Override mechanism

Any blocked command can be explicitly allowed by prepending `AEGIS_ALLOW=1`:
```
AEGIS_ALLOW=1 git push --force origin main
```
The hook allows it through and logs `ALLOWED | override` to `~/.aegis/security-hook.log`.
This forces the user to consciously type the override — it cannot happen silently.
