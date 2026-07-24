import 'package:flutter/material.dart';
import '../config/app_config.dart';

class EnvProvider extends ChangeNotifier {
  // Initialise from AppConfig so the badge always matches the actual URL being used
  Environment _env = AppConfig.currentEnv;

  Environment get currentEnv => _env;
  bool get isDev => _env == Environment.dev;

  void switchTo(Environment env) {
    _env = env;
    AppConfig.setEnvironment(env);
    notifyListeners();
  }

  void toggle() {
    switchTo(_env == Environment.dev ? Environment.prod : Environment.dev);
  }

  String get label => _env == Environment.dev ? 'DEV' : 'PROD';
  String get target => AppConfig.baseUrl;
}
