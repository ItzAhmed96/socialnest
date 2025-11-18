import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String type;
  final String title;
  final String message;
  final String senderId;
  final String senderName;
  final String senderAvatar;
  final String? targetId; // postId, commentId, etc.
  final Map<String, dynamic>? data;
  final bool isRead;
  final Timestamp timestamp;

  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.senderId,
    required this.senderName,
    required this.senderAvatar,
    this.targetId,
    this.data,
    this.isRead = false,
    required this.timestamp,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'] ?? '',
      type: map['type'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      senderAvatar: map['senderAvatar'] ?? '',
      targetId: map['targetId'],
      data: map['data'],
      isRead: map['isRead'] ?? false,
      timestamp: map['timestamp'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'message': message,
      'senderId': senderId,
      'senderName': senderName,
      'senderAvatar': senderAvatar,
      'targetId': targetId,
      'data': data,
      'isRead': isRead,
      'timestamp': timestamp,
    };
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp.toDate());
    
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${(difference.inDays / 7).floor()}w ago';
  }
}