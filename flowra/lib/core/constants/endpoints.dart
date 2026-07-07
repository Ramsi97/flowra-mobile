class Endpoints {
  // Use 10.0.2.2 for Android emulator pointing to localhost.
  // Use your computer's local IP (e.g. 192.168.x.x) if running on a physical device.
  static const String baseUrl = 'https://unorderly-nannette-preadequately.ngrok-free.dev';

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String updateProfile = '/auth/profile';

  // Tasks
  static const String tasks = '/tasks';
  static String task(String id) => '/tasks/$id';
  static const String suggestTasks = '/tasks/ai/suggest';
  static const String refineTasks = '/tasks/ai/chat';

  // Schedule
  static const String generateSchedule = '/schedule/generate';
  static const String regenerateSchedule = '/schedule/regenerate';
  static String scheduleItem(String id) => '/schedule/item/$id';
  static const String fixSchedule = '/schedule/fix';
  static const String aiSchedule = '/schedule/ai/generate';
  static String removeTask(String id) => '/schedule/task/$id';
  static String clearDay(String date) => '/schedule/day?date=$date';
  static String clearWeek(String startDate) => '/schedule/week?start=$startDate';
  static String clearMonth(String month) => '/schedule/month?month=$month';

  // Focus
  static const String focusStatus = '/focus/status';
  static const String focusConfig = '/focus/config';
}
