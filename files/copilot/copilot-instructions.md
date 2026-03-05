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

**Tools:** PowerShell, VS Code. Cross-platform by default. Prefer canary and prerelease builds to dogfood Microsoft products.

**Git:** Trunk-based development with short-lived PR branches. Conventional commit format (`feat:`, `fix:`, `chore:`, etc.). Commits must compile, pass linting, and pass tests before pushing. Default to logical, atomic commits and commit often — especially at checkpoints such as completing a feature, fixing a bug, or reaching a stable state.

## Device Repo Map

All repositories are cloned under `$env:REPOS_ROOT` (typically `<DEVDRIVE>\Source\Repos`).

### Personal — GitHub (`victorfrye`)

| Repo | Description |
|------|-------------|
| DotCom | Personal website |
| Dotfiles | Dev environment configuration |
| MicrosoftGraveyard | OSS project |
| ShrugMan | OSS project |
| MockingMirror | OSS project |
| Counter | OSS project |

### Company — GitHub (`<org>`)

<!-- Replace with your company's GitHub org and repo details -->

| Repo | Description |
|------|-------------|
| <!-- Repo name --> | <!-- Description --> |

### Client — Azure DevOps (`<org>`)

<!-- Replace with your active client's Azure DevOps org and repo details -->
<!-- Shared repos (e.g., Common, DevOps.Common) are cross-repo dependencies within this org -->

| Repo | Description |
|------|-------------|
| <!-- Repo name --> | <!-- Description --> |

## Cross-Repo Boundary Rules

- Implementations must only depend on code within the **same client/org**
- Code from other orgs may be referenced for **patterns only** — never imported or depended upon
- Shared repos within a client org are valid dependencies for all repos in that org

## Interview-First Planning (Hard Rule)

**Plans MUST NOT be finalized until a requirements interview is complete.** See the `interviewer` agent definition (`~/.copilot/agents/interviewer.agent.md`) for the full framework.

- **When planning any non-trivial task**, conduct a structured requirements interview using the `ask_user` tool before creating the plan. A task is non-trivial if it involves multi-file changes, new features, refactors, architectural decisions, or any work where scope could be misunderstood.
- **Auto-skip exception:** If the request is clearly scoped and unambiguous — a single file, a single well-defined change — skip the interview and proceed directly to planning.
- **Interview completion:** The interview is complete when the agent proposes "Do I have enough to proceed?" and the user confirms. Do not finalize the plan before this confirmation.
- **Persistence:** Save interview results (questions + answers) to `files/interview.md` in the session workspace.
- **Thoroughness over speed:** Prefer too many questions to too few. Ambiguity causes rework, and rework is more expensive than questions. There is no maximum number of interview rounds.
- **User authority:** The user's decisions supersede the agent's recommendations. When disagreeing, fetch current documentation to ensure both parties have accurate information, present evidence with sources, then accept the user's final decision.
- **Source of truth:** `origin/main` is the source of truth for code state, not local working copies or branch/worktree state. Fetch official documentation rather than relying on potentially outdated training data.
