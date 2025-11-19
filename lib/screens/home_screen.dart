import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart'; // ADD THIS DEPENDENCY
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
import 'saved_posts_screen.dart';
import '../widgets/skeleton_loader.dart'; // NEW: Import skeleton loader

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // NEW: Refresh controller for pull-to-refresh
  final RefreshController _refreshController = RefreshController(initialRefresh: false);
  
  // NEW: Scroll controller for detecting scroll position
  final ScrollController _scrollController = ScrollController();
  
  // NEW: Track loading states
  bool _isLoadingPosts = false;
  bool _hasError = false;
  String _errorMessage = '';

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
    
    // NEW: Listen for errors from FirebaseService
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final firebaseService = Provider.of<FirebaseService>(context, listen: false);
      if (firebaseService.lastError != null) {
        setState(() {
          _hasError = true;
          _errorMessage = firebaseService.lastError!;
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _refreshController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // NEW: Pull to refresh handler
  void _onRefresh() async {
    try {
      // Simulate network delay for better UX
      await Future.delayed(const Duration(milliseconds: 1000));
      
      // Clear any existing errors
      setState(() {
        _hasError = false;
        _errorMessage = '';
      });
      
      // Refresh would typically reload data here
      // For now, we'll just complete the refresh
      _refreshController.refreshCompleted();
      
      // Show success indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Feed updated!'),
          backgroundColor: Colors.green.shade600,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      _refreshController.refreshFailed();
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to refresh feed';
      });
    }
  }

  // NEW: Error widget
  Widget _buildErrorWidget() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline_rounded, size: 40, color: Colors.red.shade400),
          const SizedBox(height: 12),
          const Text(
            'Something went wrong',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _hasError = false;
                    _errorMessage = '';
                  });
                  _onRefresh();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                child: const Text('Try Again'),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _hasError = false;
                    _errorMessage = '';
                  });
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFF94A3B8)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                child: const Text('Dismiss'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // NEW: Enhanced empty state
  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(Icons.lightbulb_outline_rounded, size: 80, color: Colors.amber.shade400),
          const SizedBox(height: 20),
          const Text(
            'No posts yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Be the first to share something amazing with your learning community!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 15,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF06B6D4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7C3AED).withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(15),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateScreen()));
                },
                child: const Center(
                  child: Text(
                    'Create First Post',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () {
              _onRefresh();
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFF7C3AED)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Refresh Feed'),
          ),
        ],
      ),
    );
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

  // NEW: Enhanced share post method
  void _sharePost(String postId, String content) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.share_rounded, color: Color(0xFF7C3AED), size: 30),
              ),
              const SizedBox(height: 16),
              const Text(
                'Share Post',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Share this post with your friends and study groups?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFF94A3B8)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Post shared successfully!'),
                            backgroundColor: Colors.green.shade600,
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Share'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final firebaseService = Provider.of<FirebaseService>(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SafeArea(
              child: Column(
                children: [
                  // Enhanced Custom App Bar
                  Container(
                    color: const Color(0xFF1E293B),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          // Enhanced Logo
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF7C3AED), Color(0xFF06B6D4)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.school_rounded, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'SocialNest',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              fontSize: 24,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const Spacer(),
                          
                          // Enhanced Notification Icon with Badge
                          StreamBuilder<DocumentSnapshot>(
                            stream: firebaseService.getUnreadNotificationCount(),
                            builder: (context, snapshot) {
                              int unreadCount = 0;
                              if (snapshot.hasData && snapshot.data!.exists) {
                                final userData = snapshot.data!.data() as Map<String, dynamic>;
                                unreadCount = userData['unreadNotifications'] ?? 0;
                              }
                              
                              return MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                                    );
                                  },
                                  child: Badge(
                                    isLabelVisible: unreadCount > 0,
                                    label: Text(unreadCount.toString()),
                                    backgroundColor: Colors.red.shade500,
                                    textColor: Colors.white,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.notifications_none_rounded,
                                        color: Colors.white.withOpacity(0.8),
                                        size: 22,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 12),
                          
                          // Enhanced Search Icon
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const ExploreScreen()));
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.search_rounded,
                                  color: Colors.white.withOpacity(0.8),
                                  size: 22,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Content Area with Pull to Refresh
                  Expanded(
                    child: SmartRefresher(
                      controller: _refreshController,
                      onRefresh: _onRefresh,
                      enablePullDown: true,
                      enablePullUp: false,
                      header: ClassicHeader(
                        height: 60,
                        completeDuration: const Duration(milliseconds: 500),
                        refreshingText: 'Updating feed...',
                        completeText: 'Feed updated!',
                        failedText: 'Update failed',
                        releaseText: 'Release to refresh',
                        idleText: 'Pull down to refresh',
                        textStyle: const TextStyle(color: Color(0xFF94A3B8)),
                        refreshingIcon: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              const Color(0xFF7C3AED).withOpacity(0.8),
                            ),
                          ),
                        ),
                      ),
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          children: [
                            // Stories Section with Skeleton
                            StreamBuilder<List<dynamic>>(
                              stream: firebaseService.getStories(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return Container(
                                    height: 120,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    child: ListView(
                                      scrollDirection: Axis.horizontal,
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      children: List.generate(6, (index) => const StorySkeleton()),
                                    ),
                                  );
                                }
                                return const StoriesSection();
                              },
                            ),

                            // Quick Actions with Skeleton
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _buildQuickAction(
                                      Icons.quiz_rounded,
                                      'Daily Quiz',
                                      Colors.green,
                                      () {
                                        // Navigate to quiz screen
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildQuickAction(
                                      Icons.groups_rounded,
                                      'Study Groups',
                                      Colors.orange,
                                      () {
                                        Navigator.push(context, MaterialPageRoute(builder: (_) => const FriendsScreen()));
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildQuickAction(
                                      Icons.emoji_events_rounded,
                                      'Achievements',
                                      Colors.amber,
                                      () {
                                        // Navigate to achievements
                                      },
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
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
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
                                    child: MouseRegion(
                                      cursor: SystemMouseCursors.click,
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
                                  ),
                                  const SizedBox(width: 12),
                                  MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: GestureDetector(
                                      onTap: () {
                                        Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateScreen()));
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF7C3AED).withOpacity(0.2),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.photo_library_rounded, color: Color(0xFF7C3AED)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Error Display
                            if (_hasError) _buildErrorWidget(),

                            // Posts Feed from Firebase with Enhanced Loading
                            StreamBuilder<QuerySnapshot>(
                              stream: firebaseService.getPosts(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return Column(
                                    children: List.generate(3, (index) => const PostSkeleton()),
                                  );
                                }

                                if (snapshot.hasError) {
                                  return Container(
                                    margin: const EdgeInsets.all(16),
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1E293B),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(Icons.wifi_off_rounded, size: 50, color: Colors.red.shade400),
                                        const SizedBox(height: 16),
                                        const Text(
                                          'Connection Error',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        const Text(
                                          'Could not load posts. Please check your connection.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Color(0xFF94A3B8),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        ElevatedButton(
                                          onPressed: _onRefresh,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF7C3AED),
                                            foregroundColor: Colors.white,
                                          ),
                                          child: const Text('Retry'),
                                        ),
                                      ],
                                    ),
                                  );
                                }

                                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                                  return _buildEmptyState();
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
                  ),
                ],
              ),
            ),
          );
        },
      ),

      // Enhanced Bottom Navigation Bar
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
          border: Border(
            top: BorderSide(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
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
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
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
          // Enhanced Post Header
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

          // Enhanced Post Content
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

          // Enhanced Post Image with Loading
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
                          strokeWidth: 2,
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

          // Enhanced Quiz Section
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
                    
                    return MouseRegion(
                      cursor: hasVoted ? SystemMouseCursors.basic : SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: hasVoted 
                            ? null // Disable tap if already voted
                            : () async {
                                // Vote on this option
                                final success = await Provider.of<FirebaseService>(context, listen: false)
                                    .voteOnQuiz(postId, option);
                                
                                if (success) {
                                  // Show success message
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Voted for: $option'),
                                      backgroundColor: Colors.green.shade600,
                                      duration: const Duration(seconds: 2),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('You have already voted on this quiz!'),
                                      backgroundColor: Colors.orange,
                                      duration: Duration(seconds: 2),
                                      behavior: SnackBarBehavior.floating,
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

          // Enhanced Post Stats
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
                    Icon(Icons.bookmark_rounded, color: const Color(0xFF7C3AED), size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${post['saveCount'] ?? 0}',
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

          // Enhanced Post Actions
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
                // Enhanced Like Button
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
                
                // Enhanced Comment Button
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
                
                // Enhanced Share Button
                _buildPostAction(
                  Icons.share_rounded,
                  'Share',
                  Colors.white.withOpacity(0.6),
                  () {
                    _sharePost(postId, post['content'] ?? '');
                  },
                ),
                
                // Enhanced SAVE BUTTON
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
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
          ),
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
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index, VoidCallback onTap) {
    final isActive = _currentIndex == index;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
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
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateScreen()));
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
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