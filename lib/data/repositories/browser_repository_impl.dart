import 'package:hive_flutter/hive_flutter.dart';

import '../../domain/entities/browser_tab.dart';
import '../../domain/entities/page_summary.dart';
import '../models/browser_tab_model/browser_tab_model.dart';
import '../models/page_summary_model/page_summary_model.dart';

class BrowserRepositoryImpl {
  late Box<BrowserTabModel> _tabsBox;
  late Box<PageSummaryModel> _summaryBox;

  Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(BrowserTabModelAdapter());
    Hive.registerAdapter(PageSummaryModelAdapter());

    _tabsBox = await Hive.openBox<BrowserTabModel>('browser_tabs');
    _summaryBox = await Hive.openBox<PageSummaryModel>('page_summaries');
  }

  // Tab operations
  Future<void> saveTabs(List<BrowserTab> tabs) async {
    await _tabsBox.clear();
    for (var tab in tabs) {
      await _tabsBox.put(tab.id, BrowserTabModel.fromEntity(tab));
    }
  }

  List<BrowserTab> loadTabs() {
    return _tabsBox.values.map((model) => model.toEntity()).toList();
  }

  // Summary operations
  Future<void> cacheSummary(PageSummary summary) async {
    await _summaryBox.put('summary.url', PageSummaryModel.fromEntity(summary));
  }

  PageSummary? getCachedSummary(String url) {
    final model = _summaryBox.get(url);
    return model?.toEntity();
  }

  Future<void> clearOldCache() async {
    final now = DateTime.now();
    final keysToDelete = <String>[];

    for (var entry in _summaryBox.toMap().entries) {
      if (now.difference(entry.value.cachedAt).inDays > 7) {
        keysToDelete.add(entry.key);
      }
    }

    for (var key in keysToDelete) {
      await _summaryBox.delete(key);
    }
  }
}
