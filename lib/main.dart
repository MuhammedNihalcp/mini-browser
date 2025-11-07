import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mini_browser_app/data/services/ai_summary_service.dart'
    show AISummaryService, Summary;
import 'package:provider/provider.dart';

import 'data/repositories/browser_repository_impl.dart';
import 'presentation/pages/browser_home_page.dart';
import 'presentation/providers/browser_providers.dart';
import 'presentation/providers/tab_provider.dart';
import 'presentation/providers/theme_provider.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  // Initialize Hive
  final repository = BrowserRepositoryImpl();
  await repository.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TabProvider(repository)),
        ChangeNotifierProvider(
          create: (_) => SummaryProvider(
            repository,
            AISummaryService(
              provider: Summary.smmry,
              apiKey: String.fromEnvironment(''),
              // dotenv.env['HUGGING_FACE_API_KEY'] ?? '',
            ),
          ),
        ),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Mini Browser',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.light,
            ),
            textTheme: GoogleFonts.interTextTheme(),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.dark,
            ),
            textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
          ),
          navigatorKey: navigatorKey,
          themeMode: themeProvider.isDarkMode
              ? ThemeMode.dark
              : ThemeMode.light,
          home: BrowserHomePage(),
        );
      },
    );
  }
}
