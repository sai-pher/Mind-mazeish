class Question {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String funFact;
  final String articleTitle;
  final String articleUrl;

  const Question({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.funFact,
    required this.articleTitle,
    required this.articleUrl,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      question: json['question'] as String,
      options: List<String>.from(json['options'] as List),
      correctIndex: json['correct_index'] as int,
      funFact: json['fun_fact'] as String,
      articleTitle: json['article_title'] as String,
      articleUrl: json['article_url'] as String,
    );
  }

  bool isCorrect(int selectedIndex) => selectedIndex == correctIndex;

  @override
  String toString() =>
      'Question(question: $question, correctIndex: $correctIndex)';
}
