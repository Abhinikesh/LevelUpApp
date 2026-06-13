import 'package:shared_preferences/shared_preferences.dart';

class ApiConstants {
  static String baseUrl = "http://10.66.71.97:8000/api";
  static String wsUrl = "ws://localhost:8000";

  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUrl = prefs.getString('custom_api_base_url');
      final isDemoMode = prefs.getBool('is_demo_mode') ?? false;

      if (isDemoMode) {
        baseUrl = "";
      } else if (savedUrl != null) {
        baseUrl = savedUrl;
      } else {
        baseUrl = "http://10.66.71.97:8000/api";
      }

      if (baseUrl.isNotEmpty) {
        final uri = Uri.tryParse(baseUrl);
        if (uri != null) {
          final host = uri.host;
          final port = uri.port;
          wsUrl = "ws://$host:$port";
        }
      } else {
        wsUrl = "ws://localhost:8000";
      }
    } catch (_) {}
  }

  // ── HTTP config ─────────────────────────────────────────────
  static const int connectTimeoutMs = 30000;
  static const int receiveTimeoutMs = 60000;
  static const int sendTimeoutMs    = 30000;
  static const String contentType   = "application/json";
  static const String authHeader    = "Authorization";
  static const String tokenPrefix   = "Bearer";

  // ── Auth ────────────────────────────────────────────────────
  static const String login         = "/auth/login";
  static const String register      = "/auth/register";
  static const String googleLogin   = "/auth/google";
  static const String me            = "/auth/me";
  static const String logout        = "/auth/logout";
  static const String refreshToken  = "/auth/refresh";

  // ── Roadmaps & Levels ────────────────────────────────────────
  static const String roadmaps      = "/roadmaps";
  static String roadmapById(String id)    => "/roadmaps/$id";
  static String roadmapLevels(String id)  => "/levels/roadmap/$id";
  static String completeLevel(String id)  => "/levels/$id/complete";

  // ── Social ───────────────────────────────────────────────────
  static const String friends       = "/social/friends";
  static const String addFriend     = "/social/friends/add";
  static const String leaderboard   = "/social/leaderboard";
  static String acceptFriendRequest(String id) => "/social/friends/accept/$id";
  static String removeFriend(String id)        => "/social/friends/$id";

  // ── Users / Profile ──────────────────────────────────────────
  static const String profile           = "/users/profile";
  static const String userMe            = "/users/me";
  static const String history           = "/users/history";
  static const String trophies          = "/users/trophies";
  static const String badges            = "/users/badges";
  static const String activityCalendar  = "/users/activity-calendar";

  // ── Notifications ────────────────────────────────────────────
  static const String notifications         = "/notifications";
  static const String notificationsUnread   = "/notifications/unread-count";
  static const String notificationsReadAll  = "/notifications/read-all";
  static String notificationRead(String id) => "/notifications/$id/read";
  static String notificationDelete(String id) => "/notifications/$id";
  static const String notificationToken     = "/notifications/token";
  static const String notificationPrefs     = "/notifications/prefs";

  // ── AI & Coach ──────────────────────────────────────────────
  static const String generateRoadmap   = "/ai/generate-roadmap";
  static const String coachChat         = "/coach/chat";
}
