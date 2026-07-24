import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';


class NotificationProvider extends ChangeNotifier {

  bool _notificationsEnabled = true;


  bool get notificationsEnabled => _notificationsEnabled;


  NotificationProvider() {

    loadNotificationSetting();

  }


  void toggleNotifications(bool value) async {

    _notificationsEnabled = value;

    notifyListeners();


    final prefs = await SharedPreferences.getInstance();


    await prefs.setBool(
      "notifications",
      value,
    );

  }


  void loadNotificationSetting() async {

    final prefs = await SharedPreferences.getInstance();


    _notificationsEnabled =
        prefs.getBool("notifications") ?? true;


    notifyListeners();

  }

}