import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../shared/providers/notifications_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pagePadding, 16, AppSpacing.pagePadding, 8),
              child: Row(
                children: [
                  Text('Notifications',
                      style: GoogleFonts.syne(
                          fontSize: 22, fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary)),
                  const Spacer(),
                  if (state.unreadCount > 0)
                    TextButton(
                      onPressed: () => ref
                          .read(notificationsProvider.notifier)
                          .markAllRead(),
                      child: Text('Mark all read',
                          style: GoogleFonts.inter(
                              fontSize: 12, color: AppColors.brand)),
                    ),
                ],
              ),
            ),

            Expanded(
              child: state.notifications.isEmpty
                  ? _EmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: state.notifications.length,
                      itemBuilder: (_, i) => _NotifCard(
                        notif: state.notifications[i],
                        index: i,
                        onTap: () => ref
                            .read(notificationsProvider.notifier)
                            .markRead(state.notifications[i].id),
                        onDismiss: () => ref
                            .read(notificationsProvider.notifier)
                            .dismiss(state.notifications[i].id),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty state ───────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96, height: 96,
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(Icons.notifications_none_rounded,
                color: AppColors.textMuted, size: 44),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .moveY(begin: 0, end: -8, duration: 2000.ms,
                  curve: Curves.easeInOut),
          const SizedBox(height: 20),
          Text('No notifications yet',
              style: GoogleFonts.syne(
                  fontSize: 18, fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Text(
            'Complete levels to earn achievements\nand get notified.',
            style: GoogleFonts.inter(
                fontSize: 13, color: AppColors.textSecondary, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Notification Card ─────────────────────────────────────────
class _NotifCard extends StatelessWidget {
  final AppNotification notif;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotifCard({
    required this.notif,
    required this.index,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notif.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline,
            color: AppColors.error, size: 24),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: notif.isRead
                ? AppColors.bgCard
                : AppColors.brand.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: notif.isRead
                  ? AppColors.border
                  : AppColors.brand.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon bubble
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: notif.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(notif.icon, size: 20, color: notif.color),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(notif.title,
                        style: GoogleFonts.syne(
                            fontSize: 13, fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(notif.body,
                        style: GoogleFonts.inter(
                            fontSize: 12, color: AppColors.textSecondary,
                            height: 1.4),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(notif.timeAgo,
                        style: GoogleFonts.inter(
                            fontSize: 10, color: AppColors.textMuted)),
                  ],
                ),
              ),
              if (!notif.isRead)
                Container(
                  width: 8, height: 8,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: const BoxDecoration(
                    color: AppColors.brand, shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(
        delay: Duration(milliseconds: index * 60),
        duration: 300.ms);
  }
}
