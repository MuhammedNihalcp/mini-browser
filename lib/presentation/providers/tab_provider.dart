import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../data/repositories/browser_repository_impl.dart';
import '../../domain/entities/browser_tab.dart';

class TabProvider extends ChangeNotifier {
  final BrowserRepositoryImpl repository;
  List<BrowserTab> _tabs = [];
  int _activeTabIndex = 0;

  TabProvider(this.repository) {
    _loadTabs();
  }

  List<BrowserTab> get tabs => _tabs;
  int get activeTabIndex => _activeTabIndex;
  BrowserTab? get activeTab => _tabs.isNotEmpty ? _tabs[_activeTabIndex] : null;

  void _loadTabs() {
    final loadedTabs = repository.loadTabs();
    if (loadedTabs.isEmpty) {
      addTab('https://www.google.com');
    } else {
      _tabs = loadedTabs;
      notifyListeners();
    }
  }

  void addTab(String url) {
    final newTab = BrowserTab(
      id: Uuid().v4(),
      url: url,
      title: 'New Tab',
      createdAt: DateTime.now(),
    );
    _tabs.add(newTab);
    _activeTabIndex = _tabs.length - 1;
    _saveTabs();
    notifyListeners();
  }

  void updateTab(String id, {String? url, String? title, String? faviconUrl}) {
    final index = _tabs.indexWhere((tab) => tab.id == id);
    if (index != -1) {
      _tabs[index] = _tabs[index].copyWith(
        url: url,
        title: title,
        faviconUrl: faviconUrl,
      );
      _saveTabs();
      notifyListeners();
    }
  }

  void closeTab(String id) {
    if (_tabs.length > 1) {
      final index = _tabs.indexWhere((tab) => tab.id == id);
      if (index != -1) {
        _tabs.removeAt(index);
        if (_activeTabIndex >= _tabs.length) {
          _activeTabIndex = (_tabs.length - 1).clamp(0, _tabs.length - 1);
        }
        _saveTabs();
        notifyListeners();
      }
    }
  }

  void setActiveTabIndex(int index) {
    if (index >= 0 && index < _tabs.length) {
      _activeTabIndex = index;
      notifyListeners();
    }
  }

  void _saveTabs() {
    repository.saveTabs(_tabs);
  }
}
