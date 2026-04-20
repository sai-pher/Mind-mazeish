enum DoorState {
  wall,    // no passage between cells
  locked,  // passage exists, question not yet answered
  open,    // answered correctly
  skipped, // player bypassed without answering
}
