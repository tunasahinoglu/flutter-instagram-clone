import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wall/firebase_options.dart';
import 'package:wall/pages/splash_screen.dart';
import 'package:wall/styles/themes/dark_theme.dart';
import 'package:timeago/timeago.dart' as timeago;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
   await EasyLocalization.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  timeago.setLocaleMessages('en', timeago.EnMessages());
  timeago.setLocaleMessages('tr', timeago.TrMessages());
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: EasyLocalization(
        supportedLocales: [const Locale('en', 'US'), const Locale('tr', 'TR')],
        path: 'assets/translations',
        fallbackLocale: const Locale('en', 'US'),
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          theme: ThemeData.light().copyWith(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            colorScheme: ThemeData.light().colorScheme.copyWith(
              secondary: Colors.red,
            ),
          ),
          darkTheme: darkTheme,
          themeMode: themeProvider.themeMode,
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          debugShowCheckedModeBanner: false,
          title: 'Material App',
          home: const SplashScreen(duration: 1000,),
        );
      },
    );
  }
}