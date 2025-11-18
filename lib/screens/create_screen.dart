import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../firebase_service.dart';

class CreateScreen extends StatefulWidget {
  const CreateScreen({super.key});

  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  final TextEditingController _postController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController(); // NEW: For image URL
  
  final List<CreateOption> _createOptions = [
    CreateOption(
      title: 'Social Post',
      description: 'Share your thoughts',
      icon: Icons.chat_rounded,
      color: Color(0xFF7C3AED),
      type: 'social',
    ),
    CreateOption(
      title: 'Study Tip',
      description: 'Share knowledge',
      icon: Icons.lightbulb_rounded,
      color: Colors.blue,
      type: 'educational',
    ),
    CreateOption(
      title: 'Create Quiz',
      description: 'Test your friends',
      icon: Icons.quiz_rounded,
      color: Colors.green,
      type: 'quiz',
    ),
    CreateOption(
      title: 'Study Group',
      description: 'Invite friends',
      icon: Icons.groups_rounded,
      color: Colors.orange,
      type: 'studyGroup',
    ),
    CreateOption(
      title: 'Resource',
      description: 'Share materials',
      icon: Icons.attach_file_rounded,
      color: Colors.purple,
      type: 'resource',
    ),
    CreateOption(
      title: 'Achievement',
      description: 'Celebrate success',
      icon: Icons.emoji_events_rounded,
      color: Colors.amber,
      type: 'achievement',
    ),
  ];

  String _selectedSubject = 'General';
  String _selectedPostType = 'social';
  final List<String> _subjects = [
    'General',
    'Mathematics',
    'Science',
    'Physics',
    'Chemistry',
    'Biology',
    'History',
    'Languages',
    'Programming',
    'Arts',
  ];

  // Quiz-specific fields
  final List<TextEditingController> _quizOptionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];
  final int _maxQuizOptions = 6;

  // Image URL field
  String? _imageUrl; // NEW: Store image URL
  bool _showImageUrlField = false; // NEW: Control visibility

  bool _isLoading = false;

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
    _postController.dispose();
    _imageUrlController.dispose(); // NEW: Dispose image URL controller
    for (var controller in _quizOptionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _createPost() async {
    if (_selectedPostType == 'quiz') {
      _createQuizPost();
    } else {
      _createRegularPost();
    }
  }

  void _createRegularPost() async {
    // NEW: Better validation - allow posts with just images
    if (_postController.text.trim().isEmpty && _imageUrl == null) {
      _showErrorDialog('Please write something or add an image to share!');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await Provider.of<FirebaseService>(context, listen: false).createPost(
        content: _postController.text.trim(),
        type: _selectedPostType,
        imageUrl: _imageUrl, // NEW: Pass image URL
        subject: _selectedSubject == 'General' ? null : _selectedSubject,
        tags: _getTagsFromContent(_postController.text),
      );

      setState(() {
        _isLoading = false;
      });

      if (success) {
        _showSuccessDialog();
      } else {
        _showErrorDialog('Failed to create post. Please try again.');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('An error occurred: $e');
    }
  }

  void _createQuizPost() async {
    // Validate quiz question
    if (_postController.text.trim().isEmpty) {
      _showErrorDialog('Please enter a quiz question!');
      return;
    }

    // Validate quiz options
    final List<String> options = _quizOptionControllers
        .where((controller) => controller.text.trim().isNotEmpty)
        .map((controller) => controller.text.trim())
        .toList();

    if (options.length < 2) {
      _showErrorDialog('Please add at least 2 options for your quiz!');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await Provider.of<FirebaseService>(context, listen: false).createQuizPost(
        question: _postController.text.trim(),
        options: options,
        subject: _selectedSubject == 'General' ? 'General' : _selectedSubject,
        tags: _getTagsFromContent(_postController.text),
      );

      setState(() {
        _isLoading = false;
      });

      if (success) {
        _showSuccessDialog();
      } else {
        _showErrorDialog('Failed to create quiz. Please try again.');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('An error occurred: $e');
    }
  }

  // NEW: Image URL methods
  void _addImageUrl() {
    if (_imageUrlController.text.trim().isNotEmpty) {
      setState(() {
        _imageUrl = _imageUrlController.text.trim();
        _showImageUrlField = false;
        _imageUrlController.clear();
      });
    }
  }

  void _removeImageUrl() {
    setState(() {
      _imageUrl = null;
    });
  }

  void _toggleImageUrlField() {
    setState(() {
      _showImageUrlField = !_showImageUrlField;
      if (!_showImageUrlField) {
        _imageUrlController.clear();
      }
    });
  }

  void _addQuizOption() {
    if (_quizOptionControllers.length < _maxQuizOptions) {
      setState(() {
        _quizOptionControllers.add(TextEditingController());
      });
    }
  }

  void _removeQuizOption(int index) {
    if (_quizOptionControllers.length > 2) {
      setState(() {
        _quizOptionControllers.removeAt(index);
      });
    }
  }

  List<String> _getTagsFromContent(String content) {
    final RegExp regex = RegExp(r'\#\w+');
    final matches = regex.allMatches(content);
    return matches.map((match) => match.group(0)!.substring(1)).toList();
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Oops!',
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

  void _showSuccessDialog() {
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
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                '${_getPostTypeName(_selectedPostType)} Shared! 🎉',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your content has been shared with the community',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context); // Go back to home
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    textStyle: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  child: const Text('Awesome!'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getPostTypeName(String type) {
    switch (type) {
      case 'educational':
        return 'Study Tip';
      case 'quiz':
        return 'Quiz';
      case 'studyGroup':
        return 'Study Group';
      case 'resource':
        return 'Resource';
      case 'achievement':
        return 'Achievement';
      default:
        return 'Post';
    }
  }

  @override
  Widget build(BuildContext context) {
    final firebaseService = Provider.of<FirebaseService>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _selectedPostType == 'quiz' ? 'Create Quiz' : 'Create Post',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          _isLoading
              ? Container(
                  padding: const EdgeInsets.all(8),
                  child: const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(Color(0xFF7C3AED)),
                    strokeWidth: 2,
                  ),
                )
              : TextButton(
                  onPressed: _createPost,
                  child: Text(
                    _selectedPostType == 'quiz' ? 'Create Quiz' : 'Post',
                    style: const TextStyle(
                      color: Color(0xFF7C3AED),
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // User Info
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: const Color(0xFF7C3AED),
                          child: Text(
                            firebaseService.userAvatar ?? 'U',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              firebaseService.userName ?? 'User',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Public',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        // NEW: Add Image URL Button
                        IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              _imageUrl != null ? Icons.photo_library : Icons.photo_library_outlined,
                              size: 20,
                              color: _imageUrl != null ? const Color(0xFF7C3AED) : Colors.white70,
                            ),
                          ),
                          onPressed: _toggleImageUrlField,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // NEW: Image URL Input Field (Conditional)
                    if (_showImageUrlField) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _imageUrlController,
                                style: const TextStyle(color: Colors.white),
                                decoration: const InputDecoration(
                                  hintText: 'Paste image URL...',
                                  hintStyle: TextStyle(color: Color(0xFF94A3B8)),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.all(8),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.check_rounded, color: Color(0xFF10B981)),
                              onPressed: _addImageUrl,
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, color: Color(0xFFEF4444)),
                              onPressed: _toggleImageUrlField,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // NEW: Image Preview
                    if (_imageUrl != null) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Stack(
                          children: [
                            Container(
                              width: double.infinity,
                              height: 150,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(12),
                                image: DecorationImage(
                                  image: NetworkImage(_imageUrl!),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: _removeImageUrl,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close_rounded, size: 16, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Subject Selection
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButton<String>(
                        value: _selectedSubject,
                        isExpanded: true,
                        dropdownColor: const Color(0xFF1E293B),
                        style: const TextStyle(color: Colors.white),
                        underline: const SizedBox(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedSubject = newValue!;
                          });
                        },
                        items: _subjects.map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Post Type Selection
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButton<String>(
                        value: _selectedPostType,
                        isExpanded: true,
                        dropdownColor: const Color(0xFF1E293B),
                        style: const TextStyle(color: Colors.white),
                        underline: const SizedBox(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedPostType = newValue!;
                          });
                        },
                        items: _createOptions.map<DropdownMenuItem<String>>((CreateOption option) {
                          return DropdownMenuItem<String>(
                            value: option.type,
                            child: Text(_getPostTypeName(option.type)),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Content Input
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            // Question/Content Input
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: TextField(
                                controller: _postController,
                                maxLines: _selectedPostType == 'quiz' ? 3 : 5,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                ),
                                decoration: InputDecoration(
                                  hintText: _selectedPostType == 'quiz' 
                                      ? 'Enter your quiz question...' 
                                      : 'What would you like to share? Share thoughts, study tips, questions...',
                                  hintStyle: const TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 18,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.all(16),
                                ),
                              ),
                            ),

                            // Quiz Options (only show for quiz type)
                            if (_selectedPostType == 'quiz') ...[
                              const SizedBox(height: 20),
                              const Text(
                                'Quiz Options:',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ...List.generate(_quizOptionControllers.length, (index) {
                                return _buildQuizOptionField(index);
                              }),
                              const SizedBox(height: 12),
                              if (_quizOptionControllers.length < _maxQuizOptions)
                                OutlinedButton(
                                  onPressed: _addQuizOption,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF7C3AED),
                                    side: const BorderSide(color: Color(0xFF7C3AED)),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text('Add Option'),
                                ),
                              const SizedBox(height: 20),
                            ],

                            // Create Options Grid
                            const Text(
                              'Or choose post type:',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.9,
                              ),
                              itemCount: _createOptions.length,
                              itemBuilder: (context, index) {
                                final option = _createOptions[index];
                                final isSelected = _selectedPostType == option.type;
                                return _CreateOptionCard(
                                  option: option,
                                  isSelected: isSelected,
                                  onTap: () => setState(() {
                                    _selectedPostType = option.type;
                                  }),
                                );
                              },
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuizOptionField(int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _quizOptionControllers[index],
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Option ${index + 1}',
                  hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                  prefixIcon: Container(
                    width: 40,
                    alignment: Alignment.center,
                    child: Text(
                      '${index + 1}.',
                      style: const TextStyle(
                        color: Color(0xFF7C3AED),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (_quizOptionControllers.length > 2)
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.remove_rounded, size: 16, color: Color(0xFFEF4444)),
              ),
              onPressed: () => _removeQuizOption(index),
            ),
        ],
      ),
    );
  }
}

class _CreateOptionCard extends StatelessWidget {
  final CreateOption option;
  final bool isSelected;
  final VoidCallback onTap;

  const _CreateOptionCard({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? option.color.withOpacity(0.2) : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? option.color : option.color.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(15),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(option.icon, size: 24, color: option.color),
                  const SizedBox(height: 8),
                  Text(
                    option.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: option.color,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    option.description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CreateOption {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String type;

  const CreateOption({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.type,
  });
}