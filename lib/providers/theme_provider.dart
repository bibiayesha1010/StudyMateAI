import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';


class ThemeProvider extends ChangeNotifier {

  bool _isDarkMode = false;


  bool get isDarkMode => _isDarkMode;



  ThemeProvider() {

    loadTheme();

  }



  void toggleTheme(bool value) async {

    _isDarkMode = value;

    notifyListeners();


    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(
      "darkMode",
      value,
    );

  }




  void loadTheme() async {

    final prefs = await SharedPreferences.getInstance();


    _isDarkMode =
        prefs.getBool("darkMode") ?? false;


    notifyListeners();

  }


}