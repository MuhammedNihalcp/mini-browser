import 'package:hive/hive.dart';

import '../../../domain/entities/browser_tab.dart';

part 'browser_tab_model.g.dart';

@HiveType(typeId: 0)
class BrowserTabModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String url;

  @HiveField(2)
  String title;

  @HiveField(3)
  DateTime createdAt;

  @HiveField(4)
  String? faviconUrl;

  BrowserTabModel({
    required this.id,
    required this.url,
    required this.title,
    required this.createdAt,
    this.faviconUrl,
  });

  BrowserTab toEntity() {
    return BrowserTab(
      id: id,
      url: url,
      title: title,
      createdAt: createdAt,
      faviconUrl: faviconUrl,
    );
  }

  static BrowserTabModel fromEntity(BrowserTab tab) {
    return BrowserTabModel(
      id: tab.id,
      url: tab.url,
      title: tab.title,
      createdAt: tab.createdAt,
      faviconUrl: tab.faviconUrl,
    );
  }
}
