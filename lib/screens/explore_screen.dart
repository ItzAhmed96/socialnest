import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase_service.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  int _selectedCategory = 0;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  
  final List<String> _categories = ['All', 'Study', 'Social', 'Quizzes', 'Groups', 'Resources'];
  
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
    _searchController.dispose();
    super.dispose();
  }

  // NEW: Join study group functionality
  Future<void> _joinStudyGroup(String groupId, String groupName) async {
    try {
      final success = await Provider.of<FirebaseService>(context, listen: false)
          .joinStudyGroup(groupId);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Joined $groupName! 🎉'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to join group'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // NEW: Get popular posts for explore
  Stream<QuerySnapshot> _getPopularPosts() {
    return FirebaseFirestore.instance
        .collection('posts')
        .orderBy('likes', descending: true)
        .limit(10)
        .snapshots();
  }

  // NEW: Get trending posts (based on engagement)
  Stream<QuerySnapshot> _getTrendingPosts() {
    return FirebaseFirestore.instance
        .collection('posts')
        .orderBy('timestamp', descending: true)
        .limit(20)
        .snapshots();
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
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  backgroundColor: const Color(0xFF1E293B),
                  elevation: 0,
                  pinned: true,
                  expandedHeight: 180,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF7C3AED),
                            Color(0xFF06B6D4),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Align(
                        alignment: Alignment.bottomLeft,
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'Explore',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.search_rounded, color: Colors.white),
                      onPressed: () {},
                    ),
                  ],
                ),

                // Search Bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Search communities, topics, users...',
                          hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8)),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, color: Color(0xFF94A3B8)),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchQuery = '';
                                    });
                                  },
                                )
                              : null,
                        ),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),

                // Categories
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final isSelected = _selectedCategory == index;
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: FilterChip(
                            label: Text(
                              _categories[index],
                              style: TextStyle(
                                color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() => _selectedCategory = selected ? index : 0);
                            },
                            backgroundColor: const Color(0xFF1E293B),
                            selectedColor: const Color(0xFF7C3AED),
                            checkmarkColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                // Show content based on search
                if (_searchQuery.isNotEmpty) ...[
                  _buildSearchResults(),
                ] else ...[
                  // Regular explore content when no search
                  _buildFeaturedSection(),
                  _buildPopularGroupsSection(),
                  _buildTrendingPostsSection(),
                ],

                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          );
        },
      ),
    );
  }

  // NEW: Search results
  Widget _buildSearchResults() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Search results for "$_searchQuery"',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            // Search users
            FutureBuilder<List<Map<String, dynamic>>>(
              future: Provider.of<FirebaseService>(context).searchUsers(_searchQuery),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(Color(0xFF7C3AED)),
                    ),
                  );
                }

                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Users',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...snapshot.data!.map((user) => _buildUserSearchResult(user)),
                    ],
                  );
                }

                return const SizedBox();
              },
            ),

            const SizedBox(height: 24),

            // Search groups
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('study_groups')
                  .where('name', isGreaterThanOrEqualTo: _searchQuery)
                  .where('name', isLessThan: _searchQuery + 'z')
                  .limit(5)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Study Groups',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...snapshot.data!.docs.map((group) => _buildGroupSearchResult(group)),
                    ],
                  );
                }

                return const SizedBox();
              },
            ),

            const SizedBox(height: 24),

            // Search posts
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .where('content', isGreaterThanOrEqualTo: _searchQuery)
                  .where('content', isLessThan: _searchQuery + 'z')
                  .limit(5)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Posts',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...snapshot.data!.docs.map((post) => _buildPostSearchResult(post)),
                    ],
                  );
                }

                // No results
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(Color(0xFF7C3AED)),
                    ),
                  );
                }

                return const Column(
                  children: [
                    Icon(Icons.search_off_rounded, size: 64, color: Color(0xFF94A3B8)),
                    SizedBox(height: 16),
                    Text(
                      'No results found',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Try searching with different keywords',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserSearchResult(Map<String, dynamic> user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF7C3AED),
            child: Text(
              user['avatar'] ?? user['displayName']?[0] ?? 'U',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['displayName'] ?? 'User',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  user['bio'] ?? 'SocialNest user',
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.person_add_rounded, color: Color(0xFF7C3AED)),
            onPressed: () {
              // Add friend functionality
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGroupSearchResult(QueryDocumentSnapshot group) {
    final data = group.data() as Map<String, dynamic>;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.groups_rounded, color: Colors.blue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['name'] ?? 'Study Group',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  data['description'] ?? '',
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${data['memberCount'] ?? 0} members • ${data['subject'] ?? 'General'}',
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.group_add_rounded, color: Color(0xFF7C3AED)),
            onPressed: () {
              _joinStudyGroup(group.id, data['name'] ?? 'Study Group');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPostSearchResult(QueryDocumentSnapshot post) {
    final data = post.data() as Map<String, dynamic>;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFF7C3AED),
                child: Text(
                  data['userAvatar'] ?? 'U',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                data['userName'] ?? 'User',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            data['content'] ?? '',
            style: const TextStyle(
              color: Colors.white,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.favorite_rounded, color: Colors.red.shade400, size: 14),
              const SizedBox(width: 4),
              Text(
                '${data['likes'] ?? 0}',
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.chat_bubble_rounded, color: Colors.white.withOpacity(0.6), size: 14),
              const SizedBox(width: 4),
              Text(
                '${data['comments'] ?? 0}',
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Featured Section
  Widget _buildFeaturedSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Featured Today',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 160,
              child: StreamBuilder<QuerySnapshot>(
                stream: _getTrendingPosts(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(Color(0xFF7C3AED)),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return _buildEmptyFeatured();
                  }

                  final posts = snapshot.data!.docs;

                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      final post = posts[index];
                      final data = post.data() as Map<String, dynamic>;
                      return _buildFeaturedItem(data, post.id);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyFeatured() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.trending_up_rounded, size: 40, color: Color(0xFF94A3B8)),
          SizedBox(height: 8),
          Text(
            'No trending content yet',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Be the first to create engaging content!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedItem(Map<String, dynamic> post, String postId) {
    final hasImage = post['imageUrl'] != null && post['imageUrl'].toString().isNotEmpty;
    
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasImage)
            Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                image: DecorationImage(
                  image: NetworkImage(post['imageUrl']!),
                  fit: BoxFit.cover,
                ),
              ),
            )
          else
            Container(
              height: 100,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF7C3AED),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: const Center(
                child: Icon(Icons.trending_up_rounded, color: Colors.white, size: 40),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post['content'] != null 
                      ? (post['content'] as String).length > 60 
                        ? '${(post['content'] as String).substring(0, 60)}...'
                        : post['content']
                      : 'Featured Post',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xFF06B6D4),
                      radius: 12,
                      child: Text(
                        post['userAvatar'] ?? 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      post['userName'] ?? 'User',
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(Icons.favorite_rounded, color: Colors.red.shade400, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          '${post['likes'] ?? 0}',
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Popular Groups Section
  Widget _buildPopularGroupsSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Popular Study Groups',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: Provider.of<FirebaseService>(context).getAllStudyGroups(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(Color(0xFF7C3AED)),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyGroups();
                }

                final groups = snapshot.data!.docs;

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: groups.length,
                  itemBuilder: (context, index) {
                    final group = groups[index];
                    final data = group.data() as Map<String, dynamic>;
                    return _buildGroupCard(data, group.id);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyGroups() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.groups_rounded, size: 64, color: Color(0xFF94A3B8)),
          const SizedBox(height: 16),
          const Text(
            'No Study Groups Yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Be the first to create a study group!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              // Navigate to create group screen
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
            ),
            child: const Text('Create Group'),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupCard(Map<String, dynamic> group, String groupId) {
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            // Navigate to group details
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Emoji/Icon
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _getGroupColor(group['subject']).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      _getGroupEmoji(group['subject']),
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Title
                Text(
                  group['name'] ?? 'Study Group',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                
                // Description
                Text(
                  group['description'] ?? '',
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                
                // Members and Join Button
                Row(
                  children: [
                    Text(
                      '${group['memberCount'] ?? 0} members',
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 10,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C3AED).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: GestureDetector(
                        onTap: () {
                          _joinStudyGroup(groupId, group['name'] ?? 'Study Group');
                        },
                        child: Text(
                          'Join',
                          style: TextStyle(
                            color: const Color(0xFF7C3AED),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Trending Posts Section
  Widget _buildTrendingPostsSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Trending Posts',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: _getPopularPosts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(Color(0xFF7C3AED)),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyTrending();
                }

                final posts = snapshot.data!.docs;

                return Column(
                  children: posts.map((post) {
                    final data = post.data() as Map<String, dynamic>;
                    return _buildTrendingPostItem(data, post.id);
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyTrending() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        children: [
          Icon(Icons.trending_up_rounded, size: 64, color: Color(0xFF94A3B8)),
          SizedBox(height: 16),
          Text(
            'No trending posts yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Create engaging posts to get more likes and comments!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingPostItem(Map<String, dynamic> post, String postId) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF7C3AED),
            child: Text(
              post['userAvatar'] ?? 'U',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post['userName'] ?? 'User',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  post['content'] ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.favorite_rounded, color: Colors.red.shade400, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${post['likes'] ?? 0}',
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.chat_bubble_rounded, color: Colors.white.withOpacity(0.6), size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${post['comments'] ?? 0}',
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Trending',
                        style: TextStyle(
                          color: Colors.amber,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods for group styling
  Color _getGroupColor(String? subject) {
    switch (subject?.toLowerCase()) {
      case 'mathematics':
      case 'math':
        return Colors.blue;
      case 'science':
        return Colors.green;
      case 'physics':
        return Colors.orange;
      case 'chemistry':
        return Colors.purple;
      case 'biology':
        return Colors.green;
      case 'programming':
        return Colors.blue;
      case 'history':
        return Colors.amber;
      case 'languages':
        return Colors.red;
      default:
        return const Color(0xFF7C3AED);
    }
  }

  String _getGroupEmoji(String? subject) {
    switch (subject?.toLowerCase()) {
      case 'mathematics':
      case 'math':
        return '📐';
      case 'science':
        return '🔬';
      case 'physics':
        return '⚛️';
      case 'chemistry':
        return '🧪';
      case 'biology':
        return '🧬';
      case 'programming':
        return '💻';
      case 'history':
        return '📜';
      case 'languages':
        return '🌍';
      default:
        return '📚';
    }
  }
}