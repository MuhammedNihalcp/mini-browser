import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:mini_browser_app/main.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

import '../providers/browser_providers.dart';
import '../providers/tab_provider.dart';

import 'package:lottie/lottie.dart';

class BrowserView extends StatefulWidget {
  const BrowserView({super.key});

  @override
  State<BrowserView> createState() => _BrowserViewState();
}

class _BrowserViewState extends State<BrowserView>
    with TickerProviderStateMixin {
  final TextEditingController _urlController = TextEditingController();
  InAppWebViewController? _webViewController;
  double _loadingProgress = 0;
  bool _showSummary = false;
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _noInternetController;

  // Connectivity
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  bool _isConnected = true;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );
    _noInternetController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );

    // Initialize connectivity check
    _initConnectivity();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _updateConnectionStatus,
    );
  }

  Future<void> _initConnectivity() async {
    late List<ConnectivityResult> result;
    try {
      result = await _connectivity.checkConnectivity();
    } catch (e) {
      return;
    }

    if (!mounted) {
      return;
    }

    return _updateConnectionStatus(result);
  }

  void _updateConnectionStatus(List<ConnectivityResult> result) {
    setState(() {
      _isConnected = !result.contains(ConnectivityResult.none);
      if (!_isConnected) {
        _noInternetController.forward();
      } else {
        _noInternetController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _urlController.dispose();
    _slideController.dispose();
    _fadeController.dispose();
    _noInternetController.dispose();
    _connectivitySubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<TabProvider, SummaryProvider>(
      builder: (context, tabProvider, summaryProvider, child) {
        final tabs = tabProvider.tabs;
        final activeIndex = tabProvider.activeTabIndex;
        final summaryState = summaryProvider.state;

        if (tabs.isEmpty) {
          return Center(child: CircularProgressIndicator());
        }

        final activeTab = tabs[activeIndex];
        _urlController.text = activeTab.url;

        return Scaffold(
          appBar: AppBar(
            title: TextField(
              controller: _urlController,
              decoration: InputDecoration(
                hintText: 'Enter URL...',
                border: InputBorder.none,
                prefixIcon: Icon(Icons.search),
              ),
              onSubmitted: (value) {
                if (!_isConnected) {
                  _showNoInternetSnackBar();
                  return;
                }
                if (!value.startsWith('http')) {
                  value = 'https://$value';
                }
                _loadUrl(value);
              },
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () => _webViewController?.goBack(),
              ),
              IconButton(
                icon: Icon(Icons.arrow_forward),
                onPressed: () => _webViewController?.goForward(),
              ),
              IconButton(
                icon: Icon(Icons.refresh),
                onPressed: () {
                  if (!_isConnected) {
                    _showNoInternetSnackBar();
                    return;
                  }
                  _webViewController?.reload();
                },
              ),
              IconButton(
                icon: Icon(Icons.add),
                onPressed: () {
                  tabProvider.addTab('https://www.google.com');
                },
              ),
            ],
            bottom: _loadingProgress < 1.0
                ? PreferredSize(
                    preferredSize: Size.fromHeight(4),
                    child: LinearProgressIndicator(value: _loadingProgress),
                  )
                : null,
          ),
          body: Stack(
            children: [
              Column(
                children: [
                  // Tab Bar
                  SizedBox(
                    height: 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: tabs.length,
                      itemBuilder: (context, index) {
                        final tab = tabs[index];
                        final isActive = index == activeIndex;

                        return GestureDetector(
                          onTap: () {
                            tabProvider.setActiveTabIndex(index);
                          },
                          child: Container(
                            width: 150,
                            margin: EdgeInsets.all(4),
                            padding: EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? Theme.of(
                                      context,
                                    ).colorScheme.primaryContainer
                                  : Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Stack(
                              children: [
                                Center(
                                  child: Text(
                                    tab.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: isActive
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                if (tabs.length > 1)
                                  Positioned(
                                    right: 4,
                                    top: 4,
                                    child: GestureDetector(
                                      onTap: () {
                                        tabProvider.closeTab(tab.id);
                                      },
                                      child: Icon(Icons.close, size: 16),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // WebView
                  Expanded(
                    child: InAppWebView(
                      key: ValueKey(activeTab.id),
                      initialUrlRequest: URLRequest(url: WebUri(activeTab.url)),
                      onWebViewCreated: (controller) {
                        _webViewController = controller;
                      },
                      onLoadStart: (controller, url) {
                        setState(() {
                          _loadingProgress = 0;
                        });
                      },
                      onProgressChanged: (controller, progress) {
                        setState(() {
                          _loadingProgress = progress / 100;
                        });
                      },
                      onLoadStop: (controller, url) async {
                        setState(() {
                          _loadingProgress = 1.0;
                        });

                        final title = await controller.getTitle() ?? 'Untitled';
                        tabProvider.updateTab(
                          activeTab.id,
                          url: url.toString(),
                          title: title,
                        );

                        _urlController.text = url.toString();
                      },
                      onTitleChanged: (controller, title) {
                        tabProvider.updateTab(
                          activeTab.id,
                          title: title ?? 'Untitled',
                        );
                      },
                      onReceivedError: (controller, request, error) {
                        if (!_isConnected) {
                          // Connection error will be shown by overlay
                        }
                      },
                    ),
                  ),

                  // Summary Panel with Lottie Animation
                  if (_showSummary)
                    SlideTransition(
                      position:
                          Tween<Offset>(
                            begin: Offset(0, 1),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: _slideController,
                              curve: Curves.easeOut,
                            ),
                          ),
                      child: Container(
                        height: 250,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 10,
                              offset: Offset(0, -2),
                            ),
                          ],
                        ),
                        child: summaryState.isLoading
                            ? _buildLoadingAnimation()
                            : summaryState.error != null
                            ? _buildErrorState(summaryState.error!)
                            : _buildSummaryContent(summaryState),
                      ),
                    ),
                ],
              ),

              // No Internet Overlay
              if (!_isConnected)
                FadeTransition(
                  opacity: _noInternetController,
                  child: Container(
                    color: Theme.of(context).colorScheme.surface,
                    child: _buildNoInternetScreen(),
                  ),
                ),
            ],
          ),
          floatingActionButton: _isConnected
              ? FloatingActionButton.extended(
                  onPressed: () async {
                    if (!_showSummary) {
                      setState(() {
                        _showSummary = true;
                      });
                      _slideController.forward();
                      _fadeController.forward();

                      final html = await _webViewController?.getHtml();
                      if (html != null) {
                        final text = _extractTextFromHtml(html);
                        await summaryProvider.generateSummary(
                          activeTab.url,
                          text,
                        );
                      }
                    } else {
                      _slideController.reverse();
                      _fadeController.reverse();
                      await Future.delayed(Duration(milliseconds: 300));
                      setState(() {
                        _showSummary = false;
                      });
                      summaryProvider.clearSummary();
                    }
                  },
                  icon: Icon(_showSummary ? Icons.close : Icons.auto_awesome),
                  label: Text(_showSummary ? 'Close' : 'Summarize'),
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primaryContainer,
                )
              : null,
        );
      },
    );
  }

  Widget _buildNoInternetScreen() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Lottie Animation for No Internet
            SizedBox(
              height: 200,
              width: 200,
              child: Lottie.network(
                'https://assets10.lottiefiles.com/packages/lf20_u1xuufn3.json',
                // Alternative animations:
                // 'https://assets4.lottiefiles.com/packages/lf20_0s6tfbuc.json' - No WiFi
                // 'https://assets9.lottiefiles.com/packages/lf20_tbgfw2g6.json' - No Connection
                fit: BoxFit.contain,
                repeat: true,
                animate: true,
                errorBuilder: (context, error, stackTrace) {
                  return _buildFallbackNoInternetAnimation();
                },
              ),
            ),
            SizedBox(height: 24),
            Text(
              'No Internet Connection',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            Text(
              'Please check your connection and try again',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () async {
                await _initConnectivity();
                if (_isConnected && _webViewController != null) {
                  _webViewController!.reload();
                }
              },
              icon: Icon(Icons.refresh),
              label: Text('Try Again'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.wifi_off,
                  size: 16,
                  color: Theme.of(context).colorScheme.error,
                ),
                SizedBox(width: 8),
                Text(
                  'Offline Mode',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackNoInternetAnimation() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(seconds: 2),
      builder: (context, value, child) {
        return Icon(
          Icons.wifi_off,
          size: 100,
          color: Theme.of(
            context,
          ).colorScheme.error.withValues(alpha: 0.3 + (value * 0.7)),
        );
      },
    );
  }

  void _showNoInternetSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.white),
            SizedBox(width: 12),
            Text('No internet connection'),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _buildLoadingAnimation() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Lottie Animation for loading
        SizedBox(
          height: 150,
          width: double.infinity,
          child: Lottie.network(
            'https://assets10.lottiefiles.com/packages/lf20_p8bfn5to.json',
            fit: BoxFit.contain,
            repeat: true,
            animate: true,
            errorBuilder: (context, error, stackTrace) {
              return _buildFallbackLoadingAnimation();
            },
          ),
        ),
        SizedBox(height: 16),
        FadeTransition(
          opacity: _fadeController,
          child: Column(
            children: [
              Text(
                'Generating AI Summary...',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Analyzing page content',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFallbackLoadingAnimation() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(seconds: 2),
      builder: (context, value, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(value: null, strokeWidth: 3),
            Icon(
              Icons.auto_awesome,
              size: 40,
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: value),
            ),
          ],
        );
      },
    );
  }

  Widget _buildErrorState(String error) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 60,
            color: Theme.of(context).colorScheme.error,
          ),
          SizedBox(height: 16),
          Text(
            'Failed to Generate Summary',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () async {
              if (!_isConnected) {
                _showNoInternetSnackBar();
                return;
              }

              final html = await _webViewController?.getHtml();
              if (html != null) {
                final tabProvider = Provider.of<TabProvider>(
                  navigatorKey.currentContext!,
                  listen: false,
                );
                final summaryProvider = Provider.of<SummaryProvider>(
                  navigatorKey.currentContext!,
                  listen: false,
                );

                final tabs = tabProvider.tabs;
                final activeIndex = tabProvider.activeTabIndex;
                final activeTab = tabs[activeIndex];
                final text = _extractTextFromHtml(html);
                await summaryProvider.generateSummary(activeTab.url, text);
              }
            },
            icon: Icon(Icons.refresh),
            label: Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryContent(SummaryState summaryState) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: FadeTransition(
        opacity: _fadeController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.auto_awesome,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'AI Summary',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () async {
                    _slideController.reverse();
                    _fadeController.reverse();
                    await Future.delayed(Duration(milliseconds: 300));
                    setState(() {
                      _showSummary = false;
                    });
                    Provider.of<SummaryProvider>(
                      navigatorKey.currentContext!,
                      listen: false,
                    ).clearSummary();
                  },
                ),
              ],
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                summaryState.summary ?? '',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(height: 1.5),
              ),
            ),
            if (summaryState.analysis != null) ...[
              SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.label_outline,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Keywords',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    (summaryState.analysis!['keywords'] as List<String>?)
                        ?.map(
                          (keyword) => Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(
                                    context,
                                  ).colorScheme.primaryContainer,
                                  Theme.of(context).colorScheme.primaryContainer
                                      .withValues(alpha: 0.7),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              keyword,
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        )
                        .toList() ??
                    [],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.sentiment_satisfied_alt,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Sentiment: ${summaryState.analysis!['sentiment'] ?? 'neutral'}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: 16),
                  Icon(
                    Icons.language,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Language: ${summaryState.analysis!['language'] ?? 'unknown'}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _loadUrl(String url) {
    _webViewController?.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
  }

  String _extractTextFromHtml(String html) {
    return html
        .replaceAll(RegExp(r'<script[^>]*>.*?</script>', dotAll: true), '')
        .replaceAll(RegExp(r'<style[^>]*>.*?</style>', dotAll: true), '')
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .substring(0, 2000.clamp(0, html.length));
  }
}
