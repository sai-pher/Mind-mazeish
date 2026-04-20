enum RoomStatus {
  hidden,   // fog of war — not yet visible
  visible,  // adjacent to a visited room, shown on map but not entered
  visited,  // entered; question not answered (or no question)
  answered, // question answered correctly
  skipped,  // question skipped
}
