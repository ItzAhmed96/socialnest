import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase_service.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  int _selectedTab = 0;
  final List<String> _tabs = ['Friends', 'Requests', 'Find Friends'];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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
                  expandedHeight: 150,
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
                            'Friends',
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
                    if (_selectedTab == 2)
                      IconButton(
                        icon: const Icon(Icons.search_rounded, color: Colors.white),
                        onPressed: () {},
                      ),
                  ],
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Friends Stats
                        StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .doc(firebaseService.currentUser?.uid)
                              .snapshots(),
                          builder: (context, snapshot) {
                            int friendsCount = 0;
                            if (snapshot.hasData && snapshot.data!.exists) {
                              final data = snapshot.data!.data() as Map<String, dynamic>?;
                              friendsCount = data?['friendsCount'] ?? 0;
                            }
                            
                            return Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildStatItem(friendsCount.toString(), 'Friends'),
                                  StreamBuilder<QuerySnapshot>(
                                    stream: firebaseService.getFriendRequests(),
                                    builder: (context, snapshot) {
                                      final requestCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
                                      return _buildStatItem(requestCount.toString(), 'Requests');
                                    },
                                  ),
                                  _buildStatItem('', 'Find New'),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),

                        // Tab Selection
                        Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Row(
                            children: List.generate(_tabs.length, (index) {
                              final isSelected = _selectedTab == index;
                              return Expanded(
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(15),
                                    onTap: () => setState(() => _selectedTab = index),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: isSelected ? const Color(0xFF7C3AED) : Colors.transparent,
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      child: Center(
                                        child: Text(
                                          _tabs[index],
                                          style: TextStyle(
                                            color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Search Bar for Find Friends tab
                        if (_selectedTab == 2)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
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
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                hintText: 'Search for friends...',
                                hintStyle: TextStyle(color: Color(0xFF94A3B8)),
                                border: InputBorder.none,
                                prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF94A3B8)),
                                suffixIcon: Icon(Icons.person_add_rounded, color: Color(0xFF7C3AED)),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Debug info - Remove this after testing
                SliverToBoxAdapter(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: firebaseService.getFriendRequests(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        print('DEBUG: Found ${snapshot.data!.docs.length} friend requests');
                        for (var doc in snapshot.data!.docs) {
                          print('DEBUG: Request - ${doc.data()}');
                        }
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),

                // Content based on selected tab
                _buildTabContent(_selectedTab, firebaseService),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildTabContent(int tabIndex, FirebaseService firebaseService) {
    switch (tabIndex) {
      case 0: // Friends
        return _buildFriendsList(firebaseService);
      case 1: // Requests
        return _buildRequestsList(firebaseService);
      case 2: // Find Friends
        return _buildFindFriendsList(firebaseService);
      default:
        return _buildFriendsList(firebaseService);
    }
  }

  Widget _buildFriendsList(FirebaseService firebaseService) {
    return StreamBuilder<QuerySnapshot>(
      stream: firebaseService.getFriends(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Color(0xFF7C3AED)),
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Icon(Icons.people_outline_rounded, size: 64, color: Color(0xFF94A3B8)),
                  const SizedBox(height: 16),
                  const Text(
                    'No friends yet',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Start adding friends to see them here!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _selectedTab = 2;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Find Friends'),
                  ),
                ],
              ),
            ),
          );
        }

        final friends = snapshot.data!.docs;

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final friend = friends[index];
              final friendData = friend.data() as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: _buildFriendCard(friendData, true, firebaseService),
              );
            },
            childCount: friends.length,
          ),
        );
      },
    );
  }

  Widget _buildRequestsList(FirebaseService firebaseService) {
    return StreamBuilder<QuerySnapshot>(
      stream: firebaseService.getFriendRequests(),
      builder: (context, snapshot) {
        print('DEBUG: Building requests list - hasData: ${snapshot.hasData}');
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Color(0xFF7C3AED)),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          print('DEBUG: Error in requests stream: ${snapshot.error}');
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Icon(Icons.person_add_disabled_rounded, size: 64, color: Color(0xFF94A3B8)),
                  const SizedBox(height: 16),
                  const Text(
                    'No pending requests',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'When someone sends you a friend request, it will appear here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Debug button to check Firestore
                  ElevatedButton(
                    onPressed: () {
                      _checkFirestoreData(firebaseService);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Debug: Check Firestore'),
                  ),
                ],
              ),
            ),
          );
        }

        final requests = snapshot.data!.docs;
        print('DEBUG: Found ${requests.length} requests');

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final request = requests[index];
              final requestData = request.data() as Map<String, dynamic>;
              print('DEBUG: Request data: $requestData');
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: _buildRequestCard(requestData, request.id, firebaseService),
              );
            },
            childCount: requests.length,
          ),
        );
      },
    );
  }

  void _checkFirestoreData(FirebaseService firebaseService) async {
    print('=== DEBUG: Checking Firestore Data ===');
    
    // Check current user
    print('Current User ID: ${firebaseService.currentUser?.uid}');
    
    // Check friend_requests collection
    try {
      final requestsSnapshot = await FirebaseFirestore.instance
          .collection('friend_requests')
          .where('toUserId', isEqualTo: firebaseService.currentUser?.uid)
          .where('status', isEqualTo: 'pending')
          .get();
      
      print('Found ${requestsSnapshot.docs.length} pending requests for current user');
      for (var doc in requestsSnapshot.docs) {
        print('Request: ${doc.data()}');
      }
    } catch (e) {
      print('Error checking requests: $e');
    }
  }

  Widget _buildFindFriendsList(FirebaseService firebaseService) {
    if (_searchQuery.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              const Icon(Icons.search_rounded, size: 64, color: Color(0xFF94A3B8)),
              const SizedBox(height: 16),
              const Text(
                'Find Friends',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Search for friends by their name to connect with them!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: firebaseService.searchUsers(_searchQuery),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Color(0xFF7C3AED)),
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                children: [
                  Icon(Icons.person_off_rounded, size: 64, color: Color(0xFF94A3B8)),
                  SizedBox(height: 16),
                  Text(
                    'No users found',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Try searching with a different name',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final users = snapshot.data!;

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final user = users[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: _buildUserCard(user, firebaseService),
              );
            },
            childCount: users.length,
          ),
        );
      },
    );
  }

  Widget _buildFriendCard(Map<String, dynamic> friendData, bool isFriend, FirebaseService firebaseService) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF7C3AED),
            radius: 25,
            child: Text(
              friendData['userAvatar'] ?? 'U',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friendData['userName'] ?? 'User',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                if (friendData['friendsSince'] != null)
                  Text(
                    'Friends since ${_getTimeAgo(friendData['friendsSince'])}',
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          if (isFriend)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF94A3B8)),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'remove',
                  child: Row(
                    children: [
                      Icon(Icons.person_remove_rounded, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Remove Friend'),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'remove') {
                  firebaseService.removeFriend(friendData['userId']);
                }
              },
            ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> requestData, String requestId, FirebaseService firebaseService) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF7C3AED),
            radius: 25,
            child: Text(
              requestData['fromUserAvatar'] ?? 'U',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  requestData['fromUserName'] ?? 'User',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sent ${_getTimeAgo(requestData['createdAt'])}',
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded, size: 18, color: Color(0xFF10B981)),
                ),
                onPressed: () => firebaseService.acceptFriendRequest(requestId),
              ),
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded, size: 18, color: Color(0xFFEF4444)),
                ),
                onPressed: () => firebaseService.rejectFriendRequest(requestId),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> userData, FirebaseService firebaseService) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: firebaseService.getFriendStatus(userData['id']),
      builder: (context, snapshot) {
        final friendStatus = snapshot.data ?? {'status': 'not_friends'};
        final status = friendStatus['status'];

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFF7C3AED),
                radius: 25,
                child: Text(
                  userData['avatar'] ?? userData['displayName']?[0] ?? 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userData['displayName'] ?? 'User',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userData['bio'] ?? 'SocialNest user',
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (status == 'not_friends')
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person_add_rounded, size: 18, color: Color(0xFF7C3AED)),
                  ),
                  onPressed: () => firebaseService.sendFriendRequest(
                    userData['id'],
                    userData['displayName'] ?? 'User',
                    userData['avatar'] ?? userData['displayName']?[0] ?? 'U',
                  ),
                ),
              if (status == 'request_sent')
                const Text(
                  'Request Sent',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                  ),
                ),
              if (status == 'friends')
                const Text(
                  'Friends',
                  style: TextStyle(
                    color: Color(0xFF10B981),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}