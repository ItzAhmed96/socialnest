import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../firebase_service.dart';
import '../models/story_model.dart';
import 'create_story_screen.dart';
import 'story_screen.dart';

class StoriesSection extends StatelessWidget {
  const StoriesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final firebaseService = Provider.of<FirebaseService>(context);
    
    return StreamBuilder<List<Story>>(
      stream: firebaseService.getStories(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 120,
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Color(0xFF7C3AED)),
              ),
            ),
          );
        }

        final stories = snapshot.data ?? [];
        
        // Group stories by user and ensure each user has at least one active story
        final Map<String, UserStoryGroup> userStoryGroups = {};
        for (final story in stories) {
          if (!story.isExpired) { // Only include non-expired stories
            if (!userStoryGroups.containsKey(story.userId)) {
              userStoryGroups[story.userId] = UserStoryGroup(
                userId: story.userId,
                userName: story.userName,
                userAvatar: story.userAvatar,
                stories: [],
              );
            }
            userStoryGroups[story.userId]!.stories.add(story);
          }
        }

        final currentUserId = firebaseService.currentUser?.uid;

        // Convert to list and sort: current user first, then others by most recent story
        List<UserStoryGroup> userStoryGroupsList = userStoryGroups.values.toList();
        
        // Sort by most recent story timestamp
        userStoryGroupsList.sort((a, b) {
          final aLatest = a.stories.last.createdAt;
          final bLatest = b.stories.last.createdAt;
          return bLatest.compareTo(aLatest);
        });

        // Move current user to front if they have stories
        if (currentUserId != null && userStoryGroups.containsKey(currentUserId)) {
          final currentUserGroup = userStoryGroups[currentUserId]!;
          userStoryGroupsList.removeWhere((group) => group.userId == currentUserId);
          userStoryGroupsList.insert(0, currentUserGroup);
        }

        // If no stories, show only the add story button
        if (userStoryGroupsList.isEmpty) {
          return Container(
            height: 120,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildAddStoryItem(context),
              ],
            ),
          );
        }

        return Container(
          height: 120,
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              // Add Story Button (Current User) - ALWAYS SHOW THIS
              _buildAddStoryItem(context),
              
              // Show all user stories including current user
              ...userStoryGroupsList.map((userGroup) {
                final isCurrentUser = userGroup.userId == currentUserId;
                return _buildStoryItem(
                  isCurrentUser,
                  userGroup,
                  context,
                  userStoryGroupsList.indexOf(userGroup),
                  userStoryGroupsList, // Pass the entire list for navigation
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAddStoryItem(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateStoryScreen()),
                );
              },
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF42A5F5), Color(0xFF7E57C2)],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    const Center(
                      child: Text(
                        '+',
                        style: TextStyle(
                          fontSize: 24,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: Color(0xFF1877F2),
                          shape: BoxShape.circle,
                          border: Border.fromBorderSide(
                            BorderSide(color: Colors.white, width: 2),
                          ),
                        ),
                        child: const Icon(
                          Icons.add,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add Story',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStoryItem(
    bool isYourStory, 
    UserStoryGroup userGroup, 
    BuildContext context, 
    int userIndex,
    List<UserStoryGroup> allUserGroups,
  ) {
    final firstStory = userGroup.stories.first;
    final hasImage = firstStory.hasImage;
    final hasText = firstStory.hasText;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => StoryScreen(
                userStoryGroups: allUserGroups,
                initialUserIndex: userIndex,
              ),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFF06B6D4)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: Colors.transparent,
                    width: 3,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(3.0),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF1E293B),
                      shape: BoxShape.circle,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(3.0),
                      child: hasImage
                          ? ClipOval(
                              child: Image.network(
                                firstStory.imageUrl!,
                                fit: BoxFit.cover,
                                width: 64,
                                height: 64,
                              ),
                            )
                          : hasText
                              ? Container(
                                  decoration: BoxDecoration(
                                    color: firstStory.backgroundColor != null
                                        ? Color(int.parse(firstStory.backgroundColor!, radix: 16))
                                        : const Color(0xFF7C3AED),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      firstStory.textContent!.length > 5 
                                          ? '${firstStory.textContent!.substring(0, 5)}...'
                                          : firstStory.textContent!,
                                      style: TextStyle(
                                        color: firstStory.textColor != null
                                            ? Color(int.parse(firstStory.textColor!, radix: 16))
                                            : Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                )
                              : CircleAvatar(
                                  backgroundColor: const Color(0xFF7C3AED),
                                  child: Text(
                                    userGroup.userAvatar,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 70,
                child: Text(
                  isYourStory ? 'Your Story' : (userGroup.userName.length > 8 ? '${userGroup.userName.substring(0, 8)}...' : userGroup.userName),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}