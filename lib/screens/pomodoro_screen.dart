import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../firebase_service.dart';

class PomodoroScreen extends StatefulWidget {
  const PomodoroScreen({super.key});

  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> {
  int _selectedTime = 25;
  bool _isRunning = false;
  int _secondsRemaining = 25 * 60;
  int _completedSessions = 0;
  bool _isBreakTime = false;

  final List<int> _focusTimes = [15, 25, 30, 45];
  final List<int> _breakTimes = [5, 10, 15];

  void _startTimer() async {
    setState(() {
      _isRunning = true;
      _secondsRemaining = _selectedTime * 60;
    });
    await _startCountdown();
  }

  Future<void> _startCountdown() async {
    while (_isRunning && _secondsRemaining > 0) {
      await Future.delayed(const Duration(seconds: 1));
      if (_isRunning) {
        setState(() {
          _secondsRemaining--;
        });
      }
    }
    
    if (_secondsRemaining == 0 && _isRunning) {
      _onTimerComplete();
    }
  }

  void _onTimerComplete() async {
  if (!_isBreakTime) {
    // Focus session completed
    _completedSessions++;
    
    // Record study session in Firebase
    await Provider.of<FirebaseService>(context, listen: false)
        .recordStudySession(_selectedTime.toDouble());
    
    // Show completion dialog
    _showSessionCompleteDialog();
    
    // Start break automatically
    _startBreakTimer();
  } else {
    // Break completed
    _showBreakCompleteDialog();
    _isBreakTime = false;
  }
}

  void _startBreakTimer() {
    setState(() {
      _isBreakTime = true;
      _selectedTime = 5; // 5-minute break by default
      _secondsRemaining = _selectedTime * 60;
    });
    _startCountdown();
  }

  void _showSessionCompleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('🎉 Focus Session Complete!', 
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'You focused for $_selectedTime minutes!',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 10),
            const Text(
              'Take a short break to recharge.',
              style: TextStyle(color: Colors.white70),
            ),
          ],
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

  void _showBreakCompleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('⏰ Break Time Over!', 
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: const Text(
          'Ready for your next focus session?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Start Next Session', style: TextStyle(color: Color(0xFF7C3AED))),
          ),
        ],
      ),
    );
  }

  void _pauseTimer() {
    setState(() {
      _isRunning = false;
    });
  }

  void _resetTimer() {
    setState(() {
      _isRunning = false;
      _secondsRemaining = _selectedTime * 60;
      _isBreakTime = false;
    });
  }

  void _skipBreak() {
    setState(() {
      _isRunning = false;
      _isBreakTime = false;
      _secondsRemaining = _selectedTime * 60;
    });
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    double progress = 1 - (_secondsRemaining / (_selectedTime * 60));
    Color timerColor = _isBreakTime ? Colors.green : const Color(0xFF7C3AED);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(
          _isBreakTime ? 'Break Time' : 'Pomodoro Timer',
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Session Counter
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Sessions: $_completedSessions',
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ),
            const SizedBox(height: 30),

            // Circular Progress Timer
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.1), width: 8),
                  ),
                ),
                Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: _isBreakTime 
                          ? [Colors.green, Colors.lightGreenAccent]
                          : [const Color(0xFF7C3AED), const Color(0xFF06B6D4)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 10,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.3)),
                  ),
                ),
                Column(
                  children: [
                    Text(
                      _isBreakTime ? 'BREAK' : 'FOCUS',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatTime(_secondsRemaining),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 52,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isBreakTime ? 'Relax and recharge' : 'Stay focused!',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 40),

            // Time Selection
            Text(
              _isBreakTime ? 'Break Duration' : 'Focus Duration',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: (_isBreakTime ? _breakTimes : _focusTimes).map((time) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: ChoiceChip(
                    label: Text('${time}m', 
                        style: TextStyle(color: _selectedTime == time ? Colors.white : Colors.white70)),
                    selected: _selectedTime == time,
                    onSelected: _isRunning ? null : (selected) {
                      setState(() {
                        _selectedTime = time;
                        _secondsRemaining = time * 60;
                      });
                    },
                    backgroundColor: const Color(0xFF1E293B),
                    selectedColor: timerColor,
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 40),

            // Control Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!_isRunning && !_isBreakTime) ...[
                  ElevatedButton(
                    onPressed: _startTimer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.play_arrow_rounded),
                        SizedBox(width: 8),
                        Text('Start Focus', style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                ] else if (_isRunning) ...[
                  ElevatedButton(
                    onPressed: _pauseTimer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF59E0B),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.pause_rounded),
                        SizedBox(width: 8),
                        Text('Pause', style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton(
                    onPressed: _resetTimer,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    ),
                    child: const Text('Reset', style: TextStyle(fontSize: 16)),
                  ),
                ] else if (_isBreakTime && !_isRunning) ...[
                  ElevatedButton(
                    onPressed: _startTimer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.breakfast_dining_rounded),
                        SizedBox(width: 8),
                        Text('Start Break', style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton(
                    onPressed: _skipBreak,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    ),
                    child: const Text('Skip Break', style: TextStyle(fontSize: 16)),
                  ),
                ],
              ],
            ),

            // Study Stats - SIMPLIFIED VERSION
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text(
                    'Session Statistics',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem('Total Hours', '${(_completedSessions * _selectedTime) / 60}h', Icons.timer_rounded),
                      _buildStatItem('Sessions', '$_completedSessions', Icons.emoji_events_rounded),
                      _buildStatItem('Focus Time', '${_selectedTime}m', Icons.psychology_rounded),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF7C3AED), size: 24),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}