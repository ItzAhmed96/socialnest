import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../models/story_model.dart';

class FirebaseService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => _auth.currentUser != null;
  String? get userEmail => _auth.currentUser?.email;
  String? get userName => _auth.currentUser?.displayName;
  String? get userAvatar => _auth.currentUser?.displayName?[0] ?? _auth.currentUser?.email?[0];

  // ========== AUTHENTICATION METHODS ==========

  Future<bool> signUp(String email, String password, String displayName) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await userCredential.user!.updateDisplayName(displayName);

      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email,
        'displayName': displayName,
        'bio': 'Teen learner passionate about science and tech!',
        'avatar': displayName[0],
        'level': 1,
        'points': 0,
        'friendsCount': 0,
        'postsCount': 0,
        'studyHours': 0,
        'quizzesCompleted': 0,
        'notesCreated': 0,
        'unreadNotifications': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      notifyListeners();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('🔥 Firebase Sign Up Error: $e');
      }
      if (e is FirebaseAuthException) {
        print('🔥 Firebase Auth Error Code: ${e.code}');
        print('🔥 Firebase Auth Error Message: ${e.message}');
      }
      return false;
    }
  }

  Future<bool> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      notifyListeners();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Sign in error: $e');
      }
      return false;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    notifyListeners();
  }

  Future<Map<String, dynamic>?> getUserData() async {
    try {
      if (_auth.currentUser == null) return null;
      
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(_auth.currentUser!.uid).get();
      return userDoc.data() as Map<String, dynamic>?;
    } catch (e) {
      if (kDebugMode) {
        print('Get user data error: $e');
      }
      return null;
    }
  }

  // ========== PROFILE METHODS ==========

  Future<bool> updateProfile(String displayName, String bio) async {
    try {
      if (_auth.currentUser == null) return false;

      await _auth.currentUser!.updateDisplayName(displayName);

      await _firestore.collection('users').doc(_auth.currentUser!.uid).update({
        'displayName': displayName,
        'bio': bio,
        'avatar': displayName[0],
        'updatedAt': FieldValue.serverTimestamp(),
      });

      notifyListeners();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Update profile error: $e');
      }
      return false;
    }
  }
  Future<bool> savePost(String postId) async {
  try {
    if (_auth.currentUser == null) return false;

    final userRef = _firestore.collection('users').doc(_auth.currentUser!.uid);
    final savedPostRef = userRef.collection('saved_posts').doc(postId);

    // Check if already saved
    final savedDoc = await savedPostRef.get();
    if (savedDoc.exists) {
      return true; // Already saved
    }

    // Get post data for preview
    final postDoc = await _firestore.collection('posts').doc(postId).get();
    if (!postDoc.exists) return false;

    final postData = postDoc.data() as Map<String, dynamic>;

    // Save to user's saved_posts
    await savedPostRef.set({
      'postId': postId,
      'savedAt': FieldValue.serverTimestamp(),
      'postType': postData['type'] ?? 'social',
      'postPreview': postData['content'] != null 
          ? (postData['content'] as String).length > 100 
            ? '${(postData['content'] as String).substring(0, 100)}...'
            : postData['content']
          : 'Saved post',
      'userName': postData['userName'],
      'userAvatar': postData['userAvatar'],
      'imageUrl': postData['imageUrl'],
    });

    // Update post's save count
    await _firestore.collection('posts').doc(postId).update({
      'saveCount': FieldValue.increment(1),
    });

    await addUserActivity(
      'post_saved',
      'Post Saved',
      'You saved a post to your collection',
      data: {'postId': postId},
    );

    notifyListeners();
    return true;
  } catch (e) {
    if (kDebugMode) {
      print('Save post error: $e');
    }
    return false;
  }
}

Future<bool> unsavePost(String postId) async {
  try {
    if (_auth.currentUser == null) return false;

    await _firestore
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .collection('saved_posts')
        .doc(postId)
        .delete();

    // Update post's save count
    await _firestore.collection('posts').doc(postId).update({
      'saveCount': FieldValue.increment(-1),
    });

    notifyListeners();
    return true;
  } catch (e) {
    if (kDebugMode) {
      print('Unsave post error: $e');
    }
    return false;
  }
}

Stream<bool> getPostSaveStatus(String postId) {
  try {
    if (_auth.currentUser == null) return Stream.value(false);
    
    return _firestore
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .collection('saved_posts')
        .doc(postId)
        .snapshots()
        .map((snapshot) => snapshot.exists);
  } catch (e) {
    if (kDebugMode) {
      print('Get post save status error: $e');
    }
    return Stream.value(false);
  }
}

Stream<QuerySnapshot> getSavedPosts() {
  try {
    if (_auth.currentUser == null) {
      return const Stream.empty();
    }
    
    return _firestore
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .collection('saved_posts')
        .orderBy('savedAt', descending: true)
        .snapshots();
  } catch (e) {
    if (kDebugMode) {
      print('Get saved posts error: $e');
    }
    return const Stream.empty();
  }
}
  // ========== USER STATS & PROGRESS METHODS ==========

  Future<void> updateUserStats({
    int? postsCount,
    double? studyHours,
    int? quizzesCompleted,
    int? notesCreated,
    int? points,
  }) async {
    try {
      if (_auth.currentUser == null) return;

      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (postsCount != null) updateData['postsCount'] = FieldValue.increment(postsCount);
      if (studyHours != null) updateData['studyHours'] = FieldValue.increment(studyHours);
      if (quizzesCompleted != null) updateData['quizzesCompleted'] = FieldValue.increment(quizzesCompleted);
      if (notesCreated != null) updateData['notesCreated'] = FieldValue.increment(notesCreated);
      if (points != null) updateData['points'] = FieldValue.increment(points);

      if (updateData.isNotEmpty) {
        await _firestore.collection('users').doc(_auth.currentUser!.uid).update(updateData);
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Update user stats error: $e');
      }
    }
  }

  // ========== ACTIVITY METHODS ==========

  Future<void> addUserActivity(String type, String title, String description, {Map<String, dynamic>? data}) async {
    try {
      if (_auth.currentUser == null) return;

      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('recent_activities')
          .add({
            'type': type,
            'title': title,
            'description': description,
            'data': data ?? {},
            'timestamp': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      if (kDebugMode) {
        print('Add user activity error: $e');
      }
    }
  }

  Stream<QuerySnapshot> getUserActivities() {
    try {
      if (_auth.currentUser == null) {
        return const Stream.empty();
      }
      
      return _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('recent_activities')
          .orderBy('timestamp', descending: true)
          .limit(10)
          .snapshots();
    } catch (e) {
      if (kDebugMode) {
        print('Get user activities error: $e');
      }
      return const Stream.empty();
    }
  }

  // ========== ACHIEVEMENT METHODS ==========

  Future<void> unlockAchievement(String achievementId, String title, String description, int points) async {
    try {
      if (_auth.currentUser == null) return;

      final achievementDoc = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('achievements')
          .doc(achievementId)
          .get();

      if (!achievementDoc.exists) {
        await _firestore
            .collection('users')
            .doc(_auth.currentUser!.uid)
            .collection('achievements')
            .doc(achievementId)
            .set({
              'id': achievementId,
              'title': title,
              'description': description,
              'points': points,
              'unlockedAt': FieldValue.serverTimestamp(),
            });

        await updateUserStats(points: points);

        await addUserActivity(
          'achievement_unlocked',
          'Achievement Unlocked!',
          'You unlocked: $title',
          data: {'achievementId': achievementId, 'points': points},
        );

        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Unlock achievement error: $e');
      }
    }
  }

  Stream<QuerySnapshot> getUserAchievements() {
    try {
      if (_auth.currentUser == null) {
        return const Stream.empty();
      }
      
      return _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('achievements')
          .orderBy('unlockedAt', descending: true)
          .snapshots();
    } catch (e) {
      if (kDebugMode) {
        print('Get user achievements error: $e');
      }
      return const Stream.empty();
    }
  }

  // ========== STUDY GROUP METHODS ==========

  Future<bool> createStudyGroup(String name, String description, String subject, List<String> tags) async {
    try {
      if (_auth.currentUser == null) return false;

      final userData = await getUserData();
      final groupId = _firestore.collection('study_groups').doc().id;

      await _firestore.collection('study_groups').doc(groupId).set({
        'id': groupId,
        'name': name,
        'description': description,
        'subject': subject,
        'tags': tags,
        'createdBy': _auth.currentUser!.uid,
        'createdByName': userData?['displayName'] ?? 'User',
        'memberCount': 1,
        'members': [_auth.currentUser!.uid],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _firestore
          .collection('study_groups')
          .doc(groupId)
          .collection('members')
          .doc(_auth.currentUser!.uid)
          .set({
            'userId': _auth.currentUser!.uid,
            'userName': userData?['displayName'] ?? 'User',
            'userAvatar': userData?['avatar'] ?? 'U',
            'joinedAt': FieldValue.serverTimestamp(),
            'role': 'admin',
          });

      await addUserActivity(
        'group_created',
        'Study Group Created',
        'You created: $name',
        data: {'groupId': groupId, 'groupName': name},
      );

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Create study group error: $e');
      }
      return false;
    }
  }

  Future<bool> joinStudyGroup(String groupId) async {
    try {
      if (_auth.currentUser == null) return false;

      final userData = await getUserData();
      final groupDoc = await _firestore.collection('study_groups').doc(groupId).get();
      
      if (!groupDoc.exists) return false;

      await _firestore
          .collection('study_groups')
          .doc(groupId)
          .collection('members')
          .doc(_auth.currentUser!.uid)
          .set({
            'userId': _auth.currentUser!.uid,
            'userName': userData?['displayName'] ?? 'User',
            'userAvatar': userData?['avatar'] ?? 'U',
            'joinedAt': FieldValue.serverTimestamp(),
            'role': 'member',
          });

      await _firestore.collection('study_groups').doc(groupId).update({
        'memberCount': FieldValue.increment(1),
        'members': FieldValue.arrayUnion([_auth.currentUser!.uid]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final groupData = groupDoc.data() as Map<String, dynamic>;
      
      await addUserActivity(
        'group_joined',
        'Study Group Joined',
        'You joined: ${groupData['name']}',
        data: {'groupId': groupId, 'groupName': groupData['name']},
      );

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Join study group error: $e');
      }
      return false;
    }
  }

  Stream<QuerySnapshot> getUserStudyGroups() {
    try {
      if (_auth.currentUser == null) {
        return const Stream.empty();
      }
      
      return _firestore
          .collection('study_groups')
          .where('members', arrayContains: _auth.currentUser!.uid)
          .orderBy('updatedAt', descending: true)
          .snapshots();
    } catch (e) {
      if (kDebugMode) {
        print('Get user study groups error: $e');
      }
      return const Stream.empty();
    }
  }

  Stream<QuerySnapshot> getAllStudyGroups() {
    try {
      return _firestore
          .collection('study_groups')
          .orderBy('memberCount', descending: true)
          .limit(50)
          .snapshots();
    } catch (e) {
      if (kDebugMode) {
        print('Get all study groups error: $e');
      }
      return const Stream.empty();
    }
  }

  // ========== POST METHODS ==========

  Future<bool> createPost({
    required String content,
    required String type,
    String? imageUrl,
    String? subject,
    List<String> tags = const [],
  }) async {
    try {
      if (_auth.currentUser == null) return false;

      Map<String, dynamic>? userData = await getUserData();
      
      String postId = _firestore.collection('posts').doc().id;
      
      await _firestore.collection('posts').doc(postId).set({
        'id': postId,
        'userId': _auth.currentUser!.uid,
        'userName': userData?['displayName'] ?? _auth.currentUser!.email!.split('@').first,
        'userAvatar': userData?['avatar'] ?? _auth.currentUser!.email![0],
        'content': content,
        'type': type,
        'imageUrl': imageUrl,
        'subject': subject,
        'tags': tags,
        'likes': 0,
        'comments': 0,
        'shares': 0,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await updateUserStats(postsCount: 1);

      await addUserActivity(
        'post_created',
        'Post Created',
        'You shared: ${content.length > 50 ? content.substring(0, 50) + '...' : content}',
        data: {'postId': postId, 'type': type},
      );

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Create post error: $e');
      }
      return false;
    }
  }

  Future<bool> createQuizPost({
    required String question,
    required List<String> options,
    required String subject,
    List<String> tags = const [],
  }) async {
    try {
      if (_auth.currentUser == null) return false;

      Map<String, dynamic>? userData = await getUserData();
      
      String postId = _firestore.collection('posts').doc().id;
      
      Map<String, int> optionVotes = {};
      for (String option in options) {
        optionVotes[option] = 0;
      }

      await _firestore.collection('posts').doc(postId).set({
        'id': postId,
        'userId': _auth.currentUser!.uid,
        'userName': userData?['displayName'] ?? _auth.currentUser!.email!.split('@').first,
        'userAvatar': userData?['avatar'] ?? _auth.currentUser!.email![0],
        'content': question,
        'type': 'quiz',
        'subject': subject,
        'tags': tags,
        
        'quizOptions': options,
        'quizVotes': optionVotes,
        'votedUsers': [],
        'totalVotes': 0,
        'correctAnswer': null,
        
        'likes': 0,
        'comments': 0,
        'shares': 0,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await updateUserStats(postsCount: 1, quizzesCompleted: 1);

      await addUserActivity(
        'quiz_created',
        'Quiz Created',
        'You created a quiz: $question',
        data: {'postId': postId, 'subject': subject},
      );

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Create quiz post error: $e');
      }
      return false;
    }
  }

  Stream<QuerySnapshot> getPosts() {
    try {
      return _firestore
          .collection('posts')
          .orderBy('timestamp', descending: true)
          .snapshots();
    } catch (e) {
      if (kDebugMode) {
        print('Get posts error: $e');
      }
      return const Stream.empty();
    }
  }

  Stream<QuerySnapshot> getUserPosts(String userId) {
    try {
      return _firestore
          .collection('posts')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .snapshots();
    } catch (e) {
      if (kDebugMode) {
        print('Get user posts error: $e');
      }
      return const Stream.empty();
    }
  }

  // ========== QUIZ METHODS ==========

  Future<bool> voteOnQuiz(String postId, String selectedOption) async {
    try {
      if (_auth.currentUser == null) return false;

      final currentUserId = _auth.currentUser!.uid;

      final postDoc = await _firestore.collection('posts').doc(postId).get();
      if (!postDoc.exists) return false;
      
      final postData = postDoc.data() as Map<String, dynamic>;
      
      final List<dynamic> votedUsers = postData['votedUsers'] ?? [];
      if (votedUsers.contains(currentUserId)) {
        return false;
      }

      await _firestore.collection('posts').doc(postId).update({
        'quizVotes.$selectedOption': FieldValue.increment(1),
        'totalVotes': FieldValue.increment(1),
        'votedUsers': FieldValue.arrayUnion([currentUserId]),
      });

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Vote on quiz error: $e');
      }
      return false;
    }
  }

  Future<Map<String, dynamic>?> getQuizResults(String postId) async {
    try {
      final postDoc = await _firestore.collection('posts').doc(postId).get();
      if (!postDoc.exists) return null;
      
      final postData = postDoc.data() as Map<String, dynamic>;
      return {
        'votes': postData['quizVotes'] ?? {},
        'totalVotes': postData['totalVotes'] ?? 0,
        'hasVoted': (postData['votedUsers'] ?? []).contains(_auth.currentUser?.uid),
      };
    } catch (e) {
      if (kDebugMode) {
        print('Get quiz results error: $e');
      }
      return null;
    }
  }

  // ========== LIKE SYSTEM ==========

  Future<void> likePost(String postId) async {
    try {
      if (_auth.currentUser == null) return;

      final currentUserId = _auth.currentUser!.uid;
      final postRef = _firestore.collection('posts').doc(postId);
      
      final userLikeRef = _firestore
          .collection('posts')
          .doc(postId)
          .collection('likes')
          .doc(currentUserId);

      final userLikeDoc = await userLikeRef.get();
      
      if (userLikeDoc.exists) {
        // Unlike
        await userLikeRef.delete();
        await postRef.update({
          'likes': FieldValue.increment(-1),
        });
      } else {
        // Like
        await userLikeRef.set({
          'userId': currentUserId,
          'timestamp': FieldValue.serverTimestamp(),
        });
        await postRef.update({
          'likes': FieldValue.increment(1),
        });

        // Send notification to post owner (if it's not the current user)
        final postDoc = await postRef.get();
        if (postDoc.exists) {
          final postData = postDoc.data() as Map<String, dynamic>;
          final postOwnerId = postData['userId'];
          
          if (postOwnerId != currentUserId) {
            final userData = await getUserData();
            await sendNotification(
              receiverId: postOwnerId,
              type: 'post_like',
              title: 'Post Liked',
              message: '${userData?['displayName'] ?? userName ?? 'User'} liked your post',
              senderId: currentUserId,
              senderName: userData?['displayName'] ?? userName ?? 'User',
              senderAvatar: userData?['avatar'] ?? userAvatar ?? 'U',
              targetId: postId,
              data: {'postContent': postData['content']},
            );
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Like post error: $e');
      }
    }
  }

  Stream<bool> getPostLikeStatus(String postId) {
    try {
      if (_auth.currentUser == null) return Stream.value(false);
      
      return _firestore
          .collection('posts')
          .doc(postId)
          .collection('likes')
          .doc(_auth.currentUser!.uid)
          .snapshots()
          .map((snapshot) => snapshot.exists);
    } catch (e) {
      if (kDebugMode) {
        print('Get post like status error: $e');
      }
      return Stream.value(false);
    }
  }

  // ========== COMMENT SYSTEM ==========

  Future<bool> addComment(String postId, String content) async {
    try {
      if (_auth.currentUser == null) return false;

      Map<String, dynamic>? userData = await getUserData();
      
      String commentId = _firestore.collection('comments').doc().id;
      
      await _firestore.collection('comments').doc(commentId).set({
        'id': commentId,
        'postId': postId,
        'userId': _auth.currentUser!.uid,
        'userName': userData?['displayName'] ?? _auth.currentUser!.email!.split('@').first,
        'userAvatar': userData?['avatar'] ?? _auth.currentUser!.email![0],
        'content': content,
        'likes': 0,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await _firestore.collection('posts').doc(postId).update({
        'comments': FieldValue.increment(1),
      });

      await addUserActivity(
        'comment_created',
        'Comment Added',
        'You commented on a post',
        data: {'postId': postId},
      );

      // Send notification to post owner (if it's not the current user)
      final postDoc = await _firestore.collection('posts').doc(postId).get();
      if (postDoc.exists) {
        final postData = postDoc.data() as Map<String, dynamic>;
        final postOwnerId = postData['userId'];
        
        if (postOwnerId != _auth.currentUser!.uid) {
          await sendNotification(
            receiverId: postOwnerId,
            type: 'post_comment',
            title: 'New Comment',
            message: '${userData?['displayName'] ?? _auth.currentUser!.email!.split('@').first} commented on your post',
            senderId: _auth.currentUser!.uid,
            senderName: userData?['displayName'] ?? _auth.currentUser!.email!.split('@').first,
            senderAvatar: userData?['avatar'] ?? _auth.currentUser!.email![0],
            targetId: postId,
            data: {
              'postContent': postData['content'],
              'commentContent': content,
            },
          );
        }
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Add comment error: $e');
      }
      return false;
    }
  }

  Stream<QuerySnapshot> getComments(String postId) {
    try {
      return _firestore
          .collection('comments')
          .where('postId', isEqualTo: postId)
          .orderBy('timestamp', descending: false)
          .snapshots();
    } catch (e) {
      if (kDebugMode) {
        print('Get comments error: $e');
      }
      return const Stream.empty();
    }
  }

  Future<void> likeComment(String commentId) async {
    try {
      if (_auth.currentUser == null) return;

      final currentUserId = _auth.currentUser!.uid;
      final commentRef = _firestore.collection('comments').doc(commentId);
      
      final userLikeRef = _firestore
          .collection('comments')
          .doc(commentId)
          .collection('likes')
          .doc(currentUserId);

      final userLikeDoc = await userLikeRef.get();
      
      if (userLikeDoc.exists) {
        await userLikeRef.delete();
        await commentRef.update({
          'likes': FieldValue.increment(-1),
        });
      } else {
        await userLikeRef.set({
          'userId': currentUserId,
          'timestamp': FieldValue.serverTimestamp(),
        });
        await commentRef.update({
          'likes': FieldValue.increment(1),
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Like comment error: $e');
      }
    }
  }

  Stream<bool> getCommentLikeStatus(String commentId) {
    try {
      if (_auth.currentUser == null) return Stream.value(false);
      
      return _firestore
          .collection('comments')
          .doc(commentId)
          .collection('likes')
          .doc(_auth.currentUser!.uid)
          .snapshots()
          .map((snapshot) => snapshot.exists);
    } catch (e) {
      if (kDebugMode) {
        print('Get comment like status error: $e');
      }
      return Stream.value(false);
    }
  }

  Future<void> deleteComment(String commentId, String postId) async {
    try {
      await _firestore.collection('comments').doc(commentId).delete();
      
      await _firestore.collection('posts').doc(postId).update({
        'comments': FieldValue.increment(-1),
      });
    } catch (e) {
      if (kDebugMode) {
        print('Delete comment error: $e');
      }
    }
  }

  // ========== NOTIFICATION METHODS ==========

  Future<void> sendNotification({
    required String receiverId,
    required String type,
    required String title,
    required String message,
    required String senderId,
    required String senderName,
    required String senderAvatar,
    String? targetId,
    Map<String, dynamic>? data,
  }) async {
    try {
      if (_auth.currentUser == null) return;

      final notificationId = _firestore.collection('notifications').doc().id;

      await _firestore
          .collection('users')
          .doc(receiverId)
          .collection('notifications')
          .doc(notificationId)
          .set({
            'id': notificationId,
            'type': type,
            'title': title,
            'message': message,
            'senderId': senderId,
            'senderName': senderName,
            'senderAvatar': senderAvatar,
            'targetId': targetId,
            'data': data,
            'isRead': false,
            'timestamp': FieldValue.serverTimestamp(),
          });

      // Update user's unread notification count
      await _firestore.collection('users').doc(receiverId).update({
        'unreadNotifications': FieldValue.increment(1),
      });

    } catch (e) {
      if (kDebugMode) {
        print('Send notification error: $e');
      }
    }
  }

  Stream<QuerySnapshot> getUserNotifications() {
    try {
      if (_auth.currentUser == null) {
        return const Stream.empty();
      }
      
      return _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('notifications')
          .orderBy('timestamp', descending: true)
          .snapshots();
    } catch (e) {
      if (kDebugMode) {
        print('Get user notifications error: $e');
      }
      return const Stream.empty();
    }
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      if (_auth.currentUser == null) return;

      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('notifications')
          .doc(notificationId)
          .update({
            'isRead': true,
          });

      // Update user's unread notification count
      await _firestore.collection('users').doc(_auth.currentUser!.uid).update({
        'unreadNotifications': FieldValue.increment(-1),
      });

    } catch (e) {
      if (kDebugMode) {
        print('Mark notification as read error: $e');
      }
    }
  }

  Future<void> markAllNotificationsAsRead() async {
    try {
      if (_auth.currentUser == null) return;

      final notificationsSnapshot = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      
      for (final doc in notificationsSnapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();

      // Reset unread notification count
      await _firestore.collection('users').doc(_auth.currentUser!.uid).update({
        'unreadNotifications': 0,
      });

    } catch (e) {
      if (kDebugMode) {
        print('Mark all notifications as read error: $e');
      }
    }
  }

  Stream<DocumentSnapshot> getUnreadNotificationCount() {
    try {
      if (_auth.currentUser == null) {
        return const Stream.empty();
      }
      
      return _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .snapshots();
    } catch (e) {
      if (kDebugMode) {
        print('Get unread notification count error: $e');
      }
      return const Stream.empty();
    }
  }

  // ========== FRIENDS SYSTEM ==========

  Future<void> sendFriendRequest(String targetUserId, String targetUserName, String targetUserAvatar) async {
    try {
      if (_auth.currentUser == null) return;

      final currentUserId = _auth.currentUser!.uid;
      
      final existingRequest = await _firestore
          .collection('friend_requests')
          .where('fromUserId', isEqualTo: currentUserId)
          .where('toUserId', isEqualTo: targetUserId)
          .where('status', isEqualTo: 'pending')
          .get();

      if (existingRequest.docs.isNotEmpty) return;

      final currentUserData = await getUserData();
      
      await _firestore.collection('friend_requests').add({
        'fromUserId': currentUserId,
        'toUserId': targetUserId,
        'fromUserName': currentUserData?['displayName'] ?? userName ?? 'User',
        'fromUserAvatar': currentUserData?['avatar'] ?? userAvatar ?? 'U',
        'toUserName': targetUserName,
        'toUserAvatar': targetUserAvatar,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await addUserActivity(
        'friend_request_sent',
        'Friend Request Sent',
        'You sent a friend request to $targetUserName',
        data: {'targetUserId': targetUserId, 'targetUserName': targetUserName},
      );

      // Send notification to the target user
      await sendNotification(
        receiverId: targetUserId,
        type: 'friend_request',
        title: 'Friend Request',
        message: '${currentUserData?['displayName'] ?? userName ?? 'User'} sent you a friend request',
        senderId: currentUserId,
        senderName: currentUserData?['displayName'] ?? userName ?? 'User',
        senderAvatar: currentUserData?['avatar'] ?? userAvatar ?? 'U',
        data: {'requestId': 'pending'},
      );

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Send friend request error: $e');
      }
    }
  }

  Future<void> acceptFriendRequest(String requestId) async {
    try {
      if (_auth.currentUser == null) return;

      final requestDoc = await _firestore.collection('friend_requests').doc(requestId).get();
      if (!requestDoc.exists) return;
      
      final requestData = requestDoc.data() as Map<String, dynamic>;
      final fromUserId = requestData['fromUserId'];
      final currentUserId = _auth.currentUser!.uid;

      await _firestore.collection('friend_requests').doc(requestId).update({
        'status': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
      });

      final batch = _firestore.batch();
      
      final currentUserData = await getUserData();
      
      batch.set(
        _firestore.collection('users').doc(currentUserId).collection('friends').doc(fromUserId),
        {
          'userId': fromUserId,
          'userName': requestData['fromUserName'],
          'userAvatar': requestData['fromUserAvatar'],
          'friendsSince': FieldValue.serverTimestamp(),
        }
      );
      
      batch.set(
        _firestore.collection('users').doc(fromUserId).collection('friends').doc(currentUserId),
        {
          'userId': currentUserId,
          'userName': currentUserData?['displayName'] ?? userName ?? 'User',
          'userAvatar': currentUserData?['avatar'] ?? userAvatar ?? 'U',
          'friendsSince': FieldValue.serverTimestamp(),
        }
      );

      batch.update(_firestore.collection('users').doc(currentUserId), {
        'friendsCount': FieldValue.increment(1),
      });
      
      batch.update(_firestore.collection('users').doc(fromUserId), {
        'friendsCount': FieldValue.increment(1),
      });

      await batch.commit();

      await addUserActivity(
        'friend_added',
        'New Friend!',
        'You became friends with ${requestData['fromUserName']}',
        data: {'friendUserId': fromUserId, 'friendName': requestData['fromUserName']},
      );

      // Send notification to the original requester
      await sendNotification(
        receiverId: fromUserId,
        type: 'friend_accepted',
        title: 'Friend Request Accepted',
        message: '${currentUserData?['displayName'] ?? userName ?? 'User'} accepted your friend request',
        senderId: currentUserId,
        senderName: currentUserData?['displayName'] ?? userName ?? 'User',
        senderAvatar: currentUserData?['avatar'] ?? userAvatar ?? 'U',
      );

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Accept friend request error: $e');
      }
    }
  }

  Future<void> rejectFriendRequest(String requestId) async {
    try {
      await _firestore.collection('friend_requests').doc(requestId).update({
        'status': 'rejected',
      });
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Reject friend request error: $e');
      }
    }
  }

  Future<void> removeFriend(String friendUserId) async {
    try {
      if (_auth.currentUser == null) return;

      final currentUserId = _auth.currentUser!.uid;

      final batch = _firestore.batch();

      batch.delete(
        _firestore.collection('users').doc(currentUserId).collection('friends').doc(friendUserId)
      );

      batch.delete(
        _firestore.collection('users').doc(friendUserId).collection('friends').doc(currentUserId)
      );

      batch.update(_firestore.collection('users').doc(currentUserId), {
        'friendsCount': FieldValue.increment(-1),
      });
      
      batch.update(_firestore.collection('users').doc(friendUserId), {
        'friendsCount': FieldValue.increment(-1),
      });

      await batch.commit();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Remove friend error: $e');
      }
    }
  }

  Stream<QuerySnapshot> getFriendRequests() {
    try {
      if (_auth.currentUser == null) {
        return const Stream.empty();
      }
      
      final currentUserId = _auth.currentUser!.uid;
      
      return _firestore
          .collection('friend_requests')
          .where('toUserId', isEqualTo: currentUserId)
          .where('status', isEqualTo: 'pending')
          .snapshots();
    } catch (e) {
      if (kDebugMode) {
        print('Get friend requests error: $e');
      }
      return const Stream.empty();
    }
  }

  Stream<QuerySnapshot> getFriends() {
    try {
      if (_auth.currentUser == null) {
        return const Stream.empty();
      }
      
      return _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('friends')
          .snapshots();
    } catch (e) {
      if (kDebugMode) {
        print('Get friends error: $e');
      }
      return const Stream.empty();
    }
  }

  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    try {
      if (query.isEmpty) return [];

      final snapshot = await _firestore
          .collection('users')
          .where('displayName', isGreaterThanOrEqualTo: query)
          .where('displayName', isLessThan: query + 'z')
          .limit(10)
          .get();

      final currentUserId = _auth.currentUser?.uid;
      return snapshot.docs
          .where((doc) => doc.id != currentUserId)
          .map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Search users error: $e');
      }
      return [];
    }
  }

  Future<Map<String, dynamic>?> getFriendStatus(String targetUserId) async {
    try {
      if (_auth.currentUser == null) return null;

      final currentUserId = _auth.currentUser!.uid;

      final friendDoc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('friends')
          .doc(targetUserId)
          .get();

      if (friendDoc.exists) {
        return {'status': 'friends'};
      }

      final sentRequest = await _firestore
          .collection('friend_requests')
          .where('fromUserId', isEqualTo: currentUserId)
          .where('toUserId', isEqualTo: targetUserId)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      if (sentRequest.docs.isNotEmpty) {
        return {'status': 'request_sent', 'requestId': sentRequest.docs.first.id};
      }

      final receivedRequest = await _firestore
          .collection('friend_requests')
          .where('fromUserId', isEqualTo: targetUserId)
          .where('toUserId', isEqualTo: currentUserId)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      if (receivedRequest.docs.isNotEmpty) {
        return {'status': 'request_received', 'requestId': receivedRequest.docs.first.id};
      }

      return {'status': 'not_friends'};
    } catch (e) {
      if (kDebugMode) {
        print('Get friend status error: $e');
      }
      return null;
    }
  }

  // ========== STORY METHODS ==========

  Future<String> uploadStoryImage(XFile imageFile) async {
    try {
      final String fileName = 'stories/${currentUser!.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
      final UploadTask uploadTask = storageRef.putFile(File(imageFile.path));
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload story image: $e');
    }
  }

  Future<void> createStory({
    String? imageUrl,
    String? textContent,
    String? backgroundColor,
    String? textColor,
  }) async {
    try {
      final storyId = _firestore.collection('stories').doc().id;
      final now = DateTime.now();
      final expiresAt = now.add(const Duration(hours: 24));

      final userData = await getUserData();

      final story = Story(
        id: storyId,
        userId: currentUser!.uid,
        userName: userData?['displayName'] ?? userName ?? 'User',
        userAvatar: userData?['avatar'] ?? userAvatar ?? 'U',
        imageUrl: imageUrl,
        textContent: textContent,
        backgroundColor: backgroundColor,
        textColor: textColor,
        createdAt: now,
        expiresAt: expiresAt,
      );

      await _firestore
          .collection('stories')
          .doc(storyId)
          .set(story.toMap());

      await addUserActivity(
        'story_created',
        'Story Posted',
        'You posted a new story',
        data: {'storyId': storyId},
      );

      notifyListeners();
    } catch (e) {
      throw Exception('Failed to create story: $e');
    }
  }

  Future<void> deleteStory(String storyId) async {
    try {
      await _firestore
          .collection('stories')
          .doc(storyId)
          .delete();
      
      await addUserActivity(
        'story_deleted',
        'Story Removed',
        'You removed a story',
        data: {'storyId': storyId},
      );

      notifyListeners();
    } catch (e) {
      throw Exception('Failed to delete story: $e');
    }
  }

  Stream<List<Story>> getStories() {
    try {
      return _firestore
          .collection('stories')
          .where('expiresAt', isGreaterThan: DateTime.now().millisecondsSinceEpoch)
          .orderBy('expiresAt', descending: false)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => Story.fromMap(doc.data() as Map<String, dynamic>))
            .toList();
      });
    } catch (e) {
      if (kDebugMode) {
        print('Get stories error: $e');
      }
      return Stream.value([]);
    }
  }

  Stream<List<Story>> getUserStories(String userId) {
    try {
      return _firestore
          .collection('stories')
          .where('userId', isEqualTo: userId)
          .where('expiresAt', isGreaterThan: DateTime.now().millisecondsSinceEpoch)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => Story.fromMap(doc.data() as Map<String, dynamic>))
            .toList();
      });
    } catch (e) {
      if (kDebugMode) {
        print('Get user stories error: $e');
      }
      return Stream.value([]);
    }
  }

  Future<bool> hasActiveStories(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('stories')
          .where('userId', isEqualTo: userId)
          .where('expiresAt', isGreaterThan: DateTime.now().millisecondsSinceEpoch)
          .limit(1)
          .get();
      
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      if (kDebugMode) {
        print('Check active stories error: $e');
      }
      return false;
    }
  }

  // ========== STORY LIKE METHODS ==========

  Future<void> likeStory(String storyId, String storyOwnerId) async {
    try {
      if (_auth.currentUser == null) return;

      final currentUserId = _auth.currentUser!.uid;
      
      // Don't allow liking your own story
      if (currentUserId == storyOwnerId) return;

      final storyLikeRef = _firestore
          .collection('stories')
          .doc(storyId)
          .collection('likes')
          .doc(currentUserId);

      final storyLikeDoc = await storyLikeRef.get();
      
      if (storyLikeDoc.exists) {
        // Unlike - remove the like
        await storyLikeRef.delete();
      } else {
        // Like - add the like
        await storyLikeRef.set({
          'userId': currentUserId,
          'timestamp': FieldValue.serverTimestamp(),
        });

        // Send notification to story owner
        final userData = await getUserData();
        await sendNotification(
          receiverId: storyOwnerId,
          type: 'story_like',
          title: 'Story Liked ❤️',
          message: '${userData?['displayName'] ?? userName ?? 'Someone'} liked your story',
          senderId: currentUserId,
          senderName: userData?['displayName'] ?? userName ?? 'User',
          senderAvatar: userData?['avatar'] ?? userAvatar ?? 'U',
          targetId: storyId,
          data: {'storyId': storyId, 'type': 'story_like'},
        );

        // Add user activity
        await addUserActivity(
          'story_liked',
          'Story Liked',
          'You liked ${userData?['displayName'] ?? 'someone'}\'s story',
          data: {'storyId': storyId, 'storyOwnerId': storyOwnerId},
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Like story error: $e');
      }
    }
  }

  Stream<bool> getStoryLikeStatus(String storyId) {
    try {
      if (_auth.currentUser == null) return Stream.value(false);
      
      return _firestore
          .collection('stories')
          .doc(storyId)
          .collection('likes')
          .doc(_auth.currentUser!.uid)
          .snapshots()
          .map((snapshot) => snapshot.exists);
    } catch (e) {
      if (kDebugMode) {
        print('Get story like status error: $e');
      }
      return Stream.value(false);
    }
  }
}