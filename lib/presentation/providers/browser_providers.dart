import 'package:flutter/material.dart';

import '../../data/repositories/browser_repository_impl.dart';
import '../../data/services/ai_summary_service.dart';
import '../../domain/entities/page_summary.dart';

class SummaryState {
  final String? summary;
  final bool isLoading;
  final String? error;
  final Map<String, dynamic>? analysis;

  SummaryState({
    this.summary,
    this.isLoading = false,
    this.error,
    this.analysis,
  });

  SummaryState copyWith({
    String? summary,
    bool? isLoading,
    String? error,
    Map<String, dynamic>? analysis,
  }) {
    return SummaryState(
      summary: summary ?? this.summary,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      analysis: analysis ?? this.analysis,
    );
  }
}

class SummaryProvider extends ChangeNotifier {
  final BrowserRepositoryImpl repository;
  final AISummaryService aiService;
  SummaryState _state = SummaryState();

  SummaryProvider(this.repository, this.aiService);

  SummaryState get state => _state;

  Future<void> generateSummary(String url, String pageText) async {
    // Check cache first
    final cached = repository.getCachedSummary(url);
    if (cached != null) {
      _state = _state.copyWith(
        summary: cached.summary,
        analysis: {'language': cached.language, 'keywords': cached.keywords},
      );
      notifyListeners();
      return;
    }

    _state = _state.copyWith(isLoading: true, error: null);
    notifyListeners();

    try {
      final summary = await aiService.summarizeText(url, pageText);
      final analysis = await aiService.analyzeContent(pageText);

      final pageSummary = PageSummary(
        url: url,
        summary: summary,
        cachedAt: DateTime.now(),
        language: analysis['language'],
        keywords: List<String>.from(analysis['keywords'] ?? []),
      );

      await repository.cacheSummary(pageSummary);

      _state = _state.copyWith(
        summary: summary,
        isLoading: false,
        analysis: analysis,
      );
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(isLoading: false, error: e.toString());
      notifyListeners();
    }
  }

  void clearSummary() {
    _state = SummaryState();
    notifyListeners();
  }
}
