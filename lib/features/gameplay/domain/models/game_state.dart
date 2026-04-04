import 'room.dart';

enum GameStatus { idle, loading, playing, answerRevealed, gameOver, complete }

class GameState {
  final List<Room> rooms;
  final int currentRoomIndex;
  final int score;
  final int lives;
  final GameStatus status;
  final Set<String> usedArticleTitles;

  const GameState({
    required this.rooms,
    required this.currentRoomIndex,
    required this.score,
    required this.lives,
    required this.status,
    required this.usedArticleTitles,
  });

  Room get currentRoom => rooms[currentRoomIndex];
  bool get isGameOver => lives <= 0 || status == GameStatus.gameOver;
  bool get isComplete =>
      currentRoomIndex >= rooms.length || status == GameStatus.complete;
  int get roomsCompleted => rooms.where((r) => r.completed).length;

  GameState copyWith({
    List<Room>? rooms,
    int? currentRoomIndex,
    int? score,
    int? lives,
    GameStatus? status,
    Set<String>? usedArticleTitles,
  }) {
    return GameState(
      rooms: rooms ?? this.rooms,
      currentRoomIndex: currentRoomIndex ?? this.currentRoomIndex,
      score: score ?? this.score,
      lives: lives ?? this.lives,
      status: status ?? this.status,
      usedArticleTitles: usedArticleTitles ?? this.usedArticleTitles,
    );
  }

  GameState answerQuestion({required bool correct}) {
    final updatedRooms = List<Room>.from(rooms);
    updatedRooms[currentRoomIndex] = updatedRooms[currentRoomIndex].copyWith(
      completed: true,
      answeredCorrectly: correct,
    );

    final newScore = correct ? score + 10 : score;
    final newLives = correct ? lives : lives - 1;

    final isNowGameOver = newLives <= 0;
    final isNowComplete =
        !isNowGameOver && currentRoomIndex >= rooms.length - 1;

    return copyWith(
      rooms: updatedRooms,
      score: newScore,
      lives: newLives,
      status: isNowGameOver
          ? GameStatus.gameOver
          : isNowComplete
              ? GameStatus.complete
              : GameStatus.answerRevealed,
    );
  }

  GameState advanceRoom() {
    if (isGameOver || isComplete) return this;
    final nextIndex = currentRoomIndex + 1;
    if (nextIndex >= rooms.length) {
      return copyWith(status: GameStatus.complete);
    }
    return copyWith(
      currentRoomIndex: nextIndex,
      status: GameStatus.loading,
    );
  }

  GameState markLoading() => copyWith(status: GameStatus.loading);
  GameState markPlaying() => copyWith(status: GameStatus.playing);

  @override
  String toString() =>
      'GameState(room: $currentRoomIndex, score: $score, lives: $lives, status: $status)';
}
