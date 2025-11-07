import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/tab_provider.dart';

class TabsView extends StatelessWidget {
  const TabsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TabProvider>(
      builder: (context, tabProvider, child) {
        final tabs = tabProvider.tabs;
        return Scaffold(
          appBar: AppBar(title: Text('All Tabs (${tabs.length})')),
          body: GridView.builder(
            padding: EdgeInsets.all(10),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
            ),
            itemCount: tabs.length,
            itemBuilder: (context, index) {
              final tab = tabs[index];
              return Card(
                child: InkWell(
                  onTap: () {
                    tabProvider.setActiveTabIndex(index);
                    // Navigator.pop(context);
                  },
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Icon(Icons.web, size: 24),
                            IconButton(
                              icon: Icon(Icons.close, size: 20),
                              onPressed: () {
                                tabProvider.closeTab(tab.id);
                              },
                            ),
                          ],
                        ),
                        Spacer(),
                        Text(
                          tab.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        SizedBox(height: 4),
                        Text(
                          tab.url,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
