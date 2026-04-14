# Proposal 02: All Variety Opportunities in a Playthrough

## Overview

Five distinct layers where each playthrough can differ from the last.
Layers 1–2 are the primary fix. Layers 3–5 are already working or future opportunities.

---

## Layer 1 — Topic Sampling (PRIMARY FIX, issue #44)

**Current:** Flat pool → large topics dominate.
**Fix:** Round-robin interleaved (see proposal 01).
**Effect:** Every topic in the selected set has an equal expected contribution per game slot.
Replaying the same topic selection produces different topic mixes each time.

---

## Layer 2 — Question Ordering Within the Game

**Current:** After the flat-pool shuffle, there is no topic-interleaving guarantee.
Questions from the same topic may cluster together.

**With round-robin:** The pre-selection interleaving is broken by a final `shuffle()`,
so the player sees no predictable topic pattern.

**Alternative: Keep interleaved order (no final shuffle).**
- Pros: topics alternate visibly → feels more varied mid-game
- Cons: player could notice the pattern ("every other question is about crocheting")
- Verdict: keep the final shuffle — variety feels natural, not mechanical

**Opportunity (future):** Difficulty ramping — sort selected questions easy→medium→hard
within the shuffled set. Not in scope for this fix but noted here.

---

## Layer 3 — Answer Option Randomization (ALREADY WORKING)

Each call to `Question.toQuizQuestion()` independently:
1. Picks 1 correct answer at random from `correctAnswers` (1–3 options)
2. Picks 3 wrong answers at random from `wrongAnswers` (4–12 options)
3. Shuffles all 4 into a random order

**Effect:** The same question can appear with different wording for the correct answer,
different distractors, and different button positions on every encounter.
Questions with 3 correct answers and 12 wrong answers have enormous per-question variety.

**No change needed.** This is already well-designed.

---

## Layer 4 — Topic Order Randomization (SMALL WIN, already in round-robin proposal)

**Current:** Topics are merged in `topicIds.where(...)` order (Set iteration order, arbitrary).
**With round-robin fix:** The topic list is shuffled before cycling, so the topic that
"goes first" in round 1 changes each game.

**Effect:** Even in a 2-topic game with equal representation (3 crocheting, 2 WAH),
which topic fills slots 1/3/5 vs 2/4 is randomized.

---

## Layer 5 — Difficulty Sequence (FUTURE OPPORTUNITY)

**Not implemented.** Questions have a `difficulty` field (`easy/medium/hard`).

**Options:**
- **Random** (current, implicit): No ordering by difficulty — already the default.
- **Ramping:** Sort selected questions easy→medium→hard. Rewards progression.
- **Oscillating:** easy, hard, medium, easy, hard, ... — keeps player on their toes.

**Verdict:** Out of scope for this fix. Could be a separate feature (`quiz_config` field:
`difficultyOrder: random | ramp | oscillate`).

---

## Summary: What Changes With the Fix

| Playthrough 1 | Playthrough 2 | Reason |
|---------------|---------------|--------|
| 5 WAH questions | 3 WAH + 2 crocheting | Round-robin fair sampling |
| Q order: WAH, WAH, WAH, WAH, WAH | Q order: WAH, crochet, WAH, crochet, WAH | Interleaved + shuffle |
| Crocheting Q shows "yarn over" as correct | Same Q shows same correct answer | Only 1 correct answer exists |
| Wrong answers: A, B, C | Wrong answers: A, D, C | Random wrong answer selection |
| Option positions: correct=3rd | Option positions: correct=1st | Option shuffle |

**Net effect:** Each playthrough with the same topic selection feels fresh because:
1. Different questions are likely to appear from each topic
2. Answer options are different for questions that support it
3. Question order is different
