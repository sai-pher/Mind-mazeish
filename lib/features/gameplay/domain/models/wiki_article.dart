class WikiArticle {
  final String title;
  final String summary;
  final String url;

  const WikiArticle({
    required this.title,
    required this.summary,
    required this.url,
  });

  factory WikiArticle.fromJson(Map<String, dynamic> json) {
    final title = json['title'] as String;
    return WikiArticle(
      title: title,
      summary: json['extract'] as String? ?? '',
      url: 'https://en.m.wikipedia.org/wiki/${Uri.encodeComponent(title)}',
    );
  }

  @override
  String toString() => 'WikiArticle(title: $title)';
}
