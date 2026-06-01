import 'package:flutter/foundation.dart';

abstract class ApiEndpoints {
  // Web (Chrome): localhost:8000
  // Android emulator: set --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
  // Physical device: set --dart-define=API_BASE_URL=http://<your-ip>:8000/api/v1
  // Production: set --dart-define=API_BASE_URL=https://api.kundliai.com/api/v1
  static String get baseUrl {
    const env = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (env.isNotEmpty) return env;
    if (kIsWeb) return 'http://localhost:8000/api/v1';
    return 'http://10.0.2.2:8000/api/v1';
  }

  // Auth
  static const authVerify = '/auth/verify';
  static const authMe     = '/auth/me';

  // Users
  static const usersMe        = '/users/me';
  static const usersClearChat = '/users/me/clear-chat';

  // Birth chart
  static const birthChartCompute  = '/birth-chart/compute';
  static const birthChartGet      = '/birth-chart';
  static const birthChartGeocode  = '/birth-chart/geocode';

  // Horoscope
  static const horoscopeDaily   = '/horoscope/daily';
  static const horoscopeWeekly  = '/horoscope/weekly';
  static const horoscopeMonthly = '/horoscope/monthly';
  static const horoscopeWhatsApp = '/horoscope/whatsapp';

  // Chat
  static const chatMessage = '/chat/message';
  static const chatHistory = '/chat/history';

  // Today
  static const today = '/today';

  // Insights
  static const insights     = '/insights';          // GET → all 4
  static String insight(String category) => '/insights/$category';

  // Remedies
  static const remedies = '/remedies';
  static String remedy(String title) => '/remedies/${Uri.encodeComponent(title)}';

  // Transits
  static const transits = '/transits';

  // Compatibility
  static const compatibility = '/compatibility';

  // Payments
  static const paymentCreate = '/payments/create-subscription';
  static const paymentStatus = '/payments/status';
}
