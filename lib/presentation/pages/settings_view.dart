import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../main.dart';
import '../providers/tab_provider.dart';
import '../providers/theme_provider.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Settings')),
      body: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return ListView(
            children: [
              SwitchListTile(
                title: Text('Dark Mode'),
                subtitle: Text('Toggle dark theme'),
                value: themeProvider.isDarkMode,
                onChanged: (value) {
                  themeProvider.setTheme(value);
                },
              ),
              ListTile(
                title: Text('Clear Cache'),
                subtitle: Text('Remove cached summaries'),
                leading: Icon(Icons.delete_outline),
                onTap: () async {
                  final repository = Provider.of<TabProvider>(
                    context,
                    listen: false,
                  ).repository;
                  await repository.clearOldCache();
                  ScaffoldMessenger.of(
                    navigatorKey.currentContext!,
                  ).showSnackBar(SnackBar(content: Text('Cache cleared!')));
                },
              ),
              ListTile(
                title: Text('About'),
                subtitle: Text('Version 1.0.0'),
                leading: Icon(Icons.info_outline),
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'Mini Browser',
                    applicationVersion: '1.0.0',
                    applicationIcon: Icon(Icons.web, size: 48),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
