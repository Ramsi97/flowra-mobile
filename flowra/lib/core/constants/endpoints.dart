class Endpoints {
  // Use 10.0.2.2 for Android emulator pointing to localhost.
  // Use your computer's local IP (e.g. 192.168.x.x) if running on a physical device.
  static const String baseUrl = 'http://192.168.1.5:8080';

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String updateProfile = '/auth/profile';
}
