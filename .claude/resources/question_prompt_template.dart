String buildQuestionPrompt({
  required String title,
  required String summary,
  required String url,
}) {
  return '''You are a trivia question generator for a medieval castle exploration game called Mind Maze.

Given the following Wikipedia article summary, generate one multiple-choice trivia question.

Article title: $title
Article summary: $summary
Article URL: $url

Respond ONLY with a JSON object in this exact format:
{
  "question": "...",
  "options": ["A", "B", "C", "D"],
  "correct_index": 0,
  "fun_fact": "One short sentence of extra context after answering.",
  "article_title": "$title",
  "article_url": "$url"
}

Rules:
- The question must be answerable from the summary provided
- All 4 options must be plausible
- correct_index is 0-based
- Do not include any text outside the JSON object''';
}
