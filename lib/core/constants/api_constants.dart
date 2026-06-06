class ApiConstants {
  ApiConstants._();

  // ── Base URL ──────────────────────────────────────────────────
  // Replace with your actual backend URL in production.
  static const String baseUrl = 'https://your-backend.com/api';

  // ── Auth ──────────────────────────────────────────────────────
  static const String auth = '/auth';
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String googleAuth = '/auth/google';
  static const String refreshToken = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';

  // ── Roadmaps ──────────────────────────────────────────────────
  static const String roadmaps = '/roadmaps';
  static String roadmapById(String id) => '/roadmaps/$id';
  static String roadmapLevels(String id) => '/roadmaps/$id/levels';

  // ── Levels ────────────────────────────────────────────────────
  static const String levels = '/levels';
  static String levelById(String id) => '/levels/$id';
  static String completeLevel(String id) => '/levels/$id/complete';
  static String verifyLevel(String id) => '/levels/$id/verify';

  // ── AI ────────────────────────────────────────────────────────
  static const String ai = '/ai';
  static const String aiGenerateRoadmap = '/ai/generate-roadmap';
  static const String aiCoach = '/ai/coach';
  static const String aiOcr = '/ai/ocr';
  static const String aiQuiz = '/ai/quiz';

  // ── Social ────────────────────────────────────────────────────
  static const String social = '/social';
  static const String friends = '/social/friends';
  static const String leaderboard = '/social/leaderboard';
  static const String addFriend = '/social/friends/add';
  static String acceptFriendRequest(String userId) =>
      '/social/friends/accept/$userId';
  static String removeFriend(String userId) =>
      '/social/friends/$userId';

  // ── Coach ─────────────────────────────────────────────────────
  static const String coach = '/coach';
  static const String coachHistory = '/coach/history';

  // ── Profile ───────────────────────────────────────────────────
  static const String profile = '/profile';
  static const String updateProfile = '/profile/update';
  static const String uploadAvatar = '/profile/avatar';
  static const String badges = '/profile/badges';
  static const String stats = '/profile/stats';

  // ── Notifications ─────────────────────────────────────────────
  static const String notifications = '/notifications';
  static const String registerDevice = '/notifications/device';

  // ── Timeouts ─────────────────────────────────────────────────
  static const int connectTimeoutMs = 30000;
  static const int receiveTimeoutMs = 60000;
  static const int sendTimeoutMs = 30000;

  // ── Headers ──────────────────────────────────────────────────
  static const String authHeader = 'Authorization';
  static const String contentType = 'application/json';
  static const String tokenPrefix = 'Bearer';
}
