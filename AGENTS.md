# Multi-Environment Development with Claude Code

Guidelines for working with Claude Code across different environments (Mac terminal, GitHub Codespaces, etc.).

---

## Key Insight: One Environment at a Time

This project enables development from anywhere:

```
At Home (Mac Terminal)          On the Move (Codespaces via iPhone/iPad)
        │                                    │
        └──────── Same Repository ───────────┘
                         │
              Continue work seamlessly
```

**Rule:** Work in ONE environment at a time. Switch environments when you change location/device - don't run both simultaneously.

---

## Why Not Simultaneous Agents?

We tested running two independent Claude Code agents simultaneously (Mac + Codespaces). Results:

| What We Tried | Result |
|---------------|--------|
| Written protocol in AGENTS.md | Agents read it but "forgot" during long tasks |
| AGENT_STATUS.md tracking | Helpful but not enforced |
| Reminders to follow protocol | Only works with manual intervention |
| Git as coordination | Caught conflicts but required manual resolution |

**Root Cause:** Two independent Claude Code sessions have no shared state. Protocol documents don't persist in agent memory across many turns. Git is the only connection, and it's reactive (catches conflicts) not proactive (prevents them).

---

## Recommended Approaches

### 1. Sequential Environment Switching (Primary Use Case)

Work in one environment, commit and push, then continue in another:

```bash
# Mac Terminal (at home)
claude
# ... work on features ...
git add -A && git commit -m "feat: partial progress" && git push

# Later, on iPhone via Codespaces
git pull origin main
claude
# ... continue the work ...
```

This is the intended workflow for this project - develop from anywhere without being tied to a specific device.

### 2. Parallel Features via Subagents (Anthropic's Recommendation)

For simultaneous work on multiple features, use ONE Claude session with background subagents:

```
Single Claude Code Session
        │
        ├── Subagent A (background) ──► Projects page
        └── Subagent B (background) ──► Contact page
        │
        └── Parent coordinates and merges
```

Example prompt:
```
Run two subagents in parallel:
1. First subagent: Create a Projects page with project cards
2. Second subagent: Create a Contact page with a form

Both should add navigation. I'll handle any conflicts when they complete.
```

**Why this works:** The parent agent manages coordination, and subagents return results to it. No git conflicts because it's a single session.

### 3. Feature Branches (For True Parallel Development)

If you must use separate environments simultaneously:

```bash
# Mac Terminal
git checkout -b feature-projects
claude
# ... work ...
git push -u origin feature-projects

# Codespaces (simultaneously)
git checkout -b feature-contact
claude
# ... work ...
git push -u origin feature-contact

# Merge via Pull Requests - conflicts resolved in PR review
```

---

## Project Setup: Enforcement Hooks

Protocol documents don't persist in agent memory. Use hooks in `.claude/settings.json` to enforce rules:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "bash -c 'if [[ \"$CLAUDE_TOOL_INPUT\" == *\"git push\"* ]]; then echo \"[Hook] Reminder: Always git pull before pushing.\"; fi; exit 0'"
          }
        ]
      }
    ]
  }
}
```

Add this after launching Claude Code in a new project:
```bash
claude
# Then: "Set up the .claude/settings.json with git push reminder hooks"
```

---

## When Switching Environments

### Leaving Current Environment

```bash
git status                    # Check for uncommitted work
git add -A
git commit -m "wip: switching environments"
git push origin main
```

### Entering New Environment

```bash
git pull origin main          # Get latest changes
git log --oneline -3          # Review recent commits
claude                        # Resume work
```

---

## Subagents Within Each Environment

Each environment can run parallel subagents internally:

```
Mac Terminal Session                    Codespaces Session
        │                                       │
   ┌────┴────┐                            ┌────┴────┐
Subagent  Subagent                    Subagent  Subagent
   A         B                           C         D
```

Use subagents for:
- Parallel research tasks
- Running tests while coding
- Code review while implementing

Example:
```
Research the auth module and the API module in parallel using subagents,
then summarize findings.
```

---

## Case Study: Projects + Contact Pages (January 2026)

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

Both features deployed successfully, but required manual conflict resolution.

### Lessons Learned

| Issue | Impact |
|-------|--------|
| Protocol not persistent | Agent A forgot to pull before pushing |
| No shared state | Each agent unaware of other's progress |
| Manual intervention needed | User had to remind agents of protocol |

**Conclusion:** Git-based coordination works but requires manual intervention. Better to use subagents within a single session for parallel features.

---

## Summary

| Scenario | Approach |
|----------|----------|
| Different locations/devices | Sequential: one environment at a time |
| Parallel features, same session | Subagents (Anthropic recommended) |
| True parallel, different people | Feature branches + PRs |
| Need to enforce protocols | Use `.claude/settings.json` hooks |

---

*This document reflects learnings from testing Claude Code in GitHub Codespaces and Mac Terminal*
