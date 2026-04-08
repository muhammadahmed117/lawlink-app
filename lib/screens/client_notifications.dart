import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/notification_service.dart';

const _headerColor = Color(0xFF0D1B2A);
const _pageColor = Color(0xFFF4F5F7);
const _cardColor = Colors.white;
const _accentColor = Color(0xFFFF6B35);
const _shadowColor = Color(0x1A000000);
const _titleColor = Color(0xFF111827);
const _bodyColor = Color(0xFF4B5563);
const _timeColor = Color(0xFF9CA3AF);

class ClientNotificationsScreen extends StatelessWidget {
  const ClientNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const _NotificationsScaffold(
        child: _CenteredMessage(
          icon: Icons.lock_outline_rounded,
          title: 'Sign In Required',
          subtitle: 'Please sign in to view your notifications.',
        ),
      );
    }

    return FutureBuilder<bool>(
      future: NotificationService.hasProfile(
        uid: currentUser.uid,
        role: AppNotificationRole.client,
      ),
      builder: (context, clientSnapshot) {
        if (clientSnapshot.connectionState == ConnectionState.waiting) {
          return const _NotificationsScaffold(
            child: Center(
              child: CircularProgressIndicator(color: _accentColor),
            ),
          );
        }

        if (clientSnapshot.data != true) {
          return const _NotificationsScaffold(
            child: _CenteredMessage(
              icon: Icons.person_outline_rounded,
              title: 'Client Profile Not Found',
              subtitle: 'This screen is only available for client accounts.',
            ),
          );
        }

        final stream = FirebaseFirestore.instance
            .collection('notifications')
          .where('receiverId', isEqualTo: currentUser.uid)
            .snapshots();

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: stream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const _NotificationsScaffold(
                child: _CenteredMessage(
                  icon: Icons.error_outline_rounded,
                  title: 'Unable to load notifications',
                  subtitle: 'Please try again in a moment.',
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _NotificationsScaffold(
                child: Center(
                  child: CircularProgressIndicator(color: _accentColor),
                ),
              );
            }

            final docs = snapshot.data?.docs ?? const [];
            final notifications = NotificationService.forRole(
              docs: docs,
              uid: currentUser.uid,
              role: AppNotificationRole.client,
            );

            return _NotificationsScaffold(
              onMarkAllAsRead: notifications.any((item) => !item.isRead)
                  ? () => _markAllAsRead(notifications)
                  : null,
              child: notifications.isEmpty
                  ? const _CenteredMessage(
                      icon: Icons.notifications_none_rounded,
                      title: 'No notifications yet',
                      subtitle: 'You will see your updates here in real-time.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                      itemCount: notifications.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = notifications[index];
                        return _NotificationCard(
                          notification: item,
                          onTap: () => _markSingleAsRead(item),
                        );
                      },
                    ),
            );
          },
        );
      },
    );
  }

  Future<void> _markSingleAsRead(AppNotificationData item) async {
    if (item.isRead) {
      return;
    }

    await NotificationService.markAsRead(item.id);
  }

  Future<void> _markAllAsRead(List<AppNotificationData> notifications) async {
    await NotificationService.markAllAsRead(notifications);
  }
}

class _NotificationsScaffold extends StatelessWidget {
  const _NotificationsScaffold({
    required this.child,
    this.onMarkAllAsRead,
  });

  final Widget child;
  final VoidCallback? onMarkAllAsRead;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageColor,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(10, 14, 14, 16),
              decoration: const BoxDecoration(
                color: _headerColor,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Expanded(
                    child: Text(
                      'Notifications',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: onMarkAllAsRead,
                    child: Text(
                      'Mark all as read',
                      style: TextStyle(
                        color: onMarkAllAsRead == null
                            ? const Color(0x80FF6B35)
                            : _accentColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: const Color(0xFF94A3B8)),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: _titleColor,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(
                color: _bodyColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.onTap,
  });

  final AppNotificationData notification;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    final iconData = _iconForType(notification.type);
    final iconColor = _iconColorForType(notification.type);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: _shadowColor,
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: notification.isRead ? Colors.transparent : _accentColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: iconColor.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(iconData, color: iconColor, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                notification.title,
                                style: const TextStyle(
                                  color: _titleColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                notification.body,
                                style: const TextStyle(
                                  color: _bodyColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                NotificationService.timeAgo(notification.timestamp),
                                style: const TextStyle(
                                  color: _timeColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (!notification.isRead)
            const Positioned(
              top: 10,
              right: 10,
              child: _UnreadDot(),
            ),
        ],
      ),
    );
  }

  static IconData _iconForType(String type) {
    switch (type.toLowerCase()) {
      case 'appointment':
      case 'appointments':
        return Icons.calendar_month_rounded;
      case 'message':
      case 'messages':
        return Icons.chat_bubble_rounded;
      case 'verification':
      case 'verified':
        return Icons.verified_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  static Color _iconColorForType(String type) {
    switch (type.toLowerCase()) {
      case 'appointment':
      case 'appointments':
        return const Color(0xFF2563EB);
      case 'message':
      case 'messages':
        return const Color(0xFF16A34A);
      case 'verification':
      case 'verified':
        return const Color(0xFF16A34A);
      default:
        return const Color(0xFF64748B);
    }
  }
}

class _UnreadDot extends StatelessWidget {
  const _UnreadDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: const BoxDecoration(
        color: _accentColor,
        shape: BoxShape.circle,
      ),
    );
  }
}

