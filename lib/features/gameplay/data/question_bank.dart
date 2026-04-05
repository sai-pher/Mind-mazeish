import '../domain/models/question.dart';

/// Select [count] random [QuizQuestion]s from topics in [topicIds].
/// Returns the shuffled list ready for a game session.
List<QuizQuestion> selectQuestionsFrom(
  List<Question> allQuestions, {
  required Set<String> topicIds,
  required int count,
}) {
  final pool = allQuestions
      .where((q) => topicIds.contains(q.topicId))
      .toList()
    ..shuffle();

  final selected = pool.take(count).toList();
  return selected.map((q) => q.toQuizQuestion()).toList();
}
