import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase_service.dart';
import '../models/homework_model.dart';

class StudyCalendarScreen extends StatefulWidget {
  const StudyCalendarScreen({super.key});

  @override
  State<StudyCalendarScreen> createState() => _StudyCalendarScreenState();
}

class _StudyCalendarScreenState extends State<StudyCalendarScreen> {
  DateTime _selectedDate = DateTime.now();
  List<Homework> _upcomingHomework = [];

  @override
  void initState() {
    super.initState();
    _loadUpcomingHomework();
  }

  void _loadUpcomingHomework() {
    final homeworkStream = Provider.of<FirebaseService>(context, listen: false).getHomework();
    homeworkStream.listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final allHomework = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return Homework.fromMap(data);
        }).toList();
        
        // Sort by due date and get upcoming assignments
        allHomework.sort((a, b) => a.dueDate.compareTo(b.dueDate));
        setState(() {
          _upcomingHomework = allHomework;
        });
      }
    });
  }

  void _previousMonth() {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1);
    });
  }

  List<Homework> _getHomeworkForMonth() {
    return _upcomingHomework.where((hw) {
      return hw.dueDate.year == _selectedDate.year && 
             hw.dueDate.month == _selectedDate.month;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final monthHomework = _getHomeworkForMonth();
    final monthName = _getMonthName(_selectedDate.month);
    final year = _selectedDate.year;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Study Calendar', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Month Navigation
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: _previousMonth,
                  icon: const Icon(Icons.chevron_left_rounded, color: Colors.white),
                ),
                Text(
                  '$monthName $year',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  onPressed: _nextMonth,
                  icon: const Icon(Icons.chevron_right_rounded, color: Colors.white),
                ),
              ],
            ),
          ),

          // Month Summary
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF7C3AED).withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMonthStat('Assignments', monthHomework.length),
                _buildMonthStat('Due Soon', _getDueSoonCount(monthHomework)),
                _buildMonthStat('Completed', _getCompletedCount(monthHomework)),
              ],
            ),
          ),

          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.event_note_rounded, color: Colors.white70, size: 18),
                SizedBox(width: 8),
                Text(
                  'Upcoming Assignments',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Homework List
          Expanded(
            child: monthHomework.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: monthHomework.length,
                    itemBuilder: (context, index) {
                      return _buildHomeworkItem(monthHomework[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthStat(String label, int count) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  int _getDueSoonCount(List<Homework> homework) {
    final now = DateTime.now();
    final nextWeek = now.add(const Duration(days: 7));
    return homework.where((hw) {
      return !hw.isCompleted && hw.dueDate.isAfter(now) && hw.dueDate.isBefore(nextWeek);
    }).length;
  }

  int _getCompletedCount(List<Homework> homework) {
    return homework.where((hw) => hw.isCompleted).length;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_available_rounded, size: 80, color: Colors.white.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text(
            'No assignments this month',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add homework to see it here',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeworkItem(Homework homework) {
    final isDueSoon = _isDueSoon(homework.dueDate);
    final isOverdue = homework.dueDate.isBefore(DateTime.now()) && !homework.isCompleted;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: homework.isCompleted 
            ? Colors.green.withOpacity(0.3) 
            : isOverdue
              ? Colors.red.withOpacity(0.3)
              : isDueSoon
                ? Colors.orange.withOpacity(0.3)
                : Colors.white.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          // Date indicator
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: homework.isCompleted 
                ? Colors.green.withOpacity(0.2)
                : const Color(0xFF7C3AED).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  homework.dueDate.day.toString(),
                  style: TextStyle(
                    color: homework.isCompleted ? Colors.green : Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  _getMonthAbbr(homework.dueDate.month),
                  style: TextStyle(
                    color: homework.isCompleted ? Colors.green : Colors.white70,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
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
                const SizedBox(height: 4),
                if (homework.subject.isNotEmpty) ...[
                  Text(
                    homework.subject,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
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
                      _getDueStatus(homework),
                      style: TextStyle(
                        color: _getDueStatusColor(homework),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          homework.isCompleted
              ? Icon(Icons.check_circle_rounded, color: Colors.green.shade400)
              : Icon(
                  isOverdue ? Icons.warning_rounded : Icons.schedule_rounded,
                  color: isOverdue ? Colors.red.shade400 : Colors.orange.shade400,
                ),
        ],
      ),
    );
  }

  bool _isDueSoon(DateTime dueDate) {
    final now = DateTime.now();
    final difference = dueDate.difference(now);
    return difference.inDays <= 3 && difference.inDays >= 0;
  }

  String _getDueStatus(Homework homework) {
    if (homework.isCompleted) return 'Completed';
    
    final now = DateTime.now();
    final difference = homework.dueDate.difference(now);
    
    if (difference.inDays < 0) return 'Overdue';
    if (difference.inDays == 0) return 'Due today';
    if (difference.inDays == 1) return 'Due tomorrow';
    if (difference.inDays <= 3) return 'Due in ${difference.inDays} days';
    return 'Due ${homework.dueDate.day}/${homework.dueDate.month}';
  }

  Color _getDueStatusColor(Homework homework) {
    if (homework.isCompleted) return Colors.green;
    
    final now = DateTime.now();
    final difference = homework.dueDate.difference(now);
    
    if (difference.inDays < 0) return Colors.red;
    if (difference.inDays <= 3) return Colors.orange;
    return Colors.white70;
  }

  String _getMonthName(int month) {
    switch (month) {
      case 1: return 'January';
      case 2: return 'February';
      case 3: return 'March';
      case 4: return 'April';
      case 5: return 'May';
      case 6: return 'June';
      case 7: return 'July';
      case 8: return 'August';
      case 9: return 'September';
      case 10: return 'October';
      case 11: return 'November';
      case 12: return 'December';
      default: return '';
    }
  }

  String _getMonthAbbr(int month) {
    switch (month) {
      case 1: return 'JAN';
      case 2: return 'FEB';
      case 3: return 'MAR';
      case 4: return 'APR';
      case 5: return 'MAY';
      case 6: return 'JUN';
      case 7: return 'JUL';
      case 8: return 'AUG';
      case 9: return 'SEP';
      case 10: return 'OCT';
      case 11: return 'NOV';
      case 12: return 'DEC';
      default: return '';
    }
  }
}