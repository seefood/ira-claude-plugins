---
name: debugging-with-the-scientific-method
description: Use when debugging any bug, test failure, or unexplained behavior that survived a first guess — replaces ad hoc "try this, try that" thrashing with a written lab-notebook log of hypothesis, experiment, and result. Use especially when intuition already failed, a fix didn't stick, the bug is intermittent, or you're about to try a second unverified guess.
---

# Debugging with the Scientific Method

## Overview

Guessing wastes time and produces amnesia: three fixes in, nobody remembers what the first two ruled out. Writing the debugging process down as a lab notebook — one entry per hypothesis — forces precision, prevents repeating dead ends, and produces a record of what's actually been ruled out versus merely suspected.

**Core rule:** one hypothesis at a time, written down before touching code, and stated so it can fail.

## The Log Entry

Before changing anything, write an entry with these five fields:

1. **Problem Statement** — what's actually wrong, plus any observations so far. Not "it's broken" — the specific symptom.
2. **Hypothesis** — one falsifiable guess: "I think X is happening because Y." If it can't be wrong, it isn't a hypothesis.
3. **Experiment** — the smallest probe (log line, print, isolated repro, query) that would prove or disprove the hypothesis. Not a fix — a test.
4. **Expected Results** — what you should see if the hypothesis is correct. Be concrete: a row count, a specific log line, a value.
5. **Actual Results** — what actually happened. Paste it in verbatim (log lines, query output, screenshot description) rather than paraphrasing.

Template for one entry:

```
### Entry N
**Problem Statement:**
**Hypothesis:**
**Experiment:**
**Expected Results:**
**Actual Results:**
```

## The Loop

```
write Problem Statement
loop:
    write Hypothesis (falsifiable, specific)
    write Experiment (smallest probe, not a fix)
    write Expected Results
    run the experiment
    write Actual Results
    if Actual matches Expected:
        hypothesis confirmed → root cause found → implement the real fix
        → re-run the ORIGINAL problem scenario and confirm the symptom is gone
        (a fix without this final check is still just a hypothesis)
    elif Actual contradicts Expected:
        hypothesis rejected → write a NEW hypothesis informed by what you just learned
        do not stack a second fix on top of the failed one
    else:
        inconclusive → the experiment didn't isolate the variable; narrow it
        (smaller repro, single input, remove concurrency/timing) and rerun
        before forming the next hypothesis — don't guess past noisy data
```

Keep every rejected or inconclusive entry instead of deleting it — it's evidence that narrows the next guess.

## Worked Example

`references/generator-bug.md` walks a real bug (a Python generator silently emptying) through two rejected hypotheses to the confirmed root cause, in the five-field format above.

## Notes

- This is a note-taking discipline, not a replacement for actually reproducing the bug — you still need a reliable repro to run experiments against.
- Works standalone for a quick "write it down before you thrash" habit, and also serves as the concrete journaling practice for the Hypothesis-and-Testing phase of `superpowers:systematic-debugging` when that skill is in use.
