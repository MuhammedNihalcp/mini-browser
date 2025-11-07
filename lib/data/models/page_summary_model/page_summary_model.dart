import 'package:hive/hive.dart';

import '../../../domain/entities/page_summary.dart';
part 'page_summary_model.g.dart';

@HiveType(typeId: 1)
class PageSummaryModel extends HiveObject {
  @HiveField(0)
  String url;

  @HiveField(1)
  String summary;

  @HiveField(2)
  DateTime cachedAt;

  @HiveField(3)
  String? language;

  @HiveField(4)
  List<String>? keywords;

  PageSummaryModel({
    required this.url,
    required this.summary,
    required this.cachedAt,
    this.language,
    this.keywords,
  });

  PageSummary toEntity() {
    return PageSummary(
      url: url,
      summary: summary,
      cachedAt: cachedAt,
      language: language,
      keywords: keywords,
    );
  }

  static PageSummaryModel fromEntity(PageSummary summary) {
    return PageSummaryModel(
      url: summary.url,
      summary: summary.summary,
      cachedAt: summary.cachedAt,
      language: summary.language,
      keywords: summary.keywords,
    );
  }
}
