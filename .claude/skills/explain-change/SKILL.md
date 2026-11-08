---
name: explain-change
description: Teach the user what a finished change does and which Swift concepts it uses, using TypeScript/React analogies. Use after a spec has been built and reviewed, or whenever the user says "explain this change", "explain the spec", "разбери изменение", "объясни что мы написали", "хочу понять этот код", or asks to learn from a diff, branch, or commit range. Not a code review (use bmad-review or bmad-walkthrough for that).
---

# Explain Change

The user is learning Swift (background: JS/TS/React) and wants to understand every line of this project. This skill turns one finished change into a lesson. It teaches; it does not review or judge the code.

The unit is **one change as a whole**, normally one BMAD spec. A lesson about a single commit loses the "why", and a lesson about a whole epic is too big to absorb.

## Run in its own session

One workflow step per session keeps context clean. Do the lesson, then stop. Do not start building, reviewing, or planning the next step.

## 1. Find the change

Pick the first that applies:

1. The user named a spec folder, a branch, or a commit range: use it.
2. No argument and `_bmad-output/specs/` has spec folders: take the most recently modified one that has a `SPEC.md`, and say which one you picked.
3. Otherwise: the diff of the current branch against `main` (`git diff main...HEAD`, `git log main..HEAD`).

For a spec, read `SPEC.md` (why, capabilities `CAP-N`, constraints, non-goals) and `.memlog.md` (decisions and their reasons). Find its commits from the memlog or `git log` on the touched paths. If the range is genuinely ambiguous, ask once, in one line, before reading further. Read the actual diff and the final state of the touched files; do not explain code you have not read.

## 2. Check what the user already knows

Read `docs/learning-notes.md`. Concepts already explained there get at most one line ("`@MainActor`, как в задаче 3"). Spend the words on what is new. The user's level is beginner in Swift, comfortable in TypeScript, so name the TS/React equivalent first and the Swift difference second.

## 3. Write the lesson (one message, Russian)

Keep Swift and framework terms in English. Use `path:line` for every code reference so it is clickable. Verify each claim about behavior by reading the code; if something is unclear, say so instead of guessing.

Structure:

- **Зачем.** One paragraph: the problem this change solves, from the spec (or from the commits if there is no spec).
- **Как это работает.** Walk the change by scenario, not by file. For each capability: what the user sees or does, then the path through the code (for example hotkey → `HotkeyService` → `AppRouter.openJournal()` → window), then the test that proves it (plain UI glue often has none: say so and name how it was checked instead, rather than inventing a test). Order follows the flow of data or events.
- **Новые концепции.** Woven into the walkthrough where they first appear, each with: what it is, the TS/React analogy, where it is in the diff, why it is used here and not something simpler.
- **Решения.** Two or three choices the change made (from the memlog) and what the alternative was, so the user learns the reasoning and not only the result.
- **Что запомнить.** Three to five short points.
- **Проверь себя** (optional). Two or three questions about how the code behaves, with answers hidden until the user asks. Offer them; do not insist.

Aim for something readable in about ten minutes. If the change is large, say what you left out and offer a second pass on that part.

## 4. Draft the notes, then ask

Draft an entry for `docs/learning-notes.md` in its existing format: a `## <название задачи>` heading and short bullets, each bullet one concept with its TS/React analogy. Show the draft in the chat and write it to the file only after the user approves, because the notes are the user's own study material and they may want to rephrase the analogies.

## 5. Stop

End by saying what was explained, whether the notes were saved, and that the next step belongs in a fresh session. Do not invoke other skills.
