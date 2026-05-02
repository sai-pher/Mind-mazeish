# Proposal 03: Maze UI & Navigation

## Screens

### `/maze-settings` — MazeSettingsScreen
- Reuses topic picker and difficulty UI from GameSettingsScreen
- "Enter the Maze" CTA button
- Passes `QuizConfig` to maze generator

### `/maze` — MazeScreen
Main screen. Two layers:

#### Top: MazeMapWidget (scrollable/zoomable grid)
- Renders a 10×10 grid of cells
- Cell display by status:
  | Status | Appearance |
  |--------|-----------|
  | `hidden` | Black / dark stone, no icon |
  | `visible` | Dim stone, faint outline |
  | `visited` | Stone colour, room door icon |
  | `answered` | Gold glow, open door icon |
  | `skipped` | Muted amber, half-open door |
  | Throne (discovered) | Throne icon, shimmer |
  | Player position | Knight/torch icon on top of room |
- Walls between cells rendered as thick borders, open passages as thin/no border
- Player position centred in view

#### Bottom: ActionPanel
- Shows current room context (topic name, door state)
- If room has unanswered question: "Answer Question" + "Skip Room" buttons
- If room already answered/skipped: direction arrows (N/S/E/W) or just map navigation
- Lives widget (top bar, 3 flame icons)

### Question Sheet (bottom sheet, same UX as GameplayScreen)
- Question card with 4 answer options
- On answer: reveal correct/wrong, show fun fact
- "Onward!" button → dismiss sheet, return to maze navigation
- Skip: separate "Skip this room" text button → dismiss without answering

---

## Navigation model
Player taps a **direction arrow** (or adjacent visible cell on map) to move.

Movement rules:
1. Target cell must be **connected** (no wall in that direction).
2. If target is visited/answered/skipped → move freely.
3. If target is unvisited and has a question → open Question Sheet before committing move.
4. If target is unvisited and has no question → move directly, mark `visited`.
5. If target is Throne Room → move, trigger `complete`.

### Direction input
Four arrow buttons (↑ ↓ ← →) shown below the map. Disabled if wall in that direction.

---

## Results screen (reuse existing)
- Navigate to `/results` with a `MazeResultsExtra` containing: rooms visited, questions answered, correct count, lives remaining
- Reuse ResultsScreen with a maze-specific summary card

---

## Colour usage (AppColors)
| Element | Colour |
|---------|--------|
| Hidden cell | `background` (#1A1208) |
| Visible cell | `stone` (#3D3020) |
| Answered cell | `torchGold` (#FFD700) glow |
| Skipped cell | `torchAmber` (#FF8C00) dim |
| Wrong answer flash | `dangerRed` (#C0392B) |
| Player icon | `parchment` (#F5E6C8) |
| Throne (discovered) | `torchGold` pulse |

---

## Animations
All use `flutter_animate`:
- Cell reveal (fog lift): fade + scale in ~200ms
- Player movement: position tween ~150ms
- Throne discovery: shimmer pulse
- Answer correct: cell flashes gold
- Answer wrong: cell shakes + red flash
