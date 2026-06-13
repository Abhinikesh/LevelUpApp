import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/providers/connectivity_provider.dart';
import '../../shared/providers/dashboard_provider.dart';
import '../../shared/providers/notifications_provider.dart';
import '../../shared/providers/social_provider.dart';

/// Manages real-time data synchronization for the STEPUP app.
/// - Polls user profile and notifications when app is in foreground (every 12 seconds).
/// - Listens to connectivity changes and runs a full sync when returning online.
/// - Gracefully stops polling when app is in background to preserve battery.
class SyncManager extends WidgetsBindingObserver {
  final WidgetRef ref;
  Timer? _timer;
  ProviderSubscription? _connectivitySub;
  bool _isOnline = true;

  SyncManager(this.ref);

  void start() {
    WidgetsBinding.instance.addObserver(this);

    // 1. Listen to connectivity state changes
    _connectivitySub = ref.listenManual<AsyncValue<bool>>(
      connectivityProvider,
      (previous, next) {
        final online = next.value ?? true;
        if (online && !_isOnline) {
          debugPrint('[SyncManager] Network connection restored. Triggering full sync...');
          syncAll(forceRefresh: true);
        }
        _isOnline = online;
      },
    );

    // 2. Begin periodic foreground syncing
    _startTimer();
  }

  void stop() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _connectivitySub?.close();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 12), (timer) {
      if (_isOnline) {
        debugPrint('[SyncManager] Periodic sync tick...');
        syncLightweight();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint('[SyncManager] App resumed. Resuming sync...');
      _startTimer();
      syncAll();
    } else if (state == AppLifecycleState.paused) {
      debugPrint('[SyncManager] App paused. Suspending sync...');
      _timer?.cancel();
    }
  }

  /// Check unread notification count and user profile info.
  /// If changes are detected (e.g. fresh XP or new notification), triggers a full reload of dependent dashboards.
  Future<void> syncLightweight() async {
    try {
      final oldUser = ref.read(currentUserProvider);
      final oldUnread = ref.read(notificationsProvider).unreadCount;

      // Parallel fetch of me & notifications
      await Future.wait([
        ref.read(authProvider.notifier).getMe(),
        ref.read(notificationsProvider.notifier).fetchNotifications(),
      ]);

      final newUser = ref.read(currentUserProvider);
      final newUnread = ref.read(notificationsProvider).unreadCount;

      // Sync active view dashboard/social states if user XP, streak, or unread notification count changed
      if (oldUser?.xpTotal != newUser?.xpTotal ||
          oldUser?.streakCount != newUser?.streakCount ||
          oldUnread != newUnread) {
        debugPrint('[SyncManager] Updates detected. Updating dashboard and social metrics...');
        ref.read(dashboardProvider.notifier).loadDashboard();
        ref.invalidate(activityCalendarProvider);
        ref.read(socialProvider.notifier).fetchSocialData(forceRefresh: true);
      }
    } catch (e) {
      debugPrint('[SyncManager] Lightweight sync failed: $e');
    }
  }

  /// Triggers a full reload of auth, dashboard, notifications, and social feeds.
  Future<void> syncAll({bool forceRefresh = false}) async {
    if (!_isOnline) return;
    try {
      await Future.wait([
        ref.read(authProvider.notifier).getMe(),
        ref.read(notificationsProvider.notifier).fetchNotifications(),
        ref.read(dashboardProvider.notifier).loadDashboard(),
        ref.read(socialProvider.notifier).fetchSocialData(forceRefresh: forceRefresh),
      ]);
      ref.invalidate(activityCalendarProvider);
    } catch (e) {
      debugPrint('[SyncManager] Full sync failed: $e');
    }
  }
}
