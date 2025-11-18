import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase_service.dart';
import 'profile_screen.dart';
import 'create_screen.dart';
import 'friends_screen.dart';
import 'explore_screen.dart';
import 'comments_screen.dart';
import 'notifications_screen.dart';
import 'create_story_screen.dart';
import 'story_screen.dart';
import 'stories_section.dart';
import 'saved_posts_screen.dart'; // NEW
import '../models/story_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color _getPostColor(String type) {
    switch (type) {
      case 'educational':
        return Colors.blue;
      case 'quiz':
        return Colors.green;
      case 'studyGroup':
        return Colors.orange;
      case 'resource':
        return Colors.purple;
      case 'achievement':
        return Colors.amber;
      default:
        return const Color(0xFF7C3AED);
    }
  }

  IconData _getPostIcon(String type) {
    switch (type) {
      case 'educational':
        return Icons.school_rounded;
      case 'quiz':
        return Icons.quiz_rounded;
      case 'studyGroup':
        return Icons.groups_rounded;
      case 'resource':
        return Icons.library_books_rounded;
      case 'achievement':
        return Icons.emoji_events_rounded;
      default:
        return Icons.person_rounded;
    }
  }

  String _getPostTypeLabel(String type) {
    switch (type) {
      case 'educational':
        return 'Educational';
      case 'quiz':
        return 'Quiz';
      case 'studyGroup':
        return 'Study Group';
      case 'resource':
        return 'Resource';
      case 'achievement':
        return 'Achievement';
      default:
        return 'Social';
    }
  }

  String _getTimeAgo(Timestamp timestamp) {
    final now = DateTime.now();
    final postTime = timestamp.toDate();
    final difference = now.difference(postTime);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${(difference.inDays / 7).floor()}w ago';
  }

  // NEW: Share post method
  void _sharePost(String postId, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text(
          'Share Post',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Share this post with others?',
          style: TextStyle(color: Colors.white.withOpacity(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF94A3B8)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Post shared!'),
                  backgroundColor: Color(0xFF7C3AED),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
            ),
            child: const Text('Share'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final firebaseService = Provider.of<FirebaseService>(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  // Custom App Bar
                  Container(
                    color: const Color(0xFF1E293B),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          const Text(
                            'SocialNest',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              fontSize: 24,
                            ),
                          ),
                          const Spacer(),
                          // Updated Notification Icon with Badge
                          StreamBuilder<DocumentSnapshot>(
                            stream: Provider.of<FirebaseService>(context).getUnreadNotificationCount(),
                            builder: (context, snapshot) {
                              int unreadCount = 0;
                              if (snapshot.hasData && snapshot.data!.exists) {
                                final userData = snapshot.data!.data() as Map<String, dynamic>;
                                unreadCount = userData['unreadNotifications'] ?? 0;
                              }
                              
                              return Badge(
                                isLabelVisible: unreadCount > 0,
                                label: Text(unreadCount.toString()),
                                backgroundColor: const Color(0xFFEF4444),
                                textColor: Colors.white,
                                child: IconButton(
                                  icon: const Icon(Icons.notifications_none_rounded, color: Colors.white70),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.search_rounded, color: Colors.white70),
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const ExploreScreen()));
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Content Area
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // Stories Section
                          const StoriesSection(),

                          // Quick Actions
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _buildQuickAction(
                                    Icons.quiz_rounded,
                                    'Daily Quiz',
                                    Colors.green,
                                    () {},
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildQuickAction(
                                    Icons.groups_rounded,
                                    'Study Groups',
                                    Colors.orange,
                                    () {},
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildQuickAction(
                                    Icons.emoji_events_rounded,
                                    'Achievements',
                                    Colors.amber,
                                    () {},
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Create Post Card
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: const Color(0xFF7C3AED),
                                  child: Text(
                                    firebaseService.userAvatar ?? 'U',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateScreen()));
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.05),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        'Share something with your friends...',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.6),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                IconButton(
                                  icon: const Icon(Icons.photo_library_rounded, color: Color(0xFF7C3AED)),
                                  onPressed: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateScreen()));
                                  },
                                ),
                              ],
                            ),
                          ),

                          // Posts Feed from Firebase
                          StreamBuilder<QuerySnapshot>(
                            stream: firebaseService.getPosts(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Padding(
                                  padding: EdgeInsets.all(32),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation(Color(0xFF7C3AED)),
                                    ),
                                  ),
                                );
                              }

                              if (snapshot.hasError) {
                                return Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Center(
                                    child: Text(
                                      'Error loading posts: ${snapshot.error}',
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                );
                              }

                              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                                return Container(
                                  margin: const EdgeInsets.all(16),
                                  padding: const EdgeInsets.all(32),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E293B),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Column(
                                    children: [
                                      const Icon(Icons.lightbulb_outline_rounded, size: 64, color: Color(0xFF94A3B8)),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'No posts yet',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'Be the first to share something with the community!',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Color(0xFF94A3B8),
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      ElevatedButton(
                                        onPressed: () {
                                          Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateScreen()));
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF7C3AED),
                                          foregroundColor: Colors.white,
                                        ),
                                        child: const Text('Create First Post'),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              final posts = snapshot.data!.docs;

                              return ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: posts.length,
                                itemBuilder: (context, index) {
                                  final post = posts[index];
                                  final postData = post.data() as Map<String, dynamic>;
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    child: _buildPostCard(postData, post.id, firebaseService),
                                  );
                                },
                              );
                            },
                          ),

                          const SizedBox(height: 80), // Space for bottom navigation
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.home_rounded, 'Home', 0, () {
                  setState(() => _currentIndex = 0);
                }),
                _buildNavItem(Icons.explore_rounded, 'Explore', 1, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ExploreScreen()));
                }),
                _buildFloatingActionButton(),
                _buildNavItem(Icons.people_rounded, 'Friends', 2, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const FriendsScreen()));
                }),
                _buildNavItem(Icons.person_rounded, 'Profile', 3, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post, String postId, FirebaseService firebaseService) {
    final postColor = _getPostColor(post['type'] ?? 'social');
    final postIcon = _getPostIcon(post['type'] ?? 'social');
    final typeLabel = _getPostTypeLabel(post['type'] ?? 'social');
    final hasImage = post['imageUrl'] != null && post['imageUrl'].toString().isNotEmpty;
    final isQuiz = post['type'] == 'quiz';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Post Header
          ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF7C3AED),
              child: Text(
                post['userAvatar'] ?? 'U',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(
              post['userName'] ?? 'User',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              _getTimeAgo(post['timestamp']),
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
              ),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: postColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(postIcon, size: 12, color: postColor),
                  const SizedBox(width: 4),
                  Text(
                    typeLabel,
                    style: TextStyle(
                      color: postColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Post Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post['content'] ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                if (post['subject'] != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Subject: ${post['subject']}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Post Image
          if (hasImage) ...[
            const SizedBox(height: 16),
            Container(
              height: 200,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  post['imageUrl']!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: const Color(0xFF1E293B),
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                              : null,
                          color: const Color(0xFF7C3AED),
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: const Color(0xFF1E293B),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image_rounded, color: Color(0xFF94A3B8), size: 40),
                            SizedBox(height: 8),
                            Text(
                              'Failed to load image',
                              style: TextStyle(color: Color(0xFF94A3B8)),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],

          // Quiz Section
          if (isQuiz && post['quizOptions'] != null) ...[
            const SizedBox(height: 16),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🧠 Quiz Options:',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(post['quizOptions'].length, (index) {
                    final option = post['quizOptions'][index];
                    final votes = post['quizVotes']?[option] ?? 0;
                    final totalVotes = post['totalVotes'] ?? 0;
                    final percentage = totalVotes > 0 ? (votes / totalVotes) * 100 : 0;
                    final hasVoted = (post['votedUsers'] as List<dynamic>?)?.contains(firebaseService.currentUser?.uid) ?? false;
                    
                    return GestureDetector(
                      onTap: hasVoted 
                          ? null // Disable tap if already voted
                          : () async {
                              // Vote on this option
                              final success = await Provider.of<FirebaseService>(context, listen: false)
                                  .voteOnQuiz(postId, option);
                              
                              if (success) {
                                // Show success message or refresh
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Voted for: $option'),
                                    backgroundColor: Colors.green,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('You have already voted on this quiz!'),
                                    backgroundColor: Colors.red,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                      child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: hasVoted 
                              ? const Color(0xFF7C3AED).withOpacity(0.2)
                              : Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: hasVoted ? const Color(0xFF7C3AED) : Colors.transparent,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    option,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: hasVoted ? FontWeight.w600 : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                if (hasVoted) ...[
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.check_circle_rounded,
                                    size: 16,
                                    color: Colors.green.shade400,
                                  ),
                                ],
                              ],
                            ),
                            if (hasVoted || totalVotes > 0) ...[
                              const SizedBox(height: 6),
                              // Progress bar
                              Container(
                                height: 6,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Stack(
                                  children: [
                                    Container(
                                      height: 6,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 500),
                                      height: 6,
                                      width: (MediaQuery.of(context).size.width - 80) * (percentage / 100),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF7C3AED),
                                            Color(0xFF06B6D4),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '$votes votes',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    '${percentage.toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  Text(
                    '${post['totalVotes'] ?? 0} total votes • ${(post['votedUsers'] as List<dynamic>?)?.contains(firebaseService.currentUser?.uid) ?? false ? 'You voted!' : 'Tap to vote'}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                  
                  // Results summary if user has voted
                  if ((post['votedUsers'] as List<dynamic>?)?.contains(firebaseService.currentUser?.uid) ?? false) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.emoji_events_rounded, size: 16, color: Colors.green.shade400),
                          const SizedBox(width: 8),
                          Text(
                            'Thanks for voting!',
                            style: TextStyle(
                              color: Colors.green.shade400,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Post Stats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Row(
                  children: [
                    Icon(Icons.favorite_rounded, color: Colors.red.shade400, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${post['likes'] ?? 0}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Row(
                  children: [
                    Icon(Icons.chat_bubble_rounded, color: Colors.white.withOpacity(0.6), size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${post['comments'] ?? 0}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Row(
                  children: [
                    Icon(Icons.bookmark_rounded, color: const Color(0xFF7C3AED), size: 16), // NEW: Save count icon
                    const SizedBox(width: 4),
                    Text(
                      '${post['saveCount'] ?? 0}', // NEW: Save count
                      style: const TextStyle(
                        color: Color(0xFF7C3AED),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Row(
                  children: [
                    Icon(Icons.share_rounded, color: Colors.white.withOpacity(0.6), size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${post['shares'] ?? 0}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Post Actions
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            color: Colors.white.withOpacity(0.1),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Like Button
                StreamBuilder<bool>(
                  stream: Provider.of<FirebaseService>(context, listen: false).getPostLikeStatus(postId),
                  builder: (context, snapshot) {
                    final isLiked = snapshot.data ?? false;
                    
                    return _buildPostAction(
                      Icons.favorite_rounded,
                      'Like',
                      isLiked ? Colors.red : Colors.white.withOpacity(0.6),
                      () {
                        Provider.of<FirebaseService>(context, listen: false).likePost(postId);
                      },
                    );
                  },
                ),
                
                // Comment Button
                _buildPostAction(
                  Icons.chat_bubble_rounded,
                  'Comment',
                  Colors.white.withOpacity(0.6),
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CommentsScreen(
                          postId: postId,
                          postContent: post['content'] ?? '',
                        ),
                      ),
                    );
                  },
                ),
                
                // Share Button
                _buildPostAction(
                  Icons.share_rounded,
                  'Share',
                  Colors.white.withOpacity(0.6),
                  () {
                    _sharePost(postId, post['content'] ?? '');
                  },
                ),
                
                // SAVE BUTTON - NEW!
                StreamBuilder<bool>(
                  stream: Provider.of<FirebaseService>(context, listen: false).getPostSaveStatus(postId),
                  builder: (context, snapshot) {
                    final isSaved = snapshot.data ?? false;
                    
                    return _buildPostAction(
                      isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                      'Save',
                      isSaved ? const Color(0xFF7C3AED) : Colors.white.withOpacity(0.6),
                      () {
                        if (isSaved) {
                          Provider.of<FirebaseService>(context, listen: false).unsavePost(postId);
                        } else {
                          Provider.of<FirebaseService>(context, listen: false).savePost(postId);
                        }
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostAction(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index, VoidCallback onTap) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFF7C3AED).withOpacity(0.2) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isActive ? const Color(0xFF7C3AED) : Colors.white.withOpacity(0.5),
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isActive ? const Color(0xFF7C3AED) : Colors.white.withOpacity(0.5),
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateScreen()));
          },
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF7C3AED),
                  Color(0xFF06B6D4),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7C3AED).withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Create',
          style: TextStyle(
            fontSize: 10,
            color: Colors.white.withOpacity(0.5),
          ),
        ),
      ],
    );
  }
}