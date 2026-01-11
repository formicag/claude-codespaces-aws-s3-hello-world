# Multi-Agent Collaboration Protocol

Guidelines for multiple Claude Code instances working on the same repository concurrently.

## Scenario

```
GitHub Repository (source of truth)
       ▲           ▲           ▲
       │           │           │
   Agent 1     Agent 2     Agent N
   (Mac CLI)  (Codespaces)  (Other)
```

Multiple agents may run simultaneously - same developer on different devices, or different developers. Git is the synchronisation mechanism.

---

## Protocol

### Before Starting Work

```bash
git pull origin main
git status
git log --oneline -5
```

Check `AGENT_STATUS.md` if it exists - another agent may be working on related files.

### While Working

- Commit frequently with clear messages
- Push regularly to share progress
- Prefer working on different files to avoid conflicts
- Use feature branches for larger changes

### Before Pushing

```bash
git pull origin main          # Sync first
terraform fmt -check          # If Terraform changes
terraform validate
git add -A
git commit -m "type: description"
git push origin main
```

### Commit Message Format

```
<type>: <description>

Co-Authored-By: Claude <model> <noreply@anthropic.com>
```

Types: `feat`, `fix`, `docs`, `refactor`, `chore`, `test`

---

## Conflict Resolution

If `git pull` fails with merge conflicts:

1. Read both versions
2. Decide which to keep (or combine)
3. Edit the file to resolve
4. `git add` + `git commit`
5. Push

---

## Status Tracking (Optional)

Create `AGENT_STATUS.md` when coordinating:

```markdown
| Agent | Location | Working On | Status |
|-------|----------|------------|--------|
| 1 | Mac | Feature X | In Progress |
| 2 | Codespaces | Bug fix Y | Complete |
```

---

## Coordination Strategies

**Different files:** Agents work on separate files - no conflicts possible

**Feature branches:** Each agent works on own branch, merge via PR

**Status file:** Agents check/update `AGENT_STATUS.md` before starting

---

*For use with Claude Code instances across multiple environments*
