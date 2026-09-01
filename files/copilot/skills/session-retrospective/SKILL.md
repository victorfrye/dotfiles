---
name: session-retrospective
description: Conduct an evidence-based retrospective after code, configuration, documentation, or operational work; when a session goes idle or wraps up; or on explicit request. Gathers evidence, drafts findings for user confirmation, writes durable lessons and handoff notes, and persists anything into a project only per that project's explicit retrospective contract.
---

# Session Retrospective Instructions

You conduct structured, evidence-based retrospectives on completed work. A retrospective's job is to turn what actually happened in a session into a durable, accurate record that a future agent or person can act on — without guessing, without fabricating a clean narrative, and without changing project artifacts beyond what the project has explicitly agreed to.

This skill is intentionally **tool-neutral**: it does not assume any specific agent framework, file layout, or tool names. Use whatever interactive prompting, file, repository, and history-inspection capabilities the current environment provides.

## When to Trigger

- **After a meaningful unit of work** — code, configuration, documentation, or operational/infrastructure changes (deploys, migrations, incident response, cross-repo coordination, etc.) — once it reaches a stable stopping point.
- **On session idle or wrap-up** — before a session ends, is handed off, or goes quiet for an extended period.
- **On explicit request** — the user asks for a retrospective, a "what did we learn" summary, or a session wrap-up.
- **Skip** trivial, single-step changes (a typo fix, a one-line config edit) unless the user explicitly asks for a retro on them anyway.

## Evidence Gathering (Before Drafting Anything)

Re-derive what happened from primary evidence — do not draft from memory or from your own prior summaries alone. Pull from as many of these sources as are available in the current environment:

1. **Diff and commit history** — what files actually changed, in what order, and what the commit messages claim happened. Commit messages describe intent; diffs describe reality — check both.
2. **Validation output** — build, lint, test, and any health-check/CI results produced during the session. Record what passed, what failed, and what was never run at all.
3. **Project documentation** — the project's agent-instructions, README, contributing guidance, ADRs, or equivalent authoritative docs, so findings can be checked against stated conventions rather than assumed ones.
4. **Durable state** — any todo/task tracking, session notes, or persisted planning artifacts from this session, comparing what was planned against what was actually done.
5. **Conversation/session history** — the transcript itself, to recover decisions, corrections, dead ends, and user preferences expressed mid-task that live nowhere else.

If a source is genuinely unavailable in the current environment, say so explicitly in the findings rather than silently omitting it. An incomplete evidence base should lower confidence in the findings that depend on it, not be hidden.

## Draft Findings First

Never write a persisted retrospective record directly from evidence. Always:

1. Produce a **draft** covering: what was done, the evidence behind it, decisions made and why, what worked, what didn't, unresolved risks, and any stale or leftover artifacts from the session.
2. Present the draft to the user and invite correction before treating anything in it as final. The agent inferred this narrative from evidence after the fact — the user was present for the actual decisions and their corrections take precedence.
3. Treat a finding as eligible for persistence only once the user has confirmed it (explicitly, or by requesting adjustments and then confirming the revised draft).

## Lessons, Decisions, and Future-Agent Handoff

Once findings are confirmed, write a record aimed at **whoever picks up this work next** — a future agent or person with no memory of this session — not a status update for the current user. It should answer, concretely:

- What decisions were made, and *why* — not just what changed.
- What is now a validated fact versus an open question or unresolved risk.
- What patterns emerged worth repeating (or avoiding) next time.
- Who or what owns any follow-up work, and where it is tracked.
- What artifacts from this session are now stale and should not be trusted or reused as-is.

Write this as durable prose someone could act on cold, not a terse bullet list of activity.

## Evidence-Backed Persistence, Guided by a Per-Project Contract

Whether — and where — this record gets written into a project is governed by that **project's own explicit retrospective contract**, never by this skill's own preference:

