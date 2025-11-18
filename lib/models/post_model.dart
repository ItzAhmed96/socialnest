import 'package:cloud_firestore/cloud_firestore.dart';

class SocialPost {
  final String id;
  final String userId;
  final String userName;
  final String userAvatar;
  final String content;
  final String? imageUrl;
  final PostType type;
  final DateTime timestamp;
  int likes;
  int comments;
  int shares;
  int saveCount; // NEW: For tracking saves
  bool isLiked;
  bool isSaved; // NEW: To track if current user saved this
  List<String> tags;
  String? subject;
  String? quizQuestion;
  List<String>? quizOptions;
  Map<String, int>? quizVotes; // NEW: For quiz posts
  List<String>? votedUsers; // NEW: Track who voted
  int totalVotes; // NEW: For quiz posts

  SocialPost({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.content,
    this.imageUrl,
    required this.type,
    required this.timestamp,
    this.likes = 0,
    this.comments = 0,
    this.shares = 0,
    this.saveCount = 0, // NEW
    this.isLiked = false,
    this.isSaved = false, // NEW
    this.tags = const [],
    this.subject,
    this.quizQuestion,
    this.quizOptions,
    this.quizVotes,
    this.votedUsers,
    this.totalVotes = 0,
  });

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${difference.inDays ~/ 7}w ago';
  }

  // NEW: Calculate engagement score for trending
  double get engagementScore {
    return (likes * 1.0 + comments * 2.0 + shares * 3.0) / 
           (DateTime.now().difference(timestamp).inHours + 1);
  }
}

enum PostType {
  social,
  educational,
  quiz,
  achievement,
  studyGroup,
  resource,
}