class MazePosition {
  final int x;
  final int y;

  const MazePosition(this.x, this.y);

  @override
  bool operator ==(Object other) =>
      other is MazePosition && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => '($x,$y)';
}