1. Look for an explicit contract before writing anything: a dedicated retrospective/contributing doc, or a clearly labeled section in the project's agent-instructions or contributing documentation, stating where retrospective content belongs (a specific file, a specific doc section, or explicitly "nowhere in the repository").
2. If no contract exists, do not guess. Persist only to session-local/runtime storage that is not part of the project's repository, and tell the user plainly that no project contract authorizes writing this into the repository — offer to do so anyway only if the user explicitly asks.
3. Every persisted statement must trace back to gathered evidence or a user-confirmed finding. Never persist speculation as settled fact.
4. A retrospective is never a reason to touch application/source files. Do not "fix" unrelated issues surfaced during the retrospective — capture them as follow-up items instead, per rule above.

## Proposing Skill Candidates

If the retrospective surfaces a repeatable pattern — a process, checklist, or convention used more than once, or clearly likely to recur — that would benefit from being codified as a reusable skill:

1. Propose it explicitly, citing concrete evidence: which sessions or tasks exhibited the pattern, and what problem codifying it would solve.
2. Do not create or modify any skill file until the user explicitly approves that specific proposal. A skill is a shared, reusable asset — changing one silently changes future agent behavior beyond this session.
3. If approved, treat the change like any other reviewed change to the project: follow its existing skill format and conventions, and validate the result before considering it done.

## Local-Main Aggregation

Some workflows run in an isolated worktree, branch, or session that is not the project's primary local checkout ("local-main"). A retrospective must **never** aggregate or write findings into local-main unless the project's contract explicitly authorizes that aggregation path (for example, a documented convention for committing shared session or squad knowledge back into a main working copy).

- If authorization is present, follow the contract's stated mechanism exactly — for example, committing from a branch rather than editing the main checkout's working tree directly.
- If authorization is absent or ambiguous, skip aggregation and say so. Do not attempt it "just in case."
- If aggregation is authorized but fails (missing path, lock, conflict, permissions, or any other error), **fail safely**: leave local-main untouched, report the failure plainly, and keep the retrospective persisted wherever it was already safely written (e.g., session-local storage). Never leave local-main in a partially written or corrupted state to complete an aggregation.

## Behavioral Rules

- **Tool-neutral.** Describe capabilities, not tool names — use whatever interactive prompting, file, and repository inspection tools the current environment actually provides.
- **User authority.** The user's corrections about what happened, and their decisions about what gets persisted and where, are final.
- **No silent scope creep.** A retrospective observes and records; it does not refactor code, fix bugs, or make product decisions on its own initiative. Surface those as follow-ups instead.
- **Confidence over completeness.** A retrospective that honestly reports "we don't have evidence for X" is more valuable than one that fabricates a clean, complete-looking narrative.
- **Non-destructive by default.** When in doubt about whether an action (persisting, aggregating, modifying a skill) is authorized, don't — ask, or fall back to a private/session-local record.

## Worked Example

**Trigger:** A session that fixed a recurring CI failure across four repositories is about to end.

**Evidence gathered:** Commit history across the four repos, the CI run history showing the failure and its resolution, the shared squad-knowledge doc describing the prior (incorrect) hypothesis, and the session transcript showing the user rejecting an earlier proposed fix.

**Draft presented to user:** "Root cause was X, not the previously recorded Y. Confirmed fix applied to repos A–C; repo D's fix is still pending its own CI run. Here's what I'd record as decided vs. still open — does this match what you saw?"

**User correction:** "Repo D's CI already passed while you were drafting this — mark it done, not pending."

**Handoff record (after confirmation):** States the corrected root cause, marks all four repos resolved, records the earlier incorrect hypothesis as a corrected historical note (not deleted, so nobody re-investigates it), and flags no open follow-ups.

**Persistence:** The squad's shared-knowledge doc has an explicit contract authorizing exactly this kind of cross-repo lesson to be appended there, plus a documented convention that squad state is committed and pushed from a worktree branch — never by editing the main checkout directly. The retrospective follows that convention exactly and reports the commit it produced.

**Skill candidate:** The pattern of "confirm root cause across repos before recording it as fact" recurred three times this session. Proposed as a candidate addition to an existing investigation skill, with the three instances cited as evidence — deferred pending explicit user approval, no skill file changed.
