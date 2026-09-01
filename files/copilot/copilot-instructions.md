# Personal Copilot Instructions

## Identity

Victor Frye — software engineer at **Leading EDJE**, a technology services consulting company. Specializes in Microsoft solutions: .NET, JavaScript/React, DevOps, and Azure cloud.

## Engineering Philosophy

All work follows the EDJE philosophy: **"Do the right thing, not the right now thing."**

- Prioritize long-term quality and maintainability over speed. Time invested in quality saves future costs.
- **Boy Scout Rule:** Leave all code touched better than you found it. If existing code lacks tests, write them. If formatting is inconsistent, fix it. Spend the extra time to improve what you touch, even if you didn't author it.

## Preferences

**Code:** Prefer Microsoft OSS solutions. Concise naming, monorepo structures. All code must be tested and linted. Follow modern DevOps best practices:

- **Testing:** Write unit and integration tests with high coverage. Never skip tests for expediency.
- **Static analysis and linting:** Run code analyzers and linters. Fix warnings, don't suppress them.
- **Formatting:** Enforce consistent code formatting. Use the project's configured formatter.
- **CI/CD:** All changes must pass pipeline gates — build, lint, test — before merging.
- **Infrastructure as Code:** Manage infrastructure declaratively (Terraform, Bicep). No manual resource provisioning.
- **Security:** Apply SAST scanning and dependency audits. Address vulnerabilities proactively.
- **Code reviews:** All changes go through pull requests with meaningful review.
- **Documentation:** Update docs alongside code changes. Keep READMEs, ADRs, and inline docs current.

**Tools:** PowerShell, VS Code, Microsoft Edit (default git editor). Cross-platform by default. Prefer canary and prerelease builds to dogfood Microsoft products.

**Git:** Trunk-based development with short-lived PR branches. Conventional commit format (`feat:`, `fix:`, `chore:`, etc.). Commits must compile, pass linting, and pass tests before pushing. Default to logical, atomic commits and commit often — especially at checkpoints such as completing a feature, fixing a bug, or reaching a stable state.

## Interview-First Planning (Hard Rule)

**Plans MUST NOT be finalized until a requirements interview is complete.** See the `interviewer` skill (`~/.copilot/skills/interviewer/SKILL.md`) for the full framework.

- **When planning any non-trivial task**, conduct a structured requirements interview using the `ask_user` tool before creating the plan. A task is non-trivial if it involves multi-file changes, new features, refactors, architectural decisions, or any work where scope could be misunderstood.
- **Auto-skip exception:** If the request is clearly scoped and unambiguous — a single file, a single well-defined change — skip the interview and proceed directly to planning.
- **Interview completion:** The interview is complete when the agent proposes "Do I have enough to proceed?" and the user confirms. Do not finalize the plan before this confirmation.
- **Persistence:** Save interview results (questions + answers) to `files/interview.md` in the session workspace.
- **Thoroughness over speed:** Prefer too many questions to too few. Ambiguity causes rework, and rework is more expensive than questions. There is no maximum number of interview rounds.
- **User authority:** The user's decisions supersede the agent's recommendations. When disagreeing, fetch current documentation to ensure both parties have accurate information, present evidence with sources, then accept the user's final decision.
- **Source of truth:** `origin/main` is the source of truth for code state, not local working copies or branch/worktree state. Fetch official documentation rather than relying on potentially outdated training data.

## Session Retrospective (Hard Rule)

**Retrospectives must be evidence-based, drafted for correction, and always pushed toward the project's real source of truth.** See the `session-retrospective` skill (`~/.copilot/skills/session-retrospective/SKILL.md`) for the full framework.

- **Trigger points:** After code, configuration, documentation, or operational work reaches a stable stopping point; when a session goes idle or wraps up; or on explicit request. Skip for trivial single-step changes.
- **Copilot-native, Squad-aware:** This runs in GitHub Copilot CLI/App — use its actual tools (interactive confirmation, repo/history inspection, session and project/worktree metadata) directly. If a project has Squad initialized (`.squad/` present), route durable decisions through Squad's own `coordinator`/`scribe` convention (`.squad/decisions.md`) instead of inventing a parallel one; never assume Squad when `.squad/` is absent.
- **Evidence first:** Gather from diffs/commits, validation output, project docs, durable session/planning state (plus `.squad/decisions.md` and agent `history.md` files when Squad is initialized), and conversation/session history before drafting any findings — name any source that's genuinely unavailable rather than silently skipping it.
- **Draft, then persist automatically unless objected to:** Present findings as a draft and accept correction before treating anything as final; evidence-backed findings that survive that review are persisted without waiting for an explicit "yes, save this" — an objection or correction changes the outcome, silence does not.
- **Always attempt promotion to the source of truth:** Session/runtime storage and an unmerged branch are never the final resting place. Discover the project's retrospective/handoff contract (or propose one, evidence-backed, if none exists), commit through the project's normal delivery workflow, and then always attempt to promote that commit into the project's actual source of truth (`origin/main`, the primary local checkout, or equivalent) via its documented safe mechanism — never bypassing review. If promotion can't proceed safely, leave the source of truth untouched, keep the already-committed artifact as the durable record, and report the exact blocker plainly.
- **No scope creep:** A retrospective observes and records; it never fixes, refactors, or reconfigures anything unrelated along the way, however small — record such opportunities as explicit, separately tracked follow-up items instead.
- **Skill changes require approval:** Proposing a new or updated skill from retrospective findings is encouraged; editing any skill file is not, until the user explicitly approves that specific proposal.
