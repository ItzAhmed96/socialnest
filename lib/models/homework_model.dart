import 'package:flutter/material.dart'; // ADD THIS IMPORT

class Homework {
  final String id;
  final String title;
  final String description;
  final String subject;
  final DateTime dueDate;
  final bool isCompleted;
  final int priority; // 1=High, 2=Medium, 3=Low

  Homework({
    required this.id,
    required this.title,
    required this.description,
    required this.subject,
    required this.dueDate,
    this.isCompleted = false,
    this.priority = 2,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'subject': subject,
      'dueDate': dueDate.millisecondsSinceEpoch,
      'isCompleted': isCompleted,
      'priority': priority,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    };
  }

  static Homework fromMap(Map<String, dynamic> map) {
    return Homework(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      subject: map['subject'],
      dueDate: DateTime.fromMillisecondsSinceEpoch(map['dueDate']),
      isCompleted: map['isCompleted'],
      priority: map['priority'],
    );
  }

  String get priorityText {
    switch (priority) {
      case 1: return 'High';
      case 2: return 'Medium';
      case 3: return 'Low';
      default: return 'Medium';
    }
  }

  Color get priorityColor {
    switch (priority) {
      case 1: return Colors.red;
      case 2: return Colors.orange;
      case 3: return Colors.green;
      default: return Colors.orange;
    }
  }

  String get timeLeft {
    final now = DateTime.now();
    final difference = dueDate.difference(now);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} days left';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours left';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes left';
    } else {
      return 'Overdue';
    }
  }
}