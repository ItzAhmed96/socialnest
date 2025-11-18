import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isLoading = false;

  String _getTimeAgo(Timestamp timestamp) {
    final now = DateTime.now();
    final notificationTime = timestamp.toDate();
    final difference = now.difference(notificationTime);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    
    // Format without intl package
    final month = notificationTime.month;
    final day = notificationTime.day;
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[month - 1]} $day';
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'post_like':
        return Icons.favorite_rounded;
      case 'post_comment':
        return Icons.chat_bubble_rounded;
      case 'friend_request':
        return Icons.person_add_rounded;
      case 'friend_accepted':
        return Icons.people_rounded;
      case 'story_like':
        return Icons.favorite_rounded;
      case 'quiz_created':
        return Icons.quiz_rounded;
      case 'achievement_unlocked':
        return Icons.emoji_events_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'post_like':
        return Colors.red;
      case 'story_like':
        return Colors.red;
      case 'post_comment':
        return Colors.blue;
      case 'friend_request':
        return Colors.green;
      case 'friend_accepted':
        return Colors.green;
      case 'quiz_created':
        return Colors.orange;
      case 'achievement_unlocked':
        return Colors.amber;
      default:
        return const Color(0xFF7C3AED);
    }
  }

  String _getNotificationTitle(String type, String title) {
    return title;
  }

  String _getNotificationMessage(String type, String message) {
    return message;
  }

  Future<void> _markAllAsRead() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Provider.of<FirebaseService>(context, listen: false)
          .markAllNotificationsAsRead();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All notifications marked as read'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const Icon(Icons.arrow_back_rounded),
          ),
        ),
        actions: [
          StreamBuilder<QuerySnapshot>(
            stream: Provider.of<FirebaseService>(context).getUserNotifications(),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                final hasUnread = snapshot.data!.docs.any((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['isRead'] == false;
                });
                
                if (hasUnread) {
                  return MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: _isLoading ? null : _markAllAsRead,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : const Icon(Icons.mark_email_read_rounded),
                    ),
                  );
                }
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: Provider.of<FirebaseService>(context).getUserNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Color(0xFF7C3AED)),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 64,
                    color: Color(0xFF94A3B8),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Error loading notifications',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.notifications_off_rounded,
                    size: 80,
                    color: Color(0xFF94A3B8),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'No notifications yet',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'When you get notifications, they\'ll appear here. Stay active to see more!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: const Text('Go Back Home'),
                    ),
                  ),
                ],
              ),
            );
          }

          final notifications = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              final data = notification.data() as Map<String, dynamic>;
              final isRead = data['isRead'] ?? false;
              final type = data['type'] ?? 'general';
              final title = data['title'] ?? 'Notification';
              final message = data['message'] ?? '';
              final senderName = data['senderName'] ?? 'User';
              final senderAvatar = data['senderAvatar'] ?? 'U';
              final timestamp = data['timestamp'] as Timestamp;

              return Dismissible(
                key: Key(notification.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  decoration: BoxDecoration(
                    color: Colors.red.shade400,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(
                    Icons.delete_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                confirmDismiss: (direction) async {
                  // Show confirmation dialog
                  return await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: const Color(0xFF1E293B),
                      title: const Text(
                        'Delete Notification',
                        style: TextStyle(color: Colors.white),
                      ),
                      content: const Text(
                        'Are you sure you want to delete this notification?',
                        style: TextStyle(color: Colors.white70),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text(
                            'Delete',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                onDismissed: (direction) {
                  // Delete notification from Firebase
                  Provider.of<FirebaseService>(context, listen: false)
                      .markNotificationAsRead(notification.id);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isRead
                        ? const Color(0xFF1E293B)
                        : const Color(0xFF7C3AED).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: isRead
                        ? null
                        : Border.all(
                            color: const Color(0xFF7C3AED).withOpacity(0.3),
                            width: 1,
                          ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          if (!isRead) {
                            Provider.of<FirebaseService>(context, listen: false)
                                .markNotificationAsRead(notification.id);
                          }

                          // Handle notification tap based on type
                          switch (type) {
                            case 'post_like':
                            case 'post_comment':
                              // Navigate to post
                              // Navigator.push(...);
                              break;
                            case 'friend_request':
                              // Navigate to friends screen
                              // Navigator.push(...);
                              break;
                            case 'story_like':
                              // Navigate to story
                              // Navigator.push(...);
                              break;
                            default:
                              break;
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Notification Icon
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: _getNotificationColor(type)
                                      .withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _getNotificationIcon(type),
                                  color: _getNotificationColor(type),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Notification Content
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Sender Avatar and Name
                                    Row(
                                      children: [
                                        Container(
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF7C3AED),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              senderAvatar,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          senderName,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),

                                    // Notification Title
                                    Text(
                                      _getNotificationTitle(type, title),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 2),

                                    // Notification Message
                                    Text(
                                      _getNotificationMessage(type, message),
                                      style: const TextStyle(
                                        color: Color(0xFF94A3B8),
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 8),

                                    // Timestamp
                                    Text(
                                      _getTimeAgo(timestamp),
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.5),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Unread Indicator
                              if (!isRead)
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF7C3AED),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),

      // Clear All Button (only show if there are notifications)
      floatingActionButton: StreamBuilder<QuerySnapshot>(
        stream: Provider.of<FirebaseService>(context).getUserNotifications(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
            return MouseRegion(
              cursor: SystemMouseCursors.click,
              child: FloatingActionButton.extended(
                onPressed: _markAllAsRead,
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Icon(Icons.mark_email_read_rounded),
                label: _isLoading
                    ? const Text('Processing...')
                    : const Text('Mark All Read'),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}