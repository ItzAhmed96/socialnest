import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase_service.dart';
import 'comments_screen.dart';
import 'saved_posts_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  int _selectedTab = 0;
  final List<String> _tabs = ['Posts', 'Saved Posts', 'Study Groups'];
  final ScrollController _scrollController = ScrollController();
  final PageController _storyController = PageController();

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
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    _storyController.dispose();
    super.dispose();
  }

  void _signOut() {
    Provider.of<FirebaseService>(context, listen: false).signOut();
    Navigator.pushNamedAndRemoveUntil(context, '/welcome', (route) => false);
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
            child: SlideTransition(
              position: _slideAnimation,
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(firebaseService.currentUser?.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildLoadingScreen();
                  }

                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return _buildProfileContent(firebaseService, null);
                  }

                  final userData = snapshot.data!.data() as Map<String, dynamic>;
                  return _buildProfileContent(firebaseService, userData);
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: const Color(0xFF0F172A),
          elevation: 0,
          pinned: true,
          expandedHeight: 200,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF0F172A),
                    Color(0xFF1E293B),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Color(0xFF7C3AED)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileContent(FirebaseService firebaseService, Map<String, dynamic>? userData) {
    final displayName = userData?['displayName'] ?? firebaseService.userName ?? 'User';
    final email = firebaseService.userEmail ?? 'user@socialnest.com';
    final bio = userData?['bio'] ?? 'Teen learner passionate about science and tech!';
    final postsCount = userData?['postsCount'] ?? 0;
    final friendsCount = userData?['friendsCount'] ?? 0;
    final level = userData?['level'] ?? 1;
    final points = userData?['points'] ?? 0;
    final avatar = userData?['avatar'] ?? displayName[0];
    final joinDate = userData?['createdAt'] != null 
        ? (userData!['createdAt'] as Timestamp).toDate() 
        : DateTime.now();

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverAppBar(
          backgroundColor: const Color(0xFF0F172A),
          elevation: 0,
          pinned: true,
          expandedHeight: 320,
          flexibleSpace: FlexibleSpaceBar(
            collapseMode: CollapseMode.pin,
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF0F172A),
                    Color(0xFF1E293B),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(top: 80, left: 24, right: 24, bottom: 24),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF7C3AED),
                                    Color(0xFF06B6D4),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF7C3AED).withOpacity(0.4),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                backgroundColor: Colors.transparent,
                                child: Text(
                                  avatar,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F172A),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFF7C3AED),
                                    width: 2,
                                  ),
                                ),
                                child: Text(
                                  level.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(width: 20),
                        
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                email,
                                style: const TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildStatItem(postsCount, 'Posts'),
                                  _buildStatItem(friendsCount, 'Friends'),
                                  _buildStatItem(points, 'Points'),
                                  _buildStatItem(level, 'Level'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bio,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.calendar_today_rounded, 
                                size: 14, color: Colors.white.withOpacity(0.6)),
                            const SizedBox(width: 6),
                            Text(
                              'Joined ${_formatJoinDate(joinDate)}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            'Edit Profile',
                            Icons.edit_rounded,
                            () {
                              _showEditProfileDialog(displayName, bio, firebaseService);
                            },
                            isPrimary: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        _buildActionButton(
                          'Settings',
                          Icons.settings_rounded,
                          () {
                            _showSettingsBottomSheet(firebaseService);
                          },
                          isPrimary: false,
                        ),
                        const SizedBox(width: 12),
                        _buildActionButton(
                          'Share',
                          Icons.share_rounded,
                          () {
                            _shareProfile(displayName);
                          },
                          isPrimary: false,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.more_vert_rounded, size: 20, color: Colors.white),
              ),
              onPressed: () {
                _showQuickMenuBottomSheet(firebaseService);
              },
            ),
          ],
        ),

        SliverToBoxAdapter(
          child: _buildLearningJourney(level, points, userData),
        ),

        SliverPersistentHeader(
          pinned: true,
          delegate: _SliverAppBarDelegate(
            child: Container(
              color: const Color(0xFF0F172A),
              child: Column(
                children: [
                  Container(
                    height: 1,
                    color: Colors.white.withOpacity(0.1),
                  ),
                  Container(
                    height: 60,
                    color: const Color(0xFF0F172A),
                    child: Row(
                      children: List.generate(_tabs.length, (index) {
                        final isSelected = _selectedTab == index;
                        return Expanded(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => setState(() => _selectedTab = index),
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: isSelected ? const Color(0xFF7C3AED) : Colors.transparent,
                                      width: 3,
                                    ),
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _tabs[index],
                                      style: TextStyle(
                                        color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        _buildTabContent(_selectedTab, firebaseService),
      ],
    );
  }

  Widget _buildStatItem(int count, String label) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(String text, IconData icon, VoidCallback onTap, {bool isPrimary = false}) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: isPrimary ? const Color(0xFF7C3AED) : const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: isPrimary ? null : Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: Colors.white),
              if (text.isNotEmpty) ...[
                const SizedBox(width: 6),
                Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLearningJourney(int level, int points, Map<String, dynamic>? userData) {
    final nextLevelPoints = level * 1000;
    final progress = points / nextLevelPoints;
    
    final studyHours = userData?['studyHours'] ?? 0;
    final quizzesCompleted = userData?['quizzesCompleted'] ?? 0;
    final notesCreated = userData?['notesCreated'] ?? 0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: Color(0xFF7C3AED), size: 20),
              const SizedBox(width: 8),
              const Text(
                'Learning Journey',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Level $level',
                  style: const TextStyle(
                    color: Color(0xFF7C3AED),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$points XP',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '$nextLevelPoints XP',
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Stack(
                  children: [
                    Container(
                      height: 8,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 800),
                      height: 8,
                      width: (MediaQuery.of(context).size.width - 72) * progress.clamp(0.0, 1.0),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF7C3AED),
                            Color(0xFF06B6D4),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${(progress * 100).toStringAsFixed(1)}% to Level ${level + 1}',
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildJourneyStat('Study Hours', '${studyHours}h', Icons.school_rounded),
              _buildJourneyStat('Quizzes', quizzesCompleted.toString(), Icons.quiz_rounded),
              _buildJourneyStat('Notes', notesCreated.toString(), Icons.note_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildJourneyStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: const Color(0xFF7C3AED)),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildTabContent(int tabIndex, FirebaseService firebaseService) {
    switch (tabIndex) {
      case 0:
        return _buildMyContentTab(firebaseService);
      case 1:
        return _buildSavedPostsTab(firebaseService);
      case 2:
        return _buildStudyGroupsTab(firebaseService);
      default:
        return _buildMyContentTab(firebaseService);
    }
  }

  Widget _buildMyContentTab(FirebaseService firebaseService) {
    return StreamBuilder<QuerySnapshot>(
      stream: firebaseService.getUserPosts(firebaseService.currentUser!.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(Color(0xFF7C3AED)),
                ),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Icon(Icons.error_outline_rounded, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Error Loading Posts',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Error: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Icon(Icons.lightbulb_outline_rounded, size: 80, color: Color(0xFF94A3B8)),
                  const SizedBox(height: 16),
                  const Text(
                    'No Posts Yet',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Start by creating educational posts, quizzes, or study resources to help others learn.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/create');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text('Create First Post'),
                  ),
                ],
              ),
            ),
          );
        }

        final posts = snapshot.data!.docs;

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final post = posts[index];
              final postData = post.data() as Map<String, dynamic>;
              return _buildPostItem(postData, post.id, firebaseService);
            },
            childCount: posts.length,
          ),
        );
      },
    );
  }

  Widget _buildSavedPostsTab(FirebaseService firebaseService) {
    return StreamBuilder<QuerySnapshot>(
      stream: firebaseService.getSavedPosts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(Color(0xFF7C3AED)),
                ),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Icon(Icons.error_outline_rounded, size: 64, color: Color(0xFF94A3B8)),
                  const SizedBox(height: 16),
                  const Text(
                    'Error Loading Saved Posts',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
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
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Icon(Icons.bookmark_border_rounded, size: 80, color: Color(0xFF94A3B8)),
                  const SizedBox(height: 16),
                  const Text(
                    'No Saved Posts Yet',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Save interesting posts, study tips, and resources to find them here later!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Explore Posts'),
                  ),
                ],
              ),
            ),
          );
        }

        final savedPosts = snapshot.data!.docs;

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final savedPost = savedPosts[index];
              final savedData = savedPost.data() as Map<String, dynamic>;
              return _buildSavedPostItem(savedData, firebaseService);
            },
            childCount: savedPosts.length,
          ),
        );
      },
    );
  }

  Widget _buildSavedPostItem(Map<String, dynamic> savedData, FirebaseService firebaseService) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              'Saved ${_getTimeAgo(savedData['savedAt'])}',
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
                
                if (savedData['imageUrl'] != null && savedData['imageUrl'].toString().isNotEmpty) ...[
                  const SizedBox(height: 12),
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
              ],
            ),
          ),

          const SizedBox(height: 12),

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
                _buildProfilePostAction(
                  Icons.visibility_rounded,
                  'View',
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CommentsScreen(
                          postId: savedData['postId'],
                          postContent: savedData['postPreview'] ?? 'Saved post',
                        ),
                      ),
                    );
                  },
                ),
                _buildProfilePostAction(
                  Icons.share_rounded,
                  'Share',
                  () {
                    _shareSavedPost(savedData, context);
                  },
                ),
                _buildProfilePostAction(
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

  Widget _buildProfilePostAction(IconData icon, String label, VoidCallback onTap) {
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

  Widget _buildStudyGroupsTab(FirebaseService firebaseService) {
    return StreamBuilder<QuerySnapshot>(
      stream: firebaseService.getUserStudyGroups(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(Color(0xFF7C3AED)),
                ),
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Icon(Icons.groups_rounded, size: 80, color: Color(0xFF94A3B8)),
                  const SizedBox(height: 16),
                  const Text(
                    'No Study Groups',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Join or create study groups to collaborate with friends and classmates.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Explore Groups'),
                  ),
                ],
              ),
            ),
          );
        }

        final groups = snapshot.data!.docs;

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final group = groups[index];
              final data = group.data() as Map<String, dynamic>;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
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
                    const SizedBox(width: 16),
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
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${data['memberCount'] ?? 0} members • ${data['subject'] ?? 'General'}',
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
            childCount: groups.length,
          ),
        );
      },
    );
  }

  Widget _buildPostItem(Map<String, dynamic> post, String postId, FirebaseService firebaseService) {
    final hasImage = post['imageUrl'] != null && post['imageUrl'].toString().isNotEmpty;
    final isQuiz = post['type'] == 'quiz';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              style: const TextStyle(
                color: Color(0xFF94A3B8),
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getPostColor(post['type'] ?? 'social').withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_getPostIcon(post['type'] ?? 'social'), size: 12, color: _getPostColor(post['type'] ?? 'social')),
                      const SizedBox(width: 4),
                      Text(
                        _getPostTypeLabel(post['type'] ?? 'social'),
                        style: TextStyle(
                          color: _getPostColor(post['type'] ?? 'social'),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF94A3B8), size: 20),
                  onPressed: () => _showPostOptions(context, post, postId),
                ),
              ],
            ),
          ),

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

          if (hasImage) ...[
            const SizedBox(height: 12),
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

          if (isQuiz && post['quizOptions'] != null) ...[
            const SizedBox(height: 12),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quiz Options:',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...List.generate(
                    post['quizOptions'].length,
                    (index) {
                      final option = post['quizOptions'][index];
                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${index + 1}. $option',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

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
                Text(
                  '${post['shares'] ?? 0} shares',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

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
                _buildPostAction(
                  Icons.share_rounded,
                  'Share',
                  Colors.white.withOpacity(0.6),
                  () {},
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

  void _showPostOptions(BuildContext context, Map<String, dynamic> post, String postId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPostOption(
              Icons.edit_rounded,
              'Edit Post',
              Colors.blue,
              () {
                Navigator.pop(context);
                _editPost(post, postId);
              },
            ),
            _buildPostOption(
              Icons.delete_rounded,
              'Delete Post',
              Colors.red,
              () {
                Navigator.pop(context);
                _deletePost(postId);
              },
            ),
            const SizedBox(height: 8),
            Container(height: 1, color: Colors.white.withOpacity(0.1)),
            const SizedBox(height: 8),
            _buildPostOption(
              Icons.cancel_rounded,
              'Cancel',
              const Color(0xFF94A3B8),
              () => Navigator.pop(context),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPostOption(IconData icon, String title, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _editPost(Map<String, dynamic> post, String postId) {
    final contentController = TextEditingController(text: post['content'] ?? '');
    
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
              const Text(
                'Edit Post',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: contentController,
                maxLines: 4,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Post Content',
                  labelStyle: TextStyle(color: Color(0xFF94A3B8)),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF7C3AED)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF7C3AED)),
                  ),
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
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (contentController.text.trim().isNotEmpty) {
                          await _updatePost(postId, contentController.text.trim());
                          if (mounted) Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Text('Save'),
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

  Future<void> _updatePost(String postId, String newContent) async {
    try {
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .update({
            'content': newContent,
            'updatedAt': FieldValue.serverTimestamp(),
          });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update post: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _deletePost(String postId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text(
          'Delete Post',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to delete this post? This action cannot be undone.',
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
            onPressed: () async {
              Navigator.pop(context);
              await _confirmDeletePost(postId);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeletePost(String postId) async {
    try {
      final commentsSnapshot = await FirebaseFirestore.instance
          .collection('comments')
          .where('postId', isEqualTo: postId)
          .get();
      
      final batch = FirebaseFirestore.instance.batch();
      
      for (final comment in commentsSnapshot.docs) {
        batch.delete(comment.reference);
      }
      
      batch.delete(FirebaseFirestore.instance.collection('posts').doc(postId));
      
      final firebaseService = Provider.of<FirebaseService>(context, listen: false);
      await firebaseService.updateUserStats(postsCount: -1);
      
      await batch.commit();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post deleted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete post: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
    final time = timestamp.toDate();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${(difference.inDays / 7).floor()}w ago';
  }

  String _formatJoinDate(DateTime joinDate) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[joinDate.month - 1]} ${joinDate.year}';
  }

  void _showSettingsBottomSheet(FirebaseService firebaseService) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSettingsOption(Icons.settings_rounded, 'Account Settings', () {}),
            _buildSettingsOption(Icons.notifications_rounded, 'Notifications', () {}),
            _buildSettingsOption(Icons.privacy_tip_rounded, 'Privacy & Security', () {}),
            _buildSettingsOption(Icons.help_rounded, 'Help & Support', () {}),
            _buildSettingsOption(Icons.info_rounded, 'About SocialNest', () {}),
            const SizedBox(height: 8),
            Container(height: 1, color: Colors.white.withOpacity(0.1)),
            const SizedBox(height: 8),
            _buildSettingsOption(Icons.logout_rounded, 'Log Out', _signOut, isDestructive: true),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showQuickMenuBottomSheet(FirebaseService firebaseService) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildQuickMenuOption(Icons.qr_code_rounded, 'My QR Code', () {}),
            _buildQuickMenuOption(Icons.person_add_rounded, 'Invite Friends', () {}),
            _buildQuickMenuOption(Icons.analytics_rounded, 'View Analytics', () {}),
            _buildQuickMenuOption(Icons.bookmark_rounded, 'Saved Items', () {}),
            _buildQuickMenuOption(Icons.history_rounded, 'Activity History', () {}),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _shareProfile(String displayName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Share Profile', style: TextStyle(color: Colors.white)),
        content: Text('Share $displayName\'s profile with others', style: const TextStyle(color: Color(0xFF94A3B8))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$displayName\'s profile shared!'),
                  backgroundColor: const Color(0xFF7C3AED),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
            ),
            child: const Text('Share', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsOption(IconData icon, String title, VoidCallback onTap, {bool isDestructive = false}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            children: [
              Icon(icon, color: isDestructive ? Colors.red : Colors.white, size: 24),
              const SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(
                  color: isDestructive ? Colors.red : Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickMenuOption(IconData icon, String title, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditProfileDialog(String currentName, String currentBio, FirebaseService firebaseService) {
    final nameController = TextEditingController(text: currentName);
    final bioController = TextEditingController(text: currentBio);

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
              const Text(
                'Edit Profile',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Display Name',
                  labelStyle: TextStyle(color: Color(0xFF94A3B8)),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF7C3AED)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF7C3AED)),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: bioController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Bio',
                  labelStyle: TextStyle(color: Color(0xFF94A3B8)),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF7C3AED)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF7C3AED)),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
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
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final success = await firebaseService.updateProfile(
                          nameController.text.trim(),
                          bioController.text.trim(),
                        );
                        if (success && mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Profile updated successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Failed to update profile'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Text('Save'),
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
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _SliverAppBarDelegate({required this.child});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  double get maxExtent => 61;

  @override
  double get minExtent => 61;

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return child != oldDelegate.child;
  }
}