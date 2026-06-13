import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_interceptors.dart';
import '../../core/network/dio_client.dart';

// ─── Model ──────────────────────────────────────────────────────────────────

class AppNotification {
  final String id;
  final String title;
  final String body;
  final String type; // level_complete | badge_earned | roadmap_created | friend_request | friend_accepted | streak_reminder | general
  final String? refId;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.refId,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id:        json['_id'] as String? ?? json['id'] as String? ?? '',
      title:     json['title'] as String? ?? '',
      body:      json['body'] as String? ?? json['message'] as String? ?? '',
      type:      json['type'] as String? ?? 'general',
      refId:     json['refId'] as String?,
      isRead:    json['isRead'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  AppNotification copyWith({bool? isRead}) => AppNotification(
        id:        id,
        title:     title,
        body:      body,
        type:      type,
        refId:     refId,
        isRead:    isRead ?? this.isRead,
        createdAt: createdAt,
      );

  // Derive icon and color from type — no emoji-as-icon, only Material Icons
  IconData get icon {
    switch (type) {
      case 'level_complete':     return Icons.check_circle_rounded;
      case 'badge_earned':       return Icons.emoji_events_rounded;
      case 'roadmap_created':    return Icons.map_rounded;
      case 'friend_request':     return Icons.person_add_rounded;
      case 'friend_accepted':    return Icons.people_rounded;
      case 'streak_reminder':    return Icons.local_fire_department_rounded;
      default:                   return Icons.notifications_rounded;
    }
  }

  Color get color {
    switch (type) {
      case 'level_complete':     return const Color(0xFF43E97B);
      case 'badge_earned':       return const Color(0xFFFFB800);
      case 'roadmap_created':    return const Color(0xFF6C63FF);
      case 'friend_request':     return const Color(0xFF6C63FF);
      case 'friend_accepted':    return const Color(0xFF38F9D7);
      case 'streak_reminder':    return const Color(0xFFFF8C00);
      default:                   return const Color(0xFF9898B8);
    }
  }

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1)  return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)   return '${diff.inHours}h ago';
    if (diff.inDays < 7)     return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }
}

// ─── State ──────────────────────────────────────────────────────────────────

class NotificationsState {
  final List<AppNotification> notifications;
  final bool isLoading;
  final String? error;

  const NotificationsState({
    this.notifications = const [],
    this.isLoading = false,
    this.error,
  });

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  NotificationsState copyWith({
    List<AppNotification>? notifications,
    bool? isLoading,
    String? error,
  }) =>
      NotificationsState(
        notifications: notifications ?? this.notifications,
        isLoading:     isLoading ?? this.isLoading,
        error:         error,
      );
}

// ─── Notifier ───────────────────────────────────────────────────────────────

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  final Dio _dio;

  NotificationsNotifier(this._dio) : super(const NotificationsState()) {
    fetchNotifications();
  }

  /// Load all notifications from the API
  Future<void> fetchNotifications() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _dio.get(ApiConstants.notifications);
      final data = res.data as Map<String, dynamic>;
      if (data['success'] == true) {
        final raw = (data['notifications'] as List<dynamic>?) ?? [];
        final list = raw
            .map((j) => AppNotification.fromJson(j as Map<String, dynamic>))
            .toList();
        state = state.copyWith(notifications: list, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false, error: 'Failed to fetch notifications');
      }
    } on DioException catch (e) {
      final ex = ApiException.fromDioError(e);
      state = state.copyWith(isLoading: false, error: ex.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to load notifications');
    }
  }

  /// Mark a single notification as read (optimistic + API)
  Future<void> markRead(String id) async {
    // Optimistic update
    final updated = state.notifications
        .map((n) => n.id == id ? n.copyWith(isRead: true) : n)
        .toList();
    state = state.copyWith(notifications: updated);

    try {
      await _dio.put(ApiConstants.notificationRead(id));
    } catch (_) {
      // Silently ignore — optimistic update already applied
    }
  }

  /// Mark ALL as read (optimistic + API)
  Future<void> markAllRead() async {
    final updated = state.notifications
        .map((n) => n.copyWith(isRead: true))
        .toList();
    state = state.copyWith(notifications: updated);

    try {
      await _dio.put(ApiConstants.notificationsReadAll);
    } catch (_) {}
  }

  /// Delete a notification (optimistic + API)
  Future<void> dismiss(String id) async {
    state = state.copyWith(
      notifications: state.notifications.where((n) => n.id != id).toList(),
    );
    try {
      await _dio.delete(ApiConstants.notificationDelete(id));
    } catch (_) {}
  }
}

// ─── Providers ──────────────────────────────────────────────────────────────

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>(
        (ref) => NotificationsNotifier(DioClient.instance));

/// Lightweight provider to fetch only the unread count for the bell badge
final unreadNotificationCountProvider = FutureProvider<int>((ref) async {
  try {
    final res = await DioClient.instance.get(ApiConstants.notificationsUnread);
    final data = res.data as Map<String, dynamic>?;
    return (data?['count'] as num?)?.toInt() ?? 0;
  } catch (_) {
    return 0;
  }
});
