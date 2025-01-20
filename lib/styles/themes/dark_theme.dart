import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wall/styles/text_styles.dart';

final darkTheme = ThemeData.dark().copyWith(
  primaryColor: Colors.blueGrey[700],
  scaffoldBackgroundColor: const Color(0xFF121212),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF1F1F1F),
    elevation: 0,
    iconTheme: IconThemeData(color: Colors.white),
  ),
  colorScheme: ColorScheme.dark(
    primary: Colors.blueGrey[700]!,
    secondary: Colors.red,
    surface: const Color(0xFF1E1E1E),
    background: const Color(0xFF121212),
    error: Colors.redAccent[700]!,
  ),
  cardTheme: const CardTheme(
    color: Color(0xFF1E1E1E),
    elevation: 4,
  ),
  textTheme: TextTheme(
    headlineLarge: BwhiteTextStyle,
    headlineMedium: BwhiteTextStyle,
    bodyLarge: BwhiteTextStyle,
    bodyMedium: MwhiteTextStyle,
  ),
  buttonTheme: ButtonThemeData(
    buttonColor: Colors.blueGrey[700],
    textTheme: ButtonTextTheme.primary,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  ),
  iconTheme: const IconThemeData(color: Colors.white),
  inputDecorationTheme: InputDecorationTheme(
    fillColor: Colors.grey[800],
    filled: true,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none,
    ),
    labelStyle:
        const TextStyle(color: Colors.white70, fontFamily: 'Montserrat'),
  ),
  dividerColor: Colors.grey[100],
);

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeProvider() {
    _loadTheme();
  }

  ThemeMode get themeMode => _themeMode;

  void toggleTheme() async {
    if (_themeMode == ThemeMode.light) {
      _themeMode = ThemeMode.dark;
      await _saveTheme(ThemeMode.dark);
    } else {
      _themeMode = ThemeMode.light;
      await _saveTheme(ThemeMode.light);
    }
    notifyListeners();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final theme = prefs.getString('theme') ?? 'light';
    if (theme == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.light;
    }
    notifyListeners();
  }

  Future<void> _saveTheme(ThemeMode themeMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'theme', themeMode == ThemeMode.light ? 'light' : 'dark');
  }
}
