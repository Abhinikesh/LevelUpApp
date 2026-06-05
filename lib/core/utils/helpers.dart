import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppHelpers {
  AppHelpers._();

  // ── Date & Time ───────────────────────────────────────────────

  static String formatDate(DateTime date) =>
      DateFormat('MMM dd, yyyy').format(date);

  static String formatDateShort(DateTime date) =>
      DateFormat('MMM dd').format(date);

  static String formatTime(DateTime date) =>
      DateFormat('hh:mm a').format(date);

  static String formatDateTime(DateTime date) =>
      DateFormat('MMM dd, yyyy • hh:mm a').format(date);

  static String timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';
    return '${(diff.inDays / 365).floor()}y ago';
  }

  static String daysUntil(DateTime date) {
    final diff = date.difference(DateTime.now()).inDays;
    if (diff < 0) return 'Overdue by ${diff.abs()} days';
    if (diff == 0) return 'Due today';
    if (diff == 1) return 'Due tomorrow';
    return 'Due in $diff days';
  }

  // ── Numbers ───────────────────────────────────────────────────

  static String formatXP(int xp) {
    if (xp >= 1000000) return '${(xp / 1000000).toStringAsFixed(1)}M';
    if (xp >= 1000) return '${(xp / 1000).toStringAsFixed(1)}K';
    return xp.toString();
  }

  static String formatNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }

  static String formatPercent(double value) =>
      '${(value * 100).toStringAsFixed(0)}%';

  // ── String utils ──────────────────────────────────────────────

  static String capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }

  static String titleCase(String s) =>
      s.split(' ').map(capitalize).join(' ');

  static String truncate(String s, int maxLength, {String ellipsis = '…'}) {
    if (s.length <= maxLength) return s;
    return '${s.substring(0, maxLength)}$ellipsis';
  }

  static String initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  // ── Color utils ───────────────────────────────────────────────

  static Color hexToColor(String hex) {
    final cleaned = hex.replaceAll('#', '');
    final value = int.tryParse(
      cleaned.length == 6 ? 'FF$cleaned' : cleaned,
      radix: 16,
    );
    return Color(value ?? 0xFF6C63FF);
  }

  static String colorToHex(Color color) =>
      '#${color.value.toRadixString(16).substring(2).toUpperCase()}';

  // ── Snackbar ──────────────────────────────────────────────────

  static void showSnack(
    BuildContext context,
    String message, {
    bool isError = false,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        backgroundColor:
            isError ? const Color(0xFFEF4444) : const Color(0xFF12121A),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // ── Roadmap / Level helpers ───────────────────────────────────

  static String roadmapTypeLabel(String type) {
    switch (type) {
      case 'gym':
        return 'Fitness';
      case 'study':
        return 'Study';
      case 'work':
        return 'Work';
      case 'custom':
        return 'Custom';
      default:
        return titleCase(type);
    }
  }

  static String levelStateLabel(String state) {
    switch (state) {
      case 'completed':
        return 'Completed';
      case 'active':
        return 'In Progress';
      case 'locked':
        return 'Locked';
      default:
        return titleCase(state);
    }
  }

  // ── Avatar fallback ───────────────────────────────────────────

  static String avatarFallbackUrl(String name) {
    final encoded = Uri.encodeComponent(name.trim());
    return 'https://ui-avatars.com/api/?name=$encoded'
        '&background=6C63FF&color=ffffff&bold=true&format=svg';
  }
}
