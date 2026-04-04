/// A Wikipedia article the player opened during a playthrough.
class NotebookEntry {
  final String articleTitle;
  final String articleUrl;
  final String topicId;
  final DateTime visitedAt;

  const NotebookEntry({
    required this.articleTitle,
    required this.articleUrl,
    required this.topicId,
    required this.visitedAt,
  });

  Map<String, dynamic> toJson() => {
        'articleTitle': articleTitle,
        'articleUrl': articleUrl,
        'topicId': topicId,
        'visitedAt': visitedAt.toIso8601String(),
      };

  factory NotebookEntry.fromJson(Map<String, dynamic> json) => NotebookEntry(
        articleTitle: json['articleTitle'] as String,
        articleUrl: json['articleUrl'] as String,
        topicId: json['topicId'] as String,
        visitedAt: DateTime.parse(json['visitedAt'] as String),
      );
}
