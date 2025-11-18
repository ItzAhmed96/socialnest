import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../firebase_service.dart';

class CreateStoryScreen extends StatefulWidget {
  const CreateStoryScreen({super.key});

  @override
  State<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends State<CreateStoryScreen> {
  final TextEditingController _textController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  String? _selectedBackgroundColor;
  String? _selectedTextColor;
  bool _isUploading = false;

  final List<Map<String, String>> _backgroundColors = [
    {'name': 'Purple', 'value': 'FF7C3AED'},
    {'name': 'Blue', 'value': 'FF06B6D4'},
    {'name': 'Green', 'value': 'FF10B981'},
    {'name': 'Red', 'value': 'FFEF4444'},
    {'name': 'Orange', 'value': 'FFF59E0B'},
    {'name': 'Dark', 'value': 'FF1E293B'},
  ];

  final List<Map<String, String>> _textColors = [
    {'name': 'White', 'value': 'FFFFFFFF'},
    {'name': 'Black', 'value': 'FF000000'},
    {'name': 'Light', 'value': 'FFF8FAFC'},
  ];

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _selectedImage = image;
          _textController.clear();
        });
      }
    } catch (e) {
      _showError('Failed to pick image: $e');
    }
  }

  Future<void> _createStory() async {
    if (_selectedImage == null && _textController.text.isEmpty) {
      _showError('Please add an image or text to your story');
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final firebaseService = Provider.of<FirebaseService>(context, listen: false);
      
      String? imageUrl;
      if (_selectedImage != null) {
        imageUrl = await firebaseService.uploadStoryImage(_selectedImage!);
      }

      await firebaseService.createStory(
        imageUrl: imageUrl,
        textContent: _textController.text.isEmpty ? null : _textController.text,
        backgroundColor: _selectedBackgroundColor,
        textColor: _selectedTextColor,
      );

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Story posted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      _showError('Failed to create story: $e');
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text(
          'Create Story',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (!_isUploading)
            TextButton(
              onPressed: _createStory,
              child: const Text(
                'Post',
                style: TextStyle(
                  color: Color(0xFF7C3AED),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: _isUploading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(Color(0xFF7C3AED)),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Posting your story...',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Preview/Picker
                  Container(
                    width: double.infinity,
                    height: 300,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    child: _selectedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.file(
                              File(_selectedImage!.path),
                              fit: BoxFit.cover,
                            ),
                          )
                        : _textController.text.isNotEmpty
                            ? Container(
                                decoration: BoxDecoration(
                                  color: _selectedBackgroundColor != null
                                      ? Color(int.parse(_selectedBackgroundColor!, radix: 16))
                                      : const Color(0xFF7C3AED),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(24.0),
                                    child: Text(
                                      _textController.text,
                                      style: TextStyle(
                                        color: _selectedTextColor != null
                                            ? Color(int.parse(_selectedTextColor!, radix: 16))
                                            : Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w600,
                                        height: 1.2,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.photo_library_rounded,
                                    size: 64,
                                    color: Colors.white.withOpacity(0.3),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Add an image or text',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.5),
                                    ),
                                  ),
                                ],
                              ),
                  ),

                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.photo_library_rounded),
                          label: const Text('Add Photo'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E293B),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: _pickImage,
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (_selectedImage != null)
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.delete_rounded),
                            label: const Text('Remove'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.withOpacity(0.2),
                              foregroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            onPressed: () {
                              setState(() {
                                _selectedImage = null;
                              });
                            },
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Text Input
                  TextField(
                    controller: _textController,
                    maxLines: 4,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Type your story text...',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF7C3AED)),
                      ),
                      filled: true,
                      fillColor: const Color(0xFF1E293B),
                    ),
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),

                  if (_textController.text.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Background Color',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 60,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: _backgroundColors.map((color) {
                          final isSelected = _selectedBackgroundColor == color['value'];
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedBackgroundColor = color['value'];
                              });
                            },
                            child: Container(
                              width: 60,
                              height: 60,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                color: Color(int.parse(color['value']!, radix: 16)),
                                borderRadius: BorderRadius.circular(12),
                                border: isSelected
                                    ? Border.all(color: Colors.white, width: 3)
                                    : null,
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check_rounded, color: Colors.white)
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Text Color',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 60,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: _textColors.map((color) {
                          final isSelected = _selectedTextColor == color['value'];
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedTextColor = color['value'];
                              });
                            },
                            child: Container(
                              width: 60,
                              height: 60,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                color: Color(int.parse(color['value']!, radix: 16)),
                                borderRadius: BorderRadius.circular(12),
                                border: isSelected
                                    ? Border.all(color: Colors.white, width: 3)
                                    : null,
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check_rounded, color: Colors.white)
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}