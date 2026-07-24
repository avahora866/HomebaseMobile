import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Homebase Mobile only ever talks to production — there is no dev/local
/// target to switch between.
class AppConfig {
  AppConfig._();

  static const String baseUrl = 'https://job-runner-3sjl.onrender.com';

  // ── External services ────────────────────────────────────────────────
  static const String gasUrl =
      'https://script.google.com/macros/s/AKfycbw7YNMxP4TfqIgdw09sdTbUJFp1YPAcHbRe6Oc8MWsoRF-bhLBszRaV1YG-PC6ohWc/exec';

  static String get gasSecret => dotenv.env['GAS_SECRET'] ?? '';
}
