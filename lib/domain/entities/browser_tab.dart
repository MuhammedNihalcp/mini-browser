class BrowserTab {
  final String id;
  final String url;
  final String title;
  final DateTime createdAt;
  final String? faviconUrl;

  BrowserTab({
    required this.id,
    required this.url,
    required this.title,
    required this.createdAt,
    this.faviconUrl,
  });

  BrowserTab copyWith({String? url, String? title, String? faviconUrl}) {
    return BrowserTab(
      id: id,
      url: url ?? this.url,
      title: title ?? this.title,
      createdAt: createdAt,
      faviconUrl: faviconUrl ?? this.faviconUrl,
    );
  }
}
