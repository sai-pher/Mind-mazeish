import 'maze_position.dart';
import 'room_status.dart';

class MazeRoom {
  final MazePosition position;
  final String? questionId;
  final bool isThroneRoom;
  final RoomStatus status;
  final bool? answeredCorrectly;

  const MazeRoom({
    required this.position,
    this.questionId,
    this.isThroneRoom = false,
    this.status = RoomStatus.hidden,
    this.answeredCorrectly,
  });

  MazeRoom copyWith({
    RoomStatus? status,
    bool? answeredCorrectly,
  }) {
    return MazeRoom(
      position: position,
      questionId: questionId,
      isThroneRoom: isThroneRoom,
      status: status ?? this.status,
      answeredCorrectly: answeredCorrectly ?? this.answeredCorrectly,
    );
  }
}
