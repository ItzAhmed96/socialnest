import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase_service.dart';
import 'comments_screen.dart';

class SavedPostsScreen extends StatefulWidget {
  const SavedPostsScreen({super.key});

  @override
  State<SavedPostsScreen> createState() => _SavedPostsScreenState();
}

class _SavedPostsScreenState extends State<SavedPostsScreen> with SingleTickerProviderStateMixin {
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

  String _getTimeAgo(Timestamp timestamp) {
    final now = DateTime.now();
    final time = timestamp.toDate();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${(difference.inDays / 7).floor()}w ago';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text(
          'Saved Posts',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: StreamBuilder<QuerySnapshot>(
              stream: Provider.of<FirebaseService>(context).getSavedPosts(),
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
                        const Icon(Icons.error_outline_rounded, size: 64, color: Color(0xFF94A3B8)),
                        const SizedBox(height: 16),
                        const Text(
                          'Error loading saved posts',
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
                        const Icon(Icons.bookmark_border_rounded, size: 80, color: Color(0xFF94A3B8)),
                        const SizedBox(height: 20),
                        const Text(
                          'No saved posts yet',
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
                            'Save interesting posts, study tips, and resources to find them later!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7C3AED),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          child: const Text('Explore Posts'),
                        ),
                      ],
                    ),
                  );
                }

                final savedPosts = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: savedPosts.length,
                  itemBuilder: (context, index) {
                    final savedPost = savedPosts[index];
                    final savedData = savedPost.data() as Map<String, dynamic>;
                    
                    return _buildSavedPostItem(savedData, context);
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildSavedPostItem(Map<String, dynamic> savedData, BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with user info and unsave button
          ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF7C3AED),
              child: Text(
                savedData['userAvatar'] ?? 'U',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(
              savedData['userName'] ?? 'User',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              _getTimeAgo(savedData['savedAt']),
              style: const TextStyle(
                color: Color(0xFF94A3B8),
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.bookmark_rounded, color: Color(0xFF7C3AED)),
              onPressed: () {
                _unsavePost(savedData['postId'], context);
              },
            ),
          ),

          // Post content preview
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (savedData['postPreview'] != null)
                  Text(
                    savedData['postPreview']!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                
                if (savedData['imageUrl'] != null && savedData['imageUrl'].toString().isNotEmpty)
                  const SizedBox(height: 12),
                
                if (savedData['imageUrl'] != null && savedData['imageUrl'].toString().isNotEmpty)
                  Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: NetworkImage(savedData['imageUrl']!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Action buttons
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
                _buildSavedPostAction(
                  Icons.visibility_rounded,
                  'View Post',
                  () {
                    _viewOriginalPost(savedData['postId'], context);
                  },
                ),
                _buildSavedPostAction(
                  Icons.share_rounded,
                  'Share',
                  () {
                    _shareSavedPost(savedData, context);
                  },
                ),
                _buildSavedPostAction(
                  Icons.delete_rounded,
                  'Remove',
                  () {
                    _unsavePost(savedData['postId'], context);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedPostAction(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.white.withOpacity(0.7)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _unsavePost(String postId, BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text(
          'Remove Saved Post',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to remove this post from your saved items?',
          style: TextStyle(color: Color(0xFF94A3B8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF94A3B8)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Provider.of<FirebaseService>(context, listen: false)
                  .unsavePost(postId);
            },
            child: const Text(
              'Remove',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _viewOriginalPost(String postId, BuildContext context) {
    // Navigate to post details or comments screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CommentsScreen(
          postId: postId,
          postContent: 'Viewing saved post',
        ),
      ),
    );
  }

  void _shareSavedPost(Map<String, dynamic> savedData, BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text(
          'Share Saved Post',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Share "${savedData['postPreview'] ?? 'this post'}" with others?',
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
}