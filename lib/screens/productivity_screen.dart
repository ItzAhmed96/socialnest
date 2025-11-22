import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../firebase_service.dart';
import 'pomodoro_screen.dart';
import 'homework_tracker_screen.dart';
import 'study_calendar_screen.dart';
import 'study_stats_screen.dart';

class ProductivityScreen extends StatelessWidget {
  const ProductivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7C3AED), Color(0xFF06B6D4)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.work_outline_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Study Tools',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Quick Actions Grid
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  _buildToolCard(
                    'Pomodoro Timer',
                    Icons.timer_rounded,
                    Colors.green,
                    'Focus sessions',
                    () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const PomodoroScreen()));
                    },
                  ),
                  _buildToolCard(
                    'Homework Tracker',
                    Icons.assignment_rounded,
                    Colors.orange,
                    'Manage assignments',
                    () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const HomeworkTrackerScreen()));
                    },
                  ),
                  _buildToolCard(
                    'Study Calendar',
                    Icons.calendar_today_rounded,
                    Colors.blue,
                    'View schedule',
                    () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const StudyCalendarScreen()));
                    },
                  ),
                  _buildToolCard(
                    'Study Stats',
                    Icons.analytics_rounded,
                    Colors.purple,
                    'Your progress',
                    () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const StudyStatsScreen()));
                    },
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Study Statistics
              const Text(
                'Study Statistics',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              StreamBuilder<DocumentSnapshot>(
                stream: Provider.of<FirebaseService>(context).getUserDataStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
                    );
                  }
                  
                  final userData = snapshot.data?.data() as Map<String, dynamic>?;
                  final studyHours = userData?['studyHours'] ?? 0.0;
                  final quizzesCompleted = userData?['quizzesCompleted'] ?? 0;
                  final notesCreated = userData?['notesCreated'] ?? 0;
                  
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem('Study Hours', '${studyHours.toStringAsFixed(1)}h', Icons.timer_rounded, Colors.green),
                            _buildStatItem('Quizzes', '$quizzesCompleted', Icons.quiz_rounded, Colors.blue),
                            _buildStatItem('Notes', '$notesCreated', Icons.note_rounded, Colors.purple),
                          ],
                        ),
                        const SizedBox(height: 16),
                        LinearProgressIndicator(
                          value: (studyHours % 10) / 10,
                          backgroundColor: Colors.white.withOpacity(0.1),
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF7C3AED)),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Keep going! ${(10 - (studyHours % 10)).toStringAsFixed(1)}h to next level',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // Quick Tips Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF7C3AED).withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7C3AED).withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.lightbulb_rounded, size: 20, color: Color(0xFF7C3AED)),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Study Tip',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Try the Pomodoro technique: 25 minutes of focused study followed by a 5-minute break. Repeat 4 times, then take a longer break.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Recent Activity
              const Text(
                'Recent Activity',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              StreamBuilder<QuerySnapshot>(
                stream: Provider.of<FirebaseService>(context).getUserActivities(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.history_rounded, size: 40, color: Colors.white30),
                          SizedBox(height: 8),
                          Text(
                            'No recent activity',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    );
                  }

                  final activities = snapshot.data!.docs.take(3).toList();

                  return Column(
                    children: activities.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                       return _buildActivityItem(
                        data['title'] ?? 'Activity',
                        data['description'] ?? '',
                        _getActivityIcon(data['type'] ?? ''),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolCard(String title, IconData icon, Color color, String subtitle, VoidCallback onTap) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(String title, String description, IconData icon) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: const Color(0xFF7C3AED)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getActivityIcon(String type) {
    switch (type) {
      case 'post_created':
        return Icons.post_add_rounded;
      case 'quiz_created':
        return Icons.quiz_rounded;
      case 'homework_added':
        return Icons.assignment_rounded;
      case 'achievement_unlocked':
        return Icons.emoji_events_rounded;
      case 'study_session_completed':
        return Icons.timer_rounded;
      case 'note_created':
        return Icons.note_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }
}




