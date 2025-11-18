import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase_service.dart';

class CommentsScreen extends StatefulWidget {
  final String postId;
  final String postContent;

  const CommentsScreen({
    super.key,
    required this.postId,
    required this.postContent,
  });

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final TextEditingController _commentController = TextEditingController();
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();

  void _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await Provider.of<FirebaseService>(context, listen: false)
          .addComment(widget.postId, _commentController.text.trim());

      if (success) {
        _commentController.clear();
        FocusScope.of(context).unfocus();
        
        // Scroll to bottom to show the new comment
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      } else {
        _showErrorDialog('Failed to add comment. Please try again.');
      }
    } catch (e) {
      _showErrorDialog('An error occurred: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text(
          'Error',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Color(0xFF7C3AED))),
          ),
        ],
      ),
    );
  }

  void _deleteComment(String commentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text(
          'Delete Comment',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to delete this comment?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Provider.of<FirebaseService>(context, listen: false)
                  .deleteComment(commentId, widget.postId);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
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
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firebaseService = Provider.of<FirebaseService>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text(
          'Comments',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Post Preview
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              border: Border(
                bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF7C3AED),
                  radius: 20,
                  child: Text(
                    firebaseService.userAvatar ?? 'U',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        firebaseService.userName ?? 'User',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.postContent.length > 100
                            ? '${widget.postContent.substring(0, 100)}...'
                            : widget.postContent,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Comments List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: Provider.of<FirebaseService>(context).getComments(widget.postId),
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
                    child: Text(
                      'Error loading comments: ${snapshot.error}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded,
                            size: 64, color: Color(0xFF94A3B8)),
                        SizedBox(height: 16),
                        Text(
                          'No comments yet',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Be the first to comment!',
                          style: TextStyle(color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                  );
                }

                final comments = snapshot.data!.docs;

                // Sort comments by timestamp
                comments.sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>;
                  final bData = b.data() as Map<String, dynamic>;
                  final aTime = (aData['timestamp'] as Timestamp).millisecondsSinceEpoch;
                  final bTime = (bData['timestamp'] as Timestamp).millisecondsSinceEpoch;
                  return aTime.compareTo(bTime);
                });

                // Auto-scroll to bottom when new comments are added
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients && comments.isNotEmpty) {
                    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    final commentData = comment.data() as Map<String, dynamic>;
                    final isCurrentUser = commentData['userId'] == firebaseService.currentUser?.uid;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            backgroundColor: const Color(0xFF7C3AED),
                            radius: 16,
                            child: Text(
                              commentData['userAvatar'] ?? 'U',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        commentData['userName'] ?? 'User',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        _getTimeAgo(commentData['timestamp']),
                                        style: const TextStyle(
                                          color: Color(0xFF94A3B8),
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    commentData['content'] ?? '',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      // Like Comment Section
                                      StreamBuilder<bool>(
                                        stream: Provider.of<FirebaseService>(context, listen: false)
                                            .getCommentLikeStatus(commentData['id']),
                                        builder: (context, likeSnapshot) {
                                          final isCommentLiked = likeSnapshot.data ?? false;
                                          
                                          return GestureDetector(
                                            onTap: () {
                                              Provider.of<FirebaseService>(context, listen: false)
                                                  .likeComment(commentData['id']);
                                            },
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.favorite_rounded,
                                                  size: 16,
                                                  color: isCommentLiked ? Colors.red : const Color(0xFF94A3B8),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${commentData['likes'] ?? 0}',
                                                  style: TextStyle(
                                                    color: isCommentLiked ? Colors.red : const Color(0xFF94A3B8),
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                      const Spacer(),
                                      if (isCurrentUser)
                                        GestureDetector(
                                          onTap: () => _deleteComment(commentData['id']),
                                          child: const Icon(
                                            Icons.delete_outline_rounded,
                                            size: 16,
                                            color: Color(0xFF94A3B8),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Add Comment Input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              border: Border(
                top: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: TextField(
                      controller: _commentController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Write a comment...',
                        hintStyle: TextStyle(color: Color(0xFF94A3B8)),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: (_) => _addComment(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _isLoading
                    ? const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(Color(0xFF7C3AED)),
                      )
                    : IconButton(
                        onPressed: _addComment,
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7C3AED),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}