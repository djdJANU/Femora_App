// lib/main.dart
//
// Femora Application Entry Point
// Responsible only for:
// - App bootstrap
// - Environment loading
// - Supabase initialization
// - Global providers injection
// - Global theme injection
// - Initial route (Splash)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';

import 'config/app_theme.dart';
import 'screens/auth/splash_screen.dart';

// Providers
import 'providers/auth_provider.dart';
import 'providers/profile_provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'providers/locale_provider.dart';
import 'providers/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  final localeProvider = LocaleProvider();
  await localeProvider.loadSavedLocale();

  final themeProvider = ThemeProvider();
  await themeProvider.loadSavedTheme();

  runApp(FemoraApp(
    localeProvider: localeProvider,
    themeProvider: themeProvider,
  ));
}

class FemoraApp extends StatelessWidget {
  final LocaleProvider localeProvider;
  final ThemeProvider themeProvider;

  const FemoraApp({
    super.key,
    required this.localeProvider,
    required this.themeProvider,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: localeProvider),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
      ],
      child: Consumer2<LocaleProvider, ThemeProvider>(
        builder: (context, locale, theme, _) {
          return MaterialApp(
            title: 'Femora',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: theme.themeMode,
            locale: locale.locale,
            supportedLocales: LocaleProvider.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
