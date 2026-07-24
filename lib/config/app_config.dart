import 'package:flutter_dotenv/flutter_dotenv.dart';

enum Environment { dev, prod }

class AppConfig {
  static Environment _currentEnv = Environment.dev;

  static Environment get currentEnv => _currentEnv;

  static void setEnvironment(Environment env) {
    _currentEnv = env;
  }

  static String get baseUrl {
    switch (_currentEnv) {
      case Environment.dev:
        return 'http://localhost:8080';
      case Environment.prod:
        // Homebase is the renamed/redeployed job-runner-server — same
        // Render service. Update this if it's ever redeployed elsewhere.
        return 'https://job-runner-3sjl.onrender.com';
    }
  }

  static bool get isDev => _currentEnv == Environment.dev;
  static bool get isProd => _currentEnv == Environment.prod;

  // ── External services ────────────────────────────────────────────────
  static const String gasUrl =
      'https://script.google.com/macros/s/AKfycbw7YNMxP4TfqIgdw09sdTbUJFp1YPAcHbRe6Oc8MWsoRF-bhLBszRaV1YG-PC6ohWc/exec';

  static String get gasSecret => dotenv.env['GAS_SECRET'] ?? '';
}
