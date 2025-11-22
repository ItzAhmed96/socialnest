import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase_service.dart';
import '../models/homework_model.dart';

class HomeworkTrackerScreen extends StatefulWidget {
  const HomeworkTrackerScreen({super.key});

  @override
  State<HomeworkTrackerScreen> createState() => _HomeworkTrackerScreenState();
}

class _HomeworkTrackerScreenState extends State<HomeworkTrackerScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  
  DateTime _dueDate = DateTime.now().add(const Duration(days: 1));
  int _priority = 2;

  void _showAddHomeworkDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            backgroundColor: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Add Homework',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Title
                    TextField(
                      controller: _titleController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Title',
                        labelStyle: const TextStyle(color: Colors.white70),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF7C3AED)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Subject
                    TextField(
                      controller: _subjectController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Subject',
                        labelStyle: const TextStyle(color: Colors.white70),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF7C3AED)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Due Date
                    Row(
                      children: [
                        const Text(
                          'Due Date: ',
                          style: TextStyle(color: Colors.white70),
                        ),
                        TextButton(
                          onPressed: () async {
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate: _dueDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (pickedDate != null) {
                              setState(() {
                                _dueDate = pickedDate;
                              });
                            }
                          },
                          child: Text(
                            '${_dueDate.day}/${_dueDate.month}/${_dueDate.year}',
                            style: const TextStyle(color: Color(0xFF7C3AED)),
                          ),
                        ),
                      ],
                    ),
                    
                    // Priority
                    const Text(
                      'Priority:',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildPriorityChip('High', 1, setState),
                        const SizedBox(width: 8),
                        _buildPriorityChip('Medium', 2, setState),
                        const SizedBox(width: 8),
                        _buildPriorityChip('Low', 3, setState),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _clearForm();
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Color(0xFF94A3B8)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              _addHomework();
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7C3AED),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('Add'),
                          ),
                        ),
                      ],
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

  Widget _buildPriorityChip(String label, int priority, StateSetter setState) {
    final isSelected = _priority == priority;
    Color color;
    switch (priority) {
      case 1: color = Colors.red; break;
      case 2: color = Colors.orange; break;
      case 3: color = Colors.green; break;
      default: color = Colors.orange;
    }
    
    return ChoiceChip(
      label: Text(label, style: TextStyle(color: isSelected ? Colors.white : color)),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _priority = priority;
        });
      },
      backgroundColor: const Color(0xFF1E293B),
      selectedColor: color,
      side: BorderSide(color: color),
    );
  }

  void _addHomework() async {
    if (_titleController.text.isEmpty) return;
    
    final homework = Homework(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text,
      description: _descriptionController.text,
      subject: _subjectController.text.isEmpty ? 'General' : _subjectController.text,
      dueDate: _dueDate,
      priority: _priority,
    );
    
    final success = await Provider.of<FirebaseService>(context, listen: false)
        .addHomework(homework);
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added: ${homework.title}'),
          backgroundColor: Colors.green.shade600,
        ),
      );
      _clearForm();
    }
  }

  void _clearForm() {
    _titleController.clear();
    _descriptionController.clear();
    _subjectController.clear();
    _dueDate = DateTime.now().add(const Duration(days: 1));
    _priority = 2;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Homework Tracker', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            onPressed: _showAddHomeworkDialog,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: Provider.of<FirebaseService>(context).getHomework(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_rounded, size: 80, color: Colors.white.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  const Text(
                    'No homework yet',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Add your first assignment to get started!',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _showAddHomeworkDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Add Homework'),
                  ),
                ],
              ),
            );
          }

          final homeworkList = snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Homework.fromMap(data);
          }).toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: homeworkList.length,
            itemBuilder: (context, index) {
              final homework = homeworkList[index];
              return _buildHomeworkItem(homework, docId: snapshot.data!.docs[index].id);
            },
          );
        },
      ),
    );
  }

  Widget _buildHomeworkItem(Homework homework, {required String docId}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: homework.isCompleted ? Colors.green.withOpacity(0.3) : Colors.white.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          // Checkbox
          Checkbox(
            value: homework.isCompleted,
            onChanged: (value) async {
              await Provider.of<FirebaseService>(context, listen: false)
                  .updateHomeworkStatus(docId, value ?? false);
            },
            fillColor: MaterialStateProperty.resolveWith<Color>((states) {
              if (states.contains(MaterialState.selected)) {
                return Colors.green;
              }
              return const Color(0xFF334155);
            }),
          ),
          
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  homework.title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    decoration: homework.isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                  ),
                ),
                if (homework.subject.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    homework.subject,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: homework.priorityColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        homework.priorityText,
                        style: TextStyle(
                          color: homework.priorityColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      homework.timeLeft,
                      style: TextStyle(
                        color: homework.timeLeft == 'Overdue' ? Colors.red : Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Delete button
          IconButton(
            onPressed: () async {
              await Provider.of<FirebaseService>(context, listen: false)
                  .deleteHomework(docId);
            },
            icon: Icon(Icons.delete_outline_rounded, color: Colors.red.shade400),
          ),
        ],
      ),
    );
  }
}