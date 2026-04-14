# Proposal 01: Selection Algorithm Options

## Goal
Each selected topic should have an equal expected contribution to the final question set,
regardless of how many questions that topic has. No hard minimums — just equal probability.

---

## Algorithm A — Current (broken): Flat Pool Shuffle

```dart
pool.shuffle();
pool.take(count);
```

**Probability per slot:** `topicSize / totalQuestions`
**Result:** Large topics dominate. Crocheting (3q) vs WAH (25q) → WAH is 8× more likely per slot.
**Verdict:** ❌ Discard.

---

## Algorithm B — Round-Robin Interleaved (RECOMMENDED)

**Concept:** Shuffle within each topic independently, then cycle through topics picking one
question at a time until the count is reached or all topics are exhausted.

```dart
List<QuizQuestion> selectQuestionsFrom(
  List<Question> allQuestions, {
  required Set<String> topicIds,
  required int count,
  Random? rng,
}) {
  final random = rng ?? Random();

  // Group by topic, shuffle each bucket independently.
  final buckets = <String, List<Question>>{};
  for (final q in allQuestions) {
    if (topicIds.contains(q.topicId)) {
      (buckets[q.topicId] ??= []).add(q);
    }
  }
  for (final bucket in buckets.values) {
    bucket.shuffle(random);
  }

  // Round-robin: cycle through topics, pick one per round.
  final topicList = buckets.keys.toList()..shuffle(random); // randomise topic order too
  final selected = <Question>[];
  int round = 0;
  while (selected.length < count) {
    bool anyAdded = false;
    for (final topicId in topicList) {
      if (selected.length >= count) break;
      final bucket = buckets[topicId]!;
      if (round < bucket.length) {
        selected.add(bucket[round]);
        anyAdded = true;
      }
    }
    if (!anyAdded) break; // all buckets exhausted
    round++;
  }

  // Shuffle final selection so topic interleaving is not obvious.
  selected.shuffle(random);
  return selected.map((q) => q.toQuizQuestion(random)).toList();
}
```

**Properties:**
- Each topic contributes at most `ceil(count / numTopics)` questions per pass
- Small topics (3q) and large topics (40q) are equally likely to fill round-1 slots
- If a topic runs dry before `count` is reached, remaining slots are filled by topics with surplus
- No hard minimum: a topic can legitimately provide 0 questions if it runs dry and others fill up
- The final shuffle breaks the interleaved pattern → order appears fully random to the player

**Expected topic representation for 5 questions, 2 topics (crocheting=3, WAH=25):**
- Round 1: 1 crocheting, 1 WAH (2 questions)
- Round 2: 1 crocheting, 1 WAH (4 questions)
- Round 3: 1 crocheting, 1 WAH → stop at 5 → 3 crocheting, 2 WAH (or 2/3 depending on final shuffle position)
- On average: near-equal representation regardless of topic size

**Verdict:** ✅ Recommended. Simple, fair, handles depletion gracefully, testable.

---

## Algorithm C — Probability-Weighted Sampling

**Concept:** Assign each question a weight of `1/topicSize`. Sample without replacement
using these weights. Each topic has equal expected total weight.

```
weight(q) = 1.0 / topicSize(q.topicId)
```

**Implementation:** Weighted reservoir sampling (Algorithm A-Res or Efraimidis-Spirakis).

**Properties:**
- Mathematically rigorous: each topic has exactly equal expected probability of filling a slot
- More complex to implement correctly (need reservoir sampling, not trivial in Dart)
- Harder to unit-test the probabilistic behaviour
- Subtle depletion handling: once a question is selected, weights renormalize

**Verdict:** ⚠️ More principled mathematically, but overkill for this use case. Round-robin
achieves the same player experience with far simpler code.

---

## Algorithm D — Equal Quota (Floor/Ceil Split)

**Concept:** Divide `count` evenly across topics (`floor(count / numTopics)` per topic),
distribute remainder randomly. Handle depletion by redistributing.

```
basePerTopic = count ÷ numTopics
remainder    = count mod numTopics
```

**Properties:**
- Strictly deterministic split before randomness — closest to enforced minimums
- More complex depletion handling (need to redistribute)
- Topic ordering during game would be predictable without a final shuffle
- User explicitly said "don't enforce minimums" — this algorithm drifts that way

**Verdict:** ❌ Drifts toward enforced minimums. Use round-robin instead.

---

## Comparison table

| Algorithm | Fair? | Simple? | Handles depletion? | No hard minimums? |
|-----------|-------|---------|-------------------|-------------------|
| A — Flat pool (current) | ❌ | ✅ | ✅ | ✅ |
| B — Round-robin | ✅ | ✅ | ✅ | ✅ |
| C — Weighted sampling | ✅ | ❌ | ✅ | ✅ |
| D — Equal quota | ✅ | ⚠️ | ⚠️ | ❌ |

**Winner: Algorithm B — Round-Robin Interleaved.**
