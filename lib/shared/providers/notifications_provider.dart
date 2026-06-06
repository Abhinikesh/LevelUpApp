import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppNotification {
  final String id;
  final String title;
  final String body;
  final IconData icon;
  final Color color;
  final DateTime time;
  bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.icon,
    required this.color,
    required this.time,
    this.isRead = false,
  });

  String get timeAgo {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class NotificationsState {
  final List<AppNotification> notifications;
  const NotificationsState({this.notifications = const []});
  int get unreadCount => notifications.where((n) => !n.isRead).length;

  NotificationsState copyWith(List<AppNotification>? notifications) =>
      NotificationsState(notifications: notifications ?? this.notifications);
}

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  NotificationsNotifier() : super(const NotificationsState()) {
    _init();
  }

  void _init() {
    final now = DateTime.now();
    state = state.copyWith([
      AppNotification(
        id: 'n1',
        title: '🔥 7-Day Streak!',
        body: 'You\'re on fire! Keep your streak alive today.',
        icon: Icons.local_fire_department,
        color: const Color(0xFFFF8C00),
        time: now.subtract(const Duration(minutes: 20)),
      ),
      AppNotification(
        id: 'n2',
        title: 'Level Complete!',
        body: 'You completed "Two Pointers" and earned 150 XP!',
        icon: Icons.check_circle,
        color: const Color(0xFF43E97B),
        time: now.subtract(const Duration(hours: 2)),
        isRead: true,
      ),
      AppNotification(
        id: 'n3',
        title: 'Alex Kim accepted your request',
        body: 'You and Alex Kim are now friends. See their progress!',
        icon: Icons.person,
        color: const Color(0xFF6C63FF),
        time: now.subtract(const Duration(hours: 5)),
      ),
      AppNotification(
        id: 'n4',
        title: '⭐ New Badge Earned',
        body: 'You unlocked the "Deep Thinker" badge. Check your profile!',
        icon: Icons.star,
        color: const Color(0xFFFFB800),
        time: now.subtract(const Duration(days: 1)),
        isRead: true,
      ),
      AppNotification(
        id: 'n5',
        title: 'Weekly Summary',
        body: 'This week: 3 levels completed, 450 XP earned, 7-day streak maintained.',
        icon: Icons.bar_chart,
        color: const Color(0xFF6C63FF),
        time: now.subtract(const Duration(days: 2)),
        isRead: true,
      ),
    ]);
  }

  void markRead(String id) {
    final updated = state.notifications.map((n) {
      if (n.id == id) n.isRead = true;
      return n;
    }).toList();
    state = state.copyWith(updated);
  }

  void markAllRead() {
    final updated = state.notifications.map((n) {
      n.isRead = true;
      return n;
    }).toList();
    state = state.copyWith(updated);
  }

  void dismiss(String id) {
    state = state.copyWith(
        state.notifications.where((n) => n.id != id).toList());
  }
}

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>(
        (ref) => NotificationsNotifier());
