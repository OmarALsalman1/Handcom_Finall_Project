import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'shared/widgets/theme_provider.dart';
import 'shared/widgets/locale_provider.dart';
import 'providers/user_auth_provider.dart';
import 'features/auth/screens/user_type_screen.dart';
import 'features/auth/screens/home_page.dart';
import 'features/auth/screens/provider_home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final authProvider = UserAuthProvider();
  final localeProvider = LocaleProvider();
  await Future.wait([
    authProvider.loadFromStorage(),
    localeProvider.loadFromStorage(),
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider.value(value: localeProvider),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer3<ThemeProvider, UserAuthProvider, LocaleProvider>(
      builder: (context, themeProvider, authProvider, localeProvider, child) {
        Widget home;
        if (!authProvider.initialized) {
          home = const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (!authProvider.isLoggedIn) {
          home = const UserTypeScreen();
        } else if (authProvider.isProvider) {
          home = const ProviderHomePage();
        } else {
          home = const HomePage();
        }

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'HandCom',
          locale: localeProvider.locale,
          supportedLocales: const [
            Locale('ar'),
            Locale('en'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          themeMode: themeProvider.themeMode,
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            primaryColor: const Color(0xFF1A3D81),
            scaffoldBackgroundColor: Colors.white,
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            primaryColor: const Color(0xFF1A3D81),
            scaffoldBackgroundColor: const Color(0xFF121212),
          ),
          home: home,
        );
      },
    );
  }
}
