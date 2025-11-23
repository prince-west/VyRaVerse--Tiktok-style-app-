import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/vyra_theme.dart';
import '../services/api_service.dart';
import 'profile_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final List<NotificationItem> _notifications = [];
  bool _isLoading = true;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadNotifications();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final notifications = await _apiService.getNotifications();
      setState(() {
        _notifications.clear();
        _notifications.addAll(notifications.map((n) {
          final type = _parseNotificationType(n['type'] as String? ?? '');
          return NotificationItem(
            id: n['id']?.toString() ?? '',
            type: type,
            userId: n['user_id']?.toString() ?? '',
            username: n['username']?.toString() ?? 'Unknown',
            message: n['message']?.toString() ?? '',
            timestamp: n['created_at'] != null 
                ? DateTime.parse(n['created_at'] as String)
                : DateTime.now(),
            isRead: n['is_read'] as bool? ?? false,
          );
        }));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _notifications.clear();
        _isLoading = false;
      });
    }
  }

  NotificationType _parseNotificationType(String type) {
    switch (type.toLowerCase()) {
      case 'like':
        return NotificationType.like;
      case 'comment':
        return NotificationType.comment;
      case 'follow':
        return NotificationType.follow;
      case 'buzz':
        return NotificationType.buzz;
      default:
        return NotificationType.like;
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      for (var notification in _notifications) {
        if (!notification.isRead) {
          await _apiService.markNotificationRead(notification.id);
        }
      }
      setState(() {
        final updatedNotifications = _notifications.map((n) => NotificationItem(
          id: n.id,
          type: n.type,
          userId: n.userId,
          username: n.username,
          message: n.message,
          timestamp: n.timestamp,
          isRead: true,
        )).toList();
        _notifications.clear();
        _notifications.addAll(updatedNotifications);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                const Text(
                  'All notifications marked as read',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.error, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text('Error: $e', style: const TextStyle(fontWeight: FontWeight.w600))),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n.isRead).length;
    
    return Scaffold(
      backgroundColor: VyRaTheme.primaryBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                VyRaTheme.primaryBlack,
                VyRaTheme.darkGrey,
                VyRaTheme.primaryBlack,
              ],
            ),
          ),
        ),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                VyRaTheme.primaryCyan.withOpacity(0.2),
                VyRaTheme.primaryCyan.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: VyRaTheme.primaryCyan.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  Icon(
                    Icons.notifications_rounded,
                    color: VyRaTheme.primaryCyan,
                    size: 20,
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: VyRaTheme.primaryBlack, width: 2),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Center(
                          child: Text(
                            unreadCount > 99 ? '99+' : '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ).animate(onPlay: (controller) => controller.repeat())
                          .shake(duration: 500.ms, hz: 2)
                          .then(delay: 2000.ms),
                    ),
                ],
              ),
              const SizedBox(width: 8),
              const Text(
                'Notifications',
                style: TextStyle(
                  color: VyRaTheme.textWhite,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.2, end: 0),
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: VyRaTheme.darkGrey,
              shape: BoxShape.circle,
              border: Border.all(
                color: VyRaTheme.primaryCyan.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: const Icon(Icons.arrow_back, color: VyRaTheme.textWhite, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (unreadCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      VyRaTheme.primaryCyan.withOpacity(0.2),
                      VyRaTheme.primaryCyan.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: VyRaTheme.primaryCyan.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: TextButton.icon(
                  onPressed: _markAllAsRead,
                  icon: const Icon(
                    Icons.done_all_rounded,
                    color: VyRaTheme.primaryCyan,
                    size: 18,
                  ),
                  label: const Text(
                    'Mark all read',
                    style: TextStyle(
                      color: VyRaTheme.primaryCyan,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.2, end: 0),
            ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: VyRaTheme.primaryCyan.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const CircularProgressIndicator(
                      color: VyRaTheme.primaryCyan,
                      strokeWidth: 3,
                    ),
                  ).animate(onPlay: (controller) => controller.repeat())
                      .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1)),
                  const SizedBox(height: 20),
                  Text(
                    'Loading notifications...',
                    style: const TextStyle(
                      color: VyRaTheme.textGrey,
                      fontSize: 14,
                    ),
                  ).animate().fadeIn(delay: 200.ms),
                ],
              ),
            )
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              VyRaTheme.primaryCyan.withOpacity(0.1),
                              VyRaTheme.primaryCyan.withOpacity(0.05),
                            ],
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: VyRaTheme.primaryCyan.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          Icons.notifications_none_rounded,
                          size: 80,
                          color: VyRaTheme.primaryCyan,
                        ),
                      ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
                      const SizedBox(height: 24),
                      const Text(
                        'No notifications',
                        style: TextStyle(
                          color: VyRaTheme.textWhite,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ).animate(delay: 200.ms).fadeIn(),
                      const SizedBox(height: 8),
                      const Text(
                        'You\'re all caught up!',
                        style: TextStyle(
                          color: VyRaTheme.textGrey,
                          fontSize: 14,
                        ),
                      ).animate(delay: 300.ms).fadeIn(),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  color: VyRaTheme.primaryCyan,
                  backgroundColor: VyRaTheme.darkGrey,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      return _buildNotificationItem(notification, index);
                    },
                  ),
                ),
    );
  }

  Widget _buildNotificationItem(NotificationItem notification, int index) {
    final notificationColor = _getNotificationColor(notification.type);
    
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/profile',
          arguments: {
            'username': notification.username,
            'isViewingOther': true,
          },
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: notification.isRead
              ? null
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    VyRaTheme.darkGrey,
                    notificationColor.withOpacity(0.05),
                  ],
                ),
          color: notification.isRead ? VyRaTheme.darkGrey : null,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: notification.isRead
                ? VyRaTheme.lightGrey.withOpacity(0.2)
                : notificationColor.withOpacity(0.5),
            width: notification.isRead ? 1 : 2,
          ),
          boxShadow: notification.isRead
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : [
                  BoxShadow(
                    color: notificationColor.withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 1,
                  ),
                ],
        ),
        child: Row(
          children: [
            // Enhanced icon container
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    notificationColor.withOpacity(0.3),
                    notificationColor.withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: notificationColor.withOpacity(0.5),
                  width: 2,
                ),
                boxShadow: notification.isRead
                    ? null
                    : [
                        BoxShadow(
                          color: notificationColor.withOpacity(0.4),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
              ),
              child: _getNotificationIcon(notification.type),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: RichText(
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          text: TextSpan(
                            style: TextStyle(
                              color: VyRaTheme.textWhite,
                              fontSize: 14,
                              fontWeight: notification.isRead ? FontWeight.w400 : FontWeight.w500,
                              height: 1.4,
                            ),
                            children: [
                              TextSpan(
                                text: '@${notification.username}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: notificationColor,
                                  fontSize: 15,
                                ),
                              ),
                              TextSpan(
                                text: ' ${notification.message}',
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (!notification.isRead) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: notificationColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: notificationColor,
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                            .fadeIn(duration: 800.ms),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: notification.isRead
                              ? VyRaTheme.mediumGrey.withOpacity(0.5)
                              : notificationColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: notification.isRead
                                ? VyRaTheme.mediumGrey
                                : notificationColor.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              color: notification.isRead ? VyRaTheme.textGrey : notificationColor,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatTime(notification.timestamp),
                              style: TextStyle(
                                color: notification.isRead ? VyRaTheme.textGrey : notificationColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ).animate(delay: (index * 50).ms)
          .fadeIn(duration: 400.ms)
          .slideX(begin: 0.1, end: 0, duration: 400.ms),
    );
  }

  Widget _getNotificationIcon(NotificationType type) {
    IconData icon;
    Color color;

    switch (type) {
      case NotificationType.like:
        icon = Icons.favorite_rounded;
        color = Colors.red;
        break;
      case NotificationType.comment:
        icon = Icons.chat_bubble_rounded;
        color = VyRaTheme.primaryCyan;
        break;
      case NotificationType.follow:
        icon = Icons.person_add_rounded;
        color = VyRaTheme.primaryCyan;
        break;
      case NotificationType.buzz:
        icon = Icons.local_fire_department_rounded;
        color = Colors.orange;
        break;
      default:
        icon = Icons.notifications_rounded;
        color = VyRaTheme.textGrey;
    }

    return Icon(icon, color: color, size: 20);
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.like:
        return Colors.red;
      case NotificationType.comment:
        return VyRaTheme.primaryCyan;
      case NotificationType.follow:
        return Colors.green;
      case NotificationType.buzz:
        return Colors.orange;
      default:
        return VyRaTheme.textGrey;
    }
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 7) {
      return '${difference.inDays ~/ 7}w ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

class NotificationItem {
  final String id;
  final NotificationType type;
  final String userId;
  final String username;
  final String message;
  final DateTime timestamp;
  final bool isRead;

  NotificationItem({
    required this.id,
    required this.type,
    required this.userId,
    required this.username,
    required this.message,
    required this.timestamp,
    this.isRead = false,
  });
}

enum NotificationType {
  like,
  comment,
  follow,
  buzz,
}