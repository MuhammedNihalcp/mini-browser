class PageSummary {
  final String url;
  final String summary;
  final DateTime cachedAt;
  final String? language;
  final List<String>? keywords;

  PageSummary({
    required this.url,
    required this.summary,
    required this.cachedAt,
    this.language,
    this.keywords,
  });
}
