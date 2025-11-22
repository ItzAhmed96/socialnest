import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase_service.dart';

class StudyStatsScreen extends StatefulWidget {
  const StudyStatsScreen({super.key});

  @override
  State<StudyStatsScreen> createState() => _StudyStatsScreenState();
}

class _StudyStatsScreenState extends State<StudyStatsScreen> {
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await Provider.of<FirebaseService>(context, listen: false).getStudyStatistics();
    setState(() {
      _stats = stats;
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalStudyHours = _stats['totalStudyHours'] ?? 0.0;
    final weeklyStudyHours = _stats['weeklyStudyHours'] ?? 0.0;
    final quizzesCompleted = _stats['quizzesCompleted'] ?? 0;
    final notesCreated = _stats['notesCreated'] ?? 0;
    final postsCount = _stats['postsCount'] ?? 0;
    final homeworkCompleted = _stats['homeworkCompleted'] ?? 0;
    final studyStreak = _stats['studyStreak'] ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Study Analytics', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Overall Progress
              _buildLevelProgress(totalStudyHours),
              const SizedBox(height: 20),

              // Stats Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  _buildStatCard('Study Hours', '${totalStudyHours.toStringAsFixed(1)}h', Icons.timer_rounded, Colors.green),
                  _buildStatCard('Weekly Hours', '${weeklyStudyHours.toStringAsFixed(1)}h', Icons.calendar_today_rounded, Colors.blue),
                  _buildStatCard('Study Streak', '$studyStreak days', Icons.local_fire_department_rounded, Colors.orange),
                  _buildStatCard('Quizzes Done', '$quizzesCompleted', Icons.quiz_rounded, Colors.purple),
                  _buildStatCard('Notes Created', '$notesCreated', Icons.note_rounded, Colors.pink),
                  _buildStatCard('Posts Shared', '$postsCount', Icons.post_add_rounded, Colors.cyan),
                ],
              ),

              const SizedBox(height: 20),
              _buildWeeklyProgress(weeklyStudyHours),
              const SizedBox(height: 20),
              _buildAchievementsProgress(totalStudyHours),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLevelProgress(double studyHours) {
    final level = (studyHours ~/ 10) + 1;
    final progress = (studyHours % 10) / 10;
    final hoursToNextLevel = (10 - (studyHours % 10)).toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF06B6D4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text(
            'Learning Level',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: progress,
                strokeWidth: 12,
                backgroundColor: Colors.white.withOpacity(0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              Column(
                children: [
                  Text(
                    'Level $level',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${studyHours.toStringAsFixed(1)}h',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '$hoursToNextLevel h to next level',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyProgress(double weeklyHours) {
    final weeklyGoal = 5.0;
    final progress = weeklyHours / weeklyGoal;
    final remainingHours = (weeklyGoal - weeklyHours).toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.flag_rounded, color: Color(0xFF7C3AED)),
              SizedBox(width: 8),
              Text(
                'Weekly Goal',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress > 1 ? 1.0 : progress,
            backgroundColor: Colors.white.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(
              progress >= 1 ? Colors.green : Color(0xFF7C3AED),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${weeklyHours.toStringAsFixed(1)}h / ${weeklyGoal}h',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                progress >= 1 ? 'Goal achieved! 🎉' : '$remainingHours h to go',
                style: TextStyle(
                  color: progress >= 1 ? Colors.green : Color(0xFF7C3AED),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsProgress(double totalHours) {
    final achievements = [
      {'name': 'Study Beginner', 'hours': 5.0, 'unlocked': totalHours >= 5},
      {'name': 'Study Marathon', 'hours': 10.0, 'unlocked': totalHours >= 10},
      {'name': 'Study Enthusiast', 'hours': 20.0, 'unlocked': totalHours >= 20},
      {'name': 'Study Master', 'hours': 50.0, 'unlocked': totalHours >= 50},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.emoji_events_rounded, color: Color(0xFFFFD700)),
              SizedBox(width: 8),
              Text(
                'Achievements',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...achievements.map((achievement) => _buildAchievementItem(
            achievement['name'] as String,
            achievement['hours'] as double,
            achievement['unlocked'] as bool,
            totalHours,
          )),
        ],
      ),
    );
  }

  Widget _buildAchievementItem(String name, double requiredHours, bool unlocked, double currentHours) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: unlocked ? Colors.green.withOpacity(0.1) : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: unlocked ? Colors.green : Colors.white.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Icon(
            unlocked ? Icons.check_circle_rounded : Icons.lock_rounded,
            color: unlocked ? Colors.green : Colors.white54,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: unlocked ? Colors.white : Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  unlocked ? 'Completed!' : '${requiredHours}h required',
                  style: TextStyle(
                    color: unlocked ? Colors.green : Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (!unlocked)
            Text(
              '${(requiredHours - currentHours).toStringAsFixed(1)}h left',
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}