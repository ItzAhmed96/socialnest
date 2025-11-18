import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6, curve: Curves.easeInOut)),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.2, 0.8, curve: Curves.elasticOut)),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.4, 1.0, curve: Curves.easeOut)),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F172A),
              Color(0xFF1E293B),
              Color(0xFF334155),
            ],
          ),
        ),
        child: Stack(
          children: [
            // DEBUG TEXT - REMOVE LATER
            Positioned(
              top: 40,
              left: 20,
              child: Text(
                'DEBUG: Screen loaded',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 12,
                ),
              ),
            ),

            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF7C3AED).withOpacity(0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -150,
              left: -150,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF06B6D4).withOpacity(0.2),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Opacity(
                        opacity: _fadeAnimation.value,
                        child: Column(
                          children: [
                            Align(
                              alignment: Alignment.topRight,
                              child: TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                                  );
                                },
                                child: Text(
                                  'Skip',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),

                            const Spacer(flex: 2),

                            SlideTransition(
                              position: _slideAnimation,
                              child: Column(
                                children: [
                                  Container(
                                    width: 140,
                                    height: 140,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF7C3AED),
                                          Color(0xFF06B6D4),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(30),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF7C3AED).withOpacity(0.4),
                                          blurRadius: 30,
                                          offset: const Offset(0, 20),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Image.asset(
                                        'assets/images/logo.png',
                                        width: 70,
                                        height: 70,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 40),

                                  const Text(
                                    'SocialNest',
                                    style: TextStyle(
                                      fontSize: 52,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: -1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  const Text(
                                    'Connect, Share & Grow Together\nYour Safe Social Space',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Color(0xFF94A3B8),
                                      fontWeight: FontWeight.w400,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const Spacer(flex: 2),

                            FadeTransition(
                              opacity: _fadeAnimation,
                              child: Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(25),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.1),
                                    width: 1,
                                  ),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    FeatureStat(
                                      icon: Icons.people_rounded,
                                      value: '50K+',
                                      label: 'Users',
                                    ),
                                    FeatureStat(
                                      icon: Icons.photo_library_rounded,
                                      value: '100K+',
                                      label: 'Posts',
                                    ),
                                    FeatureStat(
                                      icon: Icons.favorite_rounded,
                                      value: '1M+',
                                      label: 'Likes',
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const Spacer(),

                            SlideTransition(
                              position: _slideAnimation,
                              child: Column(
                                children: [
                                  Container(
                                    width: double.infinity,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF7C3AED),
                                          Color(0xFF06B6D4),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF7C3AED).withOpacity(0.4),
                                          blurRadius: 20,
                                          offset: const Offset(0, 10),
                                        ),
                                      ],
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (_) => const RegisterScreen()),
                                          );
                                        },
                                        borderRadius: BorderRadius.circular(20),
                                        child: const Center(
                                          child: Text(
                                            'Join SocialNest',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  Container(
                                    width: double.infinity,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.3),
                                        width: 2,
                                      ),
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                                          );
                                        },
                                        borderRadius: BorderRadius.circular(20),
                                        child: const Center(
                                          child: Text(
                                            'I Have an Account',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FeatureStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const FeatureStat({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 24, color: Colors.white),
        ),
        const SizedBox(height: 12),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}