---
name: session-retrospective
description: Conduct an evidence-based retrospective after code, configuration, documentation, or operational work; when a session goes idle or wraps up; or on explicit request. Gathers evidence, drafts findings for the user to correct, persists evidence-backed findings automatically unless the user objects, and always attempts to promote the committed record into the project's actual source of truth (origin/main, the primary local checkout, or equivalent) through its documented safe workflow — discovering the project's retrospective contract, or proposing one if none exists, never bypassing review, and reporting plainly (without corrupting the source of truth) if promotion is blocked.
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

Never write a persisted retrospective record straight from evidence without a review step. Always:

1. Produce a **draft** covering: what was done, the evidence behind it, decisions made and why, what worked, what didn't, unresolved risks, and any stale or leftover artifacts from the session.
2. Present the draft to the user and invite correction before treating anything in it as final. The agent inferred this narrative from evidence after the fact — the user was present for the actual decisions and their corrections take precedence.
3. **Persist automatically once a finding is evidence-backed and survives that review — do not wait for an explicit "yes, save this."** The user's silence, or simply moving on, is not a blocker to persistence. What changes the outcome is the user objecting to a finding or asking for changes: honor that instead of persisting the disputed content, and re-draft before persisting anything affected by the correction.

## Lessons, Decisions, and Future-Agent Handoff

Once findings are confirmed, write a record aimed at **whoever picks up this work next** — a future agent or person with no memory of this session — not a status update for the current user. It should answer, concretely:

- What decisions were made, and *why* — not just what changed.
- What is now a validated fact versus an open question or unresolved risk.
- What patterns emerged worth repeating (or avoiding) next time.
- Who or what owns any follow-up work, and where it is tracked.
- What artifacts from this session are now stale and should not be trusted or reused as-is.

Write this as durable prose someone could act on cold, not a terse bullet list of activity.

## Persisting and Promoting Confirmed Findings

A retrospective is only valuable if its lessons and handoff record actually reach the project's **durable state, at its real source of truth**. Session or runtime storage may hold a working draft, but it is never an acceptable final artifact — and neither is a commit left stranded on a working/session branch that nobody promotes further. Both halves below are mandatory, not contingent on a separate opt-in.

### 1. Commit, guided by the project's contract

1. **Always discover the contract first.** Look for an explicit contract before writing anything durable: a dedicated retrospective/contributing doc, or a clearly labeled section in the project's agent-instructions, contributing documentation, or equivalent, stating where retrospective content belongs (a specific file, a specific doc section, or an established decision-log/handoff convention).
2. **If a contract exists**, follow it exactly: write the confirmed findings into the location and format it specifies, and commit them through the project's normal delivery workflow — never by bypassing review or editing outside that workflow.
3. **If no contract exists, do not leave the knowledge session-private.** Draft a concrete, evidence-backed proposal for where this project should durably record retrospective/handoff knowledge (for example, a new "Decisions" or "Lessons Learned" section in its agent-instructions or contributing doc, or a dedicated file), present it to the user, and — once approved — add that contract documentation *and* the confirmed findings in the same change, committed through the project's normal delivery workflow. Session/runtime storage may hold the draft only until this is resolved, never as a substitute for it.
4. Every persisted statement must trace back to gathered evidence or a user-confirmed finding. Never persist speculation as settled fact.
5. A retrospective is never a reason to touch unrelated application/source files, and it never refactors code, fixes bugs, or reconfigures anything outside its own contract and findings — even when the opportunity is obvious mid-retro. Record any such opportunity as an explicit, separately tracked follow-up item (a todo, issue, or backlog entry) instead of acting on it.

### 2. Always attempt promotion to the project's actual source of truth

Committing confirmed findings onto a working/session branch is not the end state — it is a checkpoint. A retrospective **always attempts**, by default, to promote that committed record into the project's real source of truth (`origin/main`, the primary local checkout, or whatever the project treats as canonical) through that project's own documented, safe promotion mechanism (for example, a reviewed pull/merge request, a documented fast-forward merge, or an equivalent convention the project defines). This is not gated behind separate authorization — do not stop at "committed to a branch" and call the retrospective done, and do not merely leave the work sitting on the source branch for someone else to promote later.

- Use the project's documented mechanism exactly as specified — never push directly to the source of truth, force-merge, or otherwise bypass whatever review or validation gate the project normally requires for that promotion path.
- If promotion succeeds, report what was promoted and how (e.g., which commit, which merge/PR).
- **Fail safely if promotion cannot proceed.** A merge conflict, a missing or ambiguous safe path, insufficient permissions, a pending required review, a lock, or any other blocker means: leave the source of truth exactly as it was — untouched and uncorrupted, never partially written, conflicted, or merged halfway. Preserve the already-committed source artifact exactly as committed; it remains the durable record of the retrospective regardless of whether promotion succeeds. Report the specific blocker to the user plainly (what was attempted, what blocked it, and where the committed artifact still lives) rather than silently leaving the work stranded or retrying destructively.
- A blocked promotion is not a failed retrospective. The findings are still durably committed per the base persistence duty above — report it as "committed, promotion skipped: `<reason>`," not as an unresolved task.

## Proposing Skill Candidates

If the retrospective surfaces a repeatable pattern — a process, checklist, or convention used more than once, or clearly likely to recur — that would benefit from being codified as a reusable skill:

1. Propose it explicitly, citing concrete evidence: which sessions or tasks exhibited the pattern, and what problem codifying it would solve.
2. Do not create or modify any skill file until the user explicitly approves that specific proposal. A skill is a shared, reusable asset — changing one silently changes future agent behavior beyond this session.
3. If approved, treat the change like any other reviewed change to the project: follow its existing skill format and conventions, and validate the result before considering it done.

