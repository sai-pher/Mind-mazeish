# Proposal 01 — Release Grouping Strategy

## Principles

1. **Bug fixes and polish first** — low risk, immediate value for alpha testers
2. **Infrastructure before features** — responsive layout (#62) and settings foundations (#59) before new screens (#58)
3. **Each release is shippable** — no release depends on unfinished work from the next one
4. **Largest scope last** — #58 (mode redesign) touches the most code; doing it last means all other improvements are already stable

---

## Release Groups

### Release A — v1.1: Bug Fix Sprint
**Goal:** Fix the most visible defects reported by alpha testers

| Issue | Title | Why here |
|-------|-------|----------|
| #54 | Long text wrapping | Trivial isolated fix; embarrassing to ship with |
| #83 | Game stats inaccurate | Trust/data correctness issue; easy win once root cause found |
| #63 | App permissions | Defensive hygiene; small diff |

**Estimated PRs:** 1–3 small PRs
**Risk:** Very low — all isolated fixes

---

### Release B — v1.2: Gameplay UX
**Goal:** Improve the in-game and question-bank experience

| Issue | Title | Why here |
|-------|-------|----------|
| #55 | Wiki link in answer popup | Small contained addition to existing overlay |
| #56 | Question bank: URL counts + request popup | Fixes a confusing display + adds useful UX for question management |
| #62 | Flexible/responsive scaling | Must ship before new screens; fixes existing screens immediately |

**Estimated PRs:** 2–3 PRs
**Risk:** Low–medium (#62 touches many widgets; needs broad testing)

---

### Release C — v1.3: Onboarding & Settings
**Goal:** Help new users understand the game; establish settings infrastructure

| Issue | Title | Why here |
|-------|-------|----------|
| #59 | About page + tooltips + app settings | New screens built on responsive layout from B; settings persistence pattern needed by #58 |

**Estimated PRs:** 1 PR (can be split by sub-feature)
**Risk:** Medium — new navigation routes + SharedPreferences usage
**Dependency:** Release B (#62) shipped

---

### Release D — v1.4: Mode Selection Redesign
**Goal:** Replace the topic picker with a proper game mode selection experience

| Issue | Title | Why here |
|-------|-------|----------|
| #58 | Game mode selection (home flow) | Largest change; builds on responsive layout + settings; comes last to avoid destabilising earlier work |

**Estimated PRs:** 1–2 PRs
**Risk:** High — replaces the primary navigation flow into a game
**Dependency:** Releases B + C shipped

---

## Timeline overview

```
A: v1.1 ─── Bug Fix Sprint     → #54, #83, #63
B: v1.2 ─── Gameplay UX        → #55, #56, #62
C: v1.3 ─── Onboarding/Settings→ #59
D: v1.4 ─── Mode Redesign      → #58
```
