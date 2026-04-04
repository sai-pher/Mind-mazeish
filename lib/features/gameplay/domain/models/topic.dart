// Three-level topic hierarchy: SuperCategory → Category → Topic
// A node at any level can be selected in the topic picker.

class SuperCategory {
  final String id;
  final String name;
  final String emoji;
  final List<TopicCategory> categories;

  const SuperCategory({
    required this.id,
    required this.name,
    required this.emoji,
    required this.categories,
  });

  /// Flat list of all leaf [Topic]s within this super-category.
  List<Topic> get allTopics =>
      categories.expand((c) => c.topics).toList();

  List<String> get allTopicIds => allTopics.map((t) => t.id).toList();
}

class TopicCategory {
  final String id;
  final String name;
  final String superCategoryId;
  final List<Topic> topics;

  const TopicCategory({
    required this.id,
    required this.name,
    required this.superCategoryId,
    required this.topics,
  });

  List<String> get topicIds => topics.map((t) => t.id).toList();
}

class Topic {
  final String id;
  final String name;
  final String categoryId;
  final String emoji;

  const Topic({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.emoji,
  });
}
