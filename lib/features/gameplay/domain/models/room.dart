class RoomTheme {
  final String id;
  final String name;
  final List<String> wikiTopics;

  const RoomTheme({
    required this.id,
    required this.name,
    required this.wikiTopics,
  });
}

class Room {
  final int index;
  final RoomTheme theme;
  final bool completed;
  final bool? answeredCorrectly;

  const Room({
    required this.index,
    required this.theme,
    this.completed = false,
    this.answeredCorrectly,
  });

  Room copyWith({
    bool? completed,
    bool? answeredCorrectly,
  }) {
    return Room(
      index: index,
      theme: theme,
      completed: completed ?? this.completed,
      answeredCorrectly: answeredCorrectly ?? this.answeredCorrectly,
    );
  }

  String get name => theme.name;
  String get id => theme.id;
}
