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

## Case Study: Projects + Contact Pages

Two agents worked simultaneously on overlapping features:

### Setup
```
Agent A (Mac Terminal)     Contact-Agent (Codespaces)
        │                           │
        └──────── GitHub ───────────┘
```

### Tasks
- **Agent A:** Add Projects page + site navigation
- **Contact-Agent:** Add Contact page + site navigation

### Overlapping Files
Both agents modified:
- `website/index.html` (navigation)
- `website/error.html` (navigation)
- `website/styles.css` (navigation + component styles)
- `terraform/website/main.tf` (new S3 objects)

### Timeline
1. Both agents started work, created `AGENT_STATUS.md`
2. Contact-Agent committed and pushed first
3. Agent A's push was rejected
4. Agent A ran `git pull`, received 5 merge conflicts
5. Agent A resolved conflicts by combining both features
6. Agent A pushed merged result
7. CI/CD deployed unified site

### Conflict Resolution Example

```diff
# website/index.html navigation - BEFORE (conflict)
<<<<<<< HEAD
    <li><a href="projects.html">Projects</a></li>
=======
    <li><a href="contact.html">Contact</a></li>
>>>>>>> origin/main

# AFTER (resolved)
    <li><a href="projects.html">Projects</a></li>
    <li><a href="contact.html">Contact</a></li>
```

### Result
Final navigation: **Home | Projects | Contact**

Both features deployed successfully. Protocol validated.

---

*For use with Claude Code instances across multiple environments*
