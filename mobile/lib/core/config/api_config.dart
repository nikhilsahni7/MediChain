class ApiConfig {
  // Base API URL
  static const String baseUrl =
      'http://192.168.1.100:6000/api'; // Update with your actual IP and port

  // API endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String medicines = '/medicines';
  static const String orders = '/orders';
  static const String hospitals = '/hospitals';
}
