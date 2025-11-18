import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/story_model.dart';
import '../firebase_service.dart';

// Move UserStoryGroup class outside of StoryScreen class
class UserStoryGroup {
  final String userId;
  final String userName;
  final String userAvatar;
  final List<Story> stories;

  UserStoryGroup({
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.stories,
  });
}

class StoryScreen extends StatefulWidget {
  final List<UserStoryGroup> userStoryGroups;
  final int initialUserIndex;

  const StoryScreen({
    super.key,
    required this.userStoryGroups,
    this.initialUserIndex = 0,
  });

  @override
  State<StoryScreen> createState() => _StoryScreenState();
}

class _StoryScreenState extends State<StoryScreen> with SingleTickerProviderStateMixin {
  late PageController _userPageController;
  late PageController _storyPageController;
  late AnimationController _animationController;
  int _currentUserIndex = 0;
  int _currentStoryIndex = 0;
  bool _isPaused = false;
  bool _showLikeAnimation = false;

  @override
  void initState() {
    super.initState();
    _currentUserIndex = widget.initialUserIndex;
    _currentStoryIndex = 0;
    
    _userPageController = PageController(initialPage: _currentUserIndex);
    _storyPageController = PageController(initialPage: _currentStoryIndex);
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..addListener(() {
        if (!_isPaused && _animationController.isCompleted) {
          _nextStory();
        }
      });
    _startAnimation();
  }

  void _startAnimation() {
    _animationController.forward(from: 0.0);
  }

  void _nextStory() {
    final currentUserStories = widget.userStoryGroups[_currentUserIndex].stories;
    
    if (_currentStoryIndex < currentUserStories.length - 1) {
      // Next story in same user
      _currentStoryIndex++;
      _storyPageController.animateToPage(
        _currentStoryIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _animationController.reset();
      _startAnimation();
    } else if (_currentUserIndex < widget.userStoryGroups.length - 1) {
      // Next user
      _currentUserIndex++;
      _currentStoryIndex = 0;
      _userPageController.animateToPage(
        _currentUserIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _storyPageController.jumpToPage(0);
      _animationController.reset();
      _startAnimation();
    } else {
      // Last story of last user
      Navigator.of(context).pop();
    }
  }

  void _previousStory() {
    if (_currentStoryIndex > 0) {
      // Previous story in same user
      _currentStoryIndex--;
      _storyPageController.animateToPage(
        _currentStoryIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _animationController.reset();
      _startAnimation();
    } else if (_currentUserIndex > 0) {
      // Previous user
      _currentUserIndex--;
      final previousUserStories = widget.userStoryGroups[_currentUserIndex].stories;
      _currentStoryIndex = previousUserStories.length - 1;
      _userPageController.animateToPage(
        _currentUserIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _storyPageController.jumpToPage(_currentStoryIndex);
      _animationController.reset();
      _startAnimation();
    } else {
      // First story of first user
      Navigator.of(context).pop();
    }
  }

  void _onUserPageChanged(int index) {
    setState(() {
      _currentUserIndex = index;
      _currentStoryIndex = 0;
    });
    _storyPageController.jumpToPage(0);
    _animationController.reset();
    _startAnimation();
  }

  void _onStoryPageChanged(int index) {
    setState(() {
      _currentStoryIndex = index;
    });
    _animationController.reset();
    _startAnimation();
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
    });
    if (_isPaused) {
      _animationController.stop();
    } else {
      _animationController.forward();
    }
  }

  void _likeStory() {
    final currentUser = widget.userStoryGroups[_currentUserIndex];
    final currentStory = currentUser.stories[_currentStoryIndex];
    final firebaseService = Provider.of<FirebaseService>(context, listen: false);
    
    // Only allow liking other users' stories
    if (currentUser.userId != firebaseService.currentUser?.uid) {
      _showLikeAnimation = true;
      setState(() {});
      
      // Hide like animation after 1 second
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          setState(() {
            _showLikeAnimation = false;
          });
        }
      });

      // Send like notification
      firebaseService.likeStory(currentStory.id, currentUser.userId);
    }
  }

  @override
  void dispose() {
    _userPageController.dispose();
    _storyPageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = widget.userStoryGroups[_currentUserIndex];
    final currentStory = currentUser.stories[_currentStoryIndex];
    final firebaseService = Provider.of<FirebaseService>(context);
    final isCurrentUserStory = currentUser.userId == firebaseService.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Main content with PageViews
          PageView.builder(
            controller: _userPageController,
            itemCount: widget.userStoryGroups.length,
            onPageChanged: _onUserPageChanged,
            physics: const NeverScrollableScrollPhysics(), // Disable horizontal swipe for users
            itemBuilder: (context, userIndex) {
              final userGroup = widget.userStoryGroups[userIndex];
              return PageView.builder(
                controller: userIndex == _currentUserIndex ? _storyPageController : null,
                itemCount: userGroup.stories.length,
                onPageChanged: userIndex == _currentUserIndex ? _onStoryPageChanged : null,
                physics: userIndex == _currentUserIndex ? const PageScrollPhysics() : const NeverScrollableScrollPhysics(),
                itemBuilder: (context, storyIndex) {
                  final story = userGroup.stories[storyIndex];
                  return _StoryContent(story: story);
                },
              );
            },
          ),

          // Progress Indicators (for current user's stories)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            right: 8,
            child: Row(
              children: List.generate(currentUser.stories.length, (index) {
                return Expanded(
                  child: Container(
                    height: 3,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Stack(
                      children: [
                        if (index == _currentStoryIndex)
                          AnimatedBuilder(
                            animation: _animationController,
                            builder: (context, child) {
                              return FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: _animationController.value,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              );
                            },
                          ),
                        if (index < _currentStoryIndex)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),

          // Header
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 8,
            right: 8,
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF7C3AED),
                  child: Text(
                    currentUser.userAvatar,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentUser.userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${currentStory.timeRemaining.inHours}h ${currentStory.timeRemaining.inMinutes.remainder(60)}m remaining',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Like Button (only for other users' stories) - Bottom Right Corner
          if (!isCurrentUserStory)
            Positioned(
              bottom: 20,
              right: 20,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: _likeStory,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ),

          // Like Animation
          if (_showLikeAnimation)
            Positioned.fill(
              child: Center(
                child: Icon(
                  Icons.favorite_rounded,
                  color: Colors.red,
                  size: 80,
                ),
              ),
            ),

          // Navigation Arrows (Like Instagram - Middle Left/Right)
          // Show left arrow when:
          // - Not on first story of first user
          // Show right arrow when:
          // - Not on last story of last user
          if (_currentUserIndex > 0 || _currentStoryIndex > 0) // Show left arrow condition
            Positioned(
              left: 10,
              top: MediaQuery.of(context).size.height / 2 - 30,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: _previousStory,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),

          if (_currentUserIndex < widget.userStoryGroups.length - 1 || 
              _currentStoryIndex < currentUser.stories.length - 1) // Show right arrow condition
            Positioned(
              right: 10,
              top: MediaQuery.of(context).size.height / 2 - 30,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: _nextStory,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),

          // Tap Areas for Navigation (Fixed to not interfere with like button)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: MediaQuery.of(context).size.width * 0.25, // Reduced width to avoid like button area
            child: GestureDetector(
              onTap: _previousStory,
              behavior: HitTestBehavior.opaque,
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: MediaQuery.of(context).size.width * 0.25, // Reduced width to avoid like button area
            child: GestureDetector(
              onTap: _nextStory,
              behavior: HitTestBehavior.opaque,
            ),
          ),

          // Middle area for like (double tap)
          Positioned(
            left: MediaQuery.of(context).size.width * 0.25,
            right: MediaQuery.of(context).size.width * 0.25,
            top: 0,
            bottom: 0,
            child: GestureDetector(
              onDoubleTap: _likeStory,
              behavior: HitTestBehavior.opaque,
            ),
          ),

          // Pause Indicator
          if (_isPaused)
            const Center(
              child: Icon(
                Icons.pause_rounded,
                color: Colors.white,
                size: 64,
              ),
            ),
        ],
      ),
    );
  }
}

class _StoryContent extends StatelessWidget {
  final Story story;

  const _StoryContent({required this.story});

  @override
  Widget build(BuildContext context) {
    if (story.hasImage) {
      return Image.network(
        story.imageUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(Color(0xFF7C3AED)),
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
                  Icon(Icons.broken_image_rounded, color: Color(0xFF94A3B8), size: 64),
                  SizedBox(height: 16),
                  Text(
                    'Failed to load story',
                    style: TextStyle(color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } else if (story.hasText) {
      final backgroundColor = story.backgroundColor != null 
          ? Color(int.parse(story.backgroundColor!, radix: 16))
          : const Color(0xFF7C3AED);
      final textColor = story.textColor != null
          ? Color(int.parse(story.textColor!, radix: 16))
          : Colors.white;

      return Container(
        color: backgroundColor,
        width: double.infinity,
        height: double.infinity,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              story.textContent!,
              style: TextStyle(
                color: textColor,
                fontSize: 32,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Container(
      color: const Color(0xFF1E293B),
      child: const Center(
        child: Text(
          'No content',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}