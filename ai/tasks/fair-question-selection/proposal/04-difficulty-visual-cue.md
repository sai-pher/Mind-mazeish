# Proposal 04: Difficulty Visual Cue on Question Card

## Goal
Show the current question's difficulty as a small badge on the `QuestionCard` widget,
using an emoji + colour that fits the existing castle/medieval palette.

---

## Difficulty → visual mapping

| Difficulty | Emoji | Colour | Rationale |
|------------|-------|--------|-----------|
| easy | 🕯️ | `torchGold` `#FFD700` | A candle — gentle, accessible light |
| medium | 🔥 | `torchAmber` `#FF8C00` | A torch — the game's primary accent; familiar challenge |
| hard | ⚔️ | `dangerRed` `#C0392B` | A sword — danger, difficulty, the existing error/lives colour |

All three colours are already in `AppColors`. No new colours needed.

---

## Badge design

A small pill/chip in the **bottom-left corner** of the `QuestionCard` (inside the card padding,
below the question text). Sits alongside the existing book icon (top-right).

```
┌─────────────────────────────────────────┐
│  Question text goes here, possibly      │ [📖]
│  spanning two or three lines.           │
│                                         │
│  🕯️ Easy                                │
└─────────────────────────────────────────┘
```

**Spec:**
- Horizontal pill: emoji + label text
- Background: difficulty colour at 15% opacity (matches the book icon style)
- Border: difficulty colour at 45% opacity (matches the book icon style)
- Text: difficulty colour at full opacity, `bodySmall` (12px Lora)
- Padding: 4px vertical, 8px horizontal
- Border radius: 12px (pill shape)

---

## Widget implementation

Add a static helper method on `QuizQuestion` (or a standalone function in `app_theme.dart`):

```dart
// In question.dart — no new dependency
({String emoji, Color color, String label}) get difficultyDisplay {
  return switch (difficulty) {
    QuestionDifficulty.easy   => (emoji: '🕯️', color: AppColors.torchGold,  label: 'Easy'),
    QuestionDifficulty.medium => (emoji: '🔥', color: AppColors.torchAmber, label: 'Medium'),
    QuestionDifficulty.hard   => (emoji: '⚔️', color: AppColors.dangerRed,  label: 'Hard'),
  };
}
```

**`QuestionCard` update** — add a `Column` wrapper and the badge below the question row:

```dart
@override
Widget build(BuildContext context) {
  final textTheme = Theme.of(context).textTheme;
  final diff = question.difficultyDisplay;

  return Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Existing: question text + book icon
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(question.question, style: ...),
              ),
              if (onArticleTap != null) ...[
                const SizedBox(width: 10),
                // existing book icon widget
              ],
            ],
          ),

          // New: difficulty badge
          const SizedBox(height: 10),
          _DifficultyBadge(emoji: diff.emoji, label: diff.label, color: diff.color),
        ],
      ),
    ),
  ).animate()...;
}
```

**`_DifficultyBadge` widget** (private, file-local):

```dart
class _DifficultyBadge extends StatelessWidget {
  final String emoji;
  final String label;
  final Color color;

  const _DifficultyBadge({
    required this.emoji,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
```

---

## Difficulty selector UI in `_BottomBar` (topic picker)

Add a row of 5 tappable chips between the question-count row and the Start button.
Use the castle theme: skulls or swords — but keep it readable.

**Label row:** `🕯️ Easier ——————— ⚔️ Harder` with 5 numbered chips (1–5).

```dart
Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    Text('🕯️', style: TextStyle(fontSize: 14)),
    const SizedBox(width: 6),
    ...List.generate(5, (i) {
      final value = i + 1;
      final active = value == difficultyBias;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: GestureDetector(
          onTap: () => onDifficultyChanged(value),
          child: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? _biasColor(value) : AppColors.stone,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: active ? _biasColor(value) : AppColors.stoneMid,
              ),
            ),
            child: Text(
              '$value',
              style: TextStyle(
                color: active ? Colors.white : AppColors.textLight,
                fontWeight: active ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ),
        ),
      );
    }),
    const SizedBox(width: 6),
    Text('⚔️', style: TextStyle(fontSize: 14)),
  ],
),
```

Where `_biasColor` interpolates between the three difficulty colours:
```dart
Color _biasColor(int bias) => switch (bias) {
  1 => AppColors.torchGold,
  2 => AppColors.torchGold,
  3 => AppColors.torchAmber,
  4 => AppColors.dangerRed,
  5 => AppColors.dangerRed,
  _ => AppColors.torchAmber,
};
```

The `_BottomBar` receives two new parameters:
```dart
final int difficultyBias;
final void Function(int) onDifficultyChanged;
```

And `_TopicPickerScreenState` adds:
```dart
int _difficultyBias = 3;
```

The `QuizConfig` is constructed with the value at game start.

---

## Files affected

| File | Change |
|------|--------|
| `lib/features/gameplay/domain/models/question.dart` | Add `difficultyDisplay` getter to `QuizQuestion` |
| `lib/features/gameplay/presentation/widgets/question_card.dart` | Add `_DifficultyBadge`, update `QuestionCard.build` |
| `lib/features/start/presentation/screens/topic_picker_screen.dart` | Add difficulty chips row to `_BottomBar`; pass state through |
