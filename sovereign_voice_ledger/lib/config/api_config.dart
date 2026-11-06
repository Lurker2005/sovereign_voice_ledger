
class ApiConfig {
  // Change your computer's IP address only here.
  static const String baseUrl = 'http://192.168.1.2:5000';

  static String get shopUrl => '$baseUrl/shops';
  static String get productUrl => '$baseUrl/products';
  static String get customerUrl => '$baseUrl/customers';
  static String get transactionUrl => '$baseUrl/transactions';
  static String get voiceUrl => '$baseUrl/voice';
}