## Isolated Worktrees and Local-Main

Some workflows run in an isolated worktree, branch, or session that is not the project's primary local checkout ("local-main") — for example, a session working in its own worktree while `origin/main` or a separately maintained local-main copy is the project's actual source of truth. This is not a special case that relaxes the promotion duty above: it is simply what "the project's source of truth" refers to in that setup, and section 2 above (**Always attempt promotion to the project's actual source of truth**) applies exactly as written — attempt promotion by default through the documented safe mechanism, and fail safely (leaving local-main or `origin/main` untouched and reporting the blocker plainly) if it cannot proceed cleanly. Never leave local-main, or any source of truth, in a partially written or corrupted state to force an aggregation through.

## Behavioral Rules

- **Tool-neutral.** Describe capabilities, not tool names — use whatever interactive prompting, file, and repository inspection tools the current environment actually provides.
- **User authority.** The user's corrections about what happened, and their decisions about a proposed contract or where confirmed findings live within it, are final.
- **No silent scope creep.** A retrospective observes and records; it never refactors code, fixes bugs, changes configuration, or makes product decisions on its own initiative — even when the fix is obvious and small. Record any such opportunity as an explicit, separately tracked follow-up item (a todo, issue, or backlog entry) instead of acting on it during the retro.
- **Confidence over completeness.** A retrospective that honestly reports "we don't have evidence for X" is more valuable than one that fabricates a clean, complete-looking narrative.
- **Durable and promoted by default, not by default guess.** Persisting confirmed findings into the project, and then attempting to promote that commit into the project's actual source of truth, is never optional — discover the contract, or propose one, rather than defaulting to a session-private record, and never treat "committed to a branch" as the finish line when promotion is the project's normal next step. Reserve "don't, ask first" caution for skill-file changes and for anything outside the retrospective's own contract and findings, not for the base persistence-and-promotion duty itself.

## Worked Example

**Trigger:** A session that fixed a recurring CI failure across four repositories is about to end.

**Evidence gathered:** Commit history across the four repos, the CI run history showing the failure and its resolution, the shared squad-knowledge doc describing the prior (incorrect) hypothesis, and the session transcript showing the user rejecting an earlier proposed fix.

**Draft presented to user:** "Root cause was X, not the previously recorded Y. Confirmed fix applied to repos A–C; repo D's fix is still pending its own CI run. Here's what I'd record as decided vs. still open — does this match what you saw?"

**User correction:** "Repo D's CI already passed while you were drafting this — mark it done, not pending."

**Handoff record (re-drafted, then persisted with no further objection):** States the corrected root cause, marks all four repos resolved, records the earlier incorrect hypothesis as a corrected historical note (not deleted, so nobody re-investigates it), and flags no open follow-ups. No explicit "go ahead and save it" was requested or needed — the corrected draft went unobjected, so it was persisted.

**Persistence and promotion:** The squad's shared-knowledge doc has an explicit contract authorizing exactly this kind of cross-repo lesson to be appended there, plus a documented convention that squad state is committed and pushed from a worktree branch — never by editing the main checkout directly. The retrospective follows that convention exactly, opens the documented review path to promote the commit into the squad's local-main copy, and reports both the commit and the successful promotion back to the user.

**Trigger (promotion blocked):** A retrospective's findings are drafted, unobjected to, and committed to the session's working branch, but the project's documented promotion mechanism is a fast-forward merge into local-main and another session has since advanced local-main past the retrospective's base commit.

**What happens:** The retrospective does not force a merge, rebase over the conflict, or edit local-main's working tree directly to make it fit. It leaves local-main exactly as it was, keeps the confirmed findings committed on the session's branch (still the durable record), and reports plainly: "Findings committed at `<commit>` on `<branch>`; promotion to local-main skipped — local-main has advanced past this branch's base and a fast-forward is no longer possible. Rebase and retry, or promote manually." This is reported as a completed retrospective with a skipped promotion, not as a failure of the retrospective itself.

**Trigger (scope creep temptation):** While gathering evidence for a retrospective, the agent notices an unrelated lint warning and an outdated comment in a file it is reading.

**What happens:** Neither is touched. Both are recorded as separate follow-up items (e.g., new todos) with enough detail to act on later, and the retrospective proceeds with its own findings unchanged.

**Skill candidate:** The pattern of "confirm root cause across repos before recording it as fact" recurred three times this session. Proposed as a candidate addition to an existing investigation skill, with the three instances cited as evidence — deferred pending explicit user approval, no skill file changed.

**Trigger (no existing contract):** A session that added a new deployment script to a project with no retrospective/handoff convention is wrapping up.

**Evidence gathered:** The diff adding the script, its validation run, and a scan of the project's contributing docs and agent-instructions confirming no retrospective, decision-log, or handoff section exists anywhere in the repository.

**Draft presented to user:** The confirmed findings (what the script does, why this approach was chosen over an alternative that was tried and reverted, and one open risk about a missing rollback path).

**Persistence and promotion:** No contract is found, so the retrospective does not default to a session-private note. Instead, it proposes a concrete durable-contract addition — e.g., a new "Decisions" section in the project's agent-instructions doc, with the confirmed findings as its first entry — and asks the user to approve it. Once approved, both the new contract section and the confirmed findings are written and committed together through the project's normal branch/commit workflow. The retrospective then attempts to promote that commit into the project's actual source of truth (e.g., opening the review the project's workflow requires against `origin/main`) and reports back the commit and the outcome of that promotion attempt — successful or, if blocked, the specific reason.
