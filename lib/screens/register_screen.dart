import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../firebase_service.dart';
import 'login_screen.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _studentIdController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _displayNameController.dispose();
    _studentIdController.dispose();
    super.dispose();
  }

  void _register() async {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Passwords do not match'),
            backgroundColor: Colors.red.shade500,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        return;
      }

      if (!_agreeToTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please agree to terms and conditions'),
            backgroundColor: Colors.orange.shade500,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        return;
      }

      setState(() => _isLoading = true);
      
      try {
        bool success = await Provider.of<FirebaseService>(context, listen: false)
            .signUp(_emailController.text, _passwordController.text, _displayNameController.text);
            
        setState(() => _isLoading = false);

        if (success && mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
          );
        } else if (mounted) {
          _showErrorDialog();
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          String errorMessage = 'Unable to create your account. Please try again.';
          if (e is FirebaseAuthException) {
            switch (e.code) {
              case 'email-already-in-use':
                errorMessage = 'This email is already registered. Please use a different email.';
                break;
              case 'weak-password':
                errorMessage = 'Password is too weak. Please use a stronger password.';
                break;
              case 'invalid-email':
                errorMessage = 'Invalid email address. Please check your email.';
                break;
            }
          }
          _showErrorDialog(errorMessage);
        }
      }
    }
  }

  void _showErrorDialog([String? errorMessage]) {
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
                  color: const Color(0xFFEF4444).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 32),
              ),
              const SizedBox(height: 16),
              const Text(
                'Registration Failed',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                errorMessage ?? 'Unable to create your account. Please try again.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    textStyle: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  child: const Text('Try Again'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Colors.white),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            expandedHeight: 180,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF7C3AED),
                      Color(0xFF06B6D4),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -30,
                      right: -30,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ),
                    const Center(
                      child: Text(
                        'Join Our Community',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          const Text(
                            'Create Your Account 🚀',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Join thousands of students in our learning community',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 40),

                          // Form Card
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 30,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  // Display Name Field
                                  TextFormField(
                                    controller: _displayNameController,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      labelText: 'Full Name',
                                      labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                                      prefixIcon: Container(
                                        margin: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF7C3AED).withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(Icons.person_rounded, color: Color(0xFF7C3AED)),
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(15),
                                        borderSide: BorderSide.none,
                                      ),
                                      filled: true,
                                      fillColor: Colors.white.withOpacity(0.05),
                                    ),
                                    validator: (v) => v!.isEmpty ? 'Full name is required' : null,
                                  ),
                                  const SizedBox(height: 20),

                                  // Student ID Field
                                  TextFormField(
                                    controller: _studentIdController,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      labelText: 'Student ID (Optional)',
                                      labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                                      prefixIcon: Container(
                                        margin: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF7C3AED).withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(Icons.badge_rounded, color: Color(0xFF7C3AED)),
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(15),
                                        borderSide: BorderSide.none,
                                      ),
                                      filled: true,
                                      fillColor: Colors.white.withOpacity(0.05),
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  // Email Field
                                  TextFormField(
                                    controller: _emailController,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      labelText: 'Email Address',
                                      labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                                      prefixIcon: Container(
                                        margin: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF7C3AED).withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(Icons.email_rounded, color: Color(0xFF7C3AED)),
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(15),
                                        borderSide: BorderSide.none,
                                      ),
                                      filled: true,
                                      fillColor: Colors.white.withOpacity(0.05),
                                    ),
                                    validator: (v) => v!.isEmpty ? 'Email is required' : null,
                                  ),
                                  const SizedBox(height: 20),

                                  // Password Field
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      labelText: 'Password',
                                      labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                                      prefixIcon: Container(
                                        margin: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF7C3AED).withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(Icons.lock_rounded, color: Color(0xFF7C3AED)),
                                      ),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                          color: const Color(0xFF94A3B8),
                                        ),
                                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(15),
                                        borderSide: BorderSide.none,
                                      ),
                                      filled: true,
                                      fillColor: Colors.white.withOpacity(0.05),
                                    ),
                                    validator: (v) => v!.length < 6 ? 'Password must be at least 6 characters' : null,
                                  ),
                                  const SizedBox(height: 20),

                                  // Confirm Password Field
                                  TextFormField(
                                    controller: _confirmPasswordController,
                                    obscureText: _obscureConfirmPassword,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      labelText: 'Confirm Password',
                                      labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                                      prefixIcon: Container(
                                        margin: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF7C3AED).withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(Icons.lock_reset_rounded, color: Color(0xFF7C3AED)),
                                      ),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                                          color: const Color(0xFF94A3B8),
                                        ),
                                        onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(15),
                                        borderSide: BorderSide.none,
                                      ),
                                      filled: true,
                                      fillColor: Colors.white.withOpacity(0.05),
                                    ),
                                    validator: (v) => v!.isEmpty ? 'Please confirm your password' : null,
                                  ),
                                  const SizedBox(height: 24),

                                  // Terms and Conditions
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Checkbox(
                                        value: _agreeToTerms,
                                        onChanged: (value) => setState(() => _agreeToTerms = value ?? false),
                                        fillColor: MaterialStateProperty.resolveWith<Color>((states) {
                                          if (states.contains(MaterialState.selected)) {
                                            return const Color(0xFF7C3AED);
                                          }
                                          return Colors.transparent;
                                        }),
                                        checkColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text.rich(
                                          TextSpan(
                                            children: [
                                              const TextSpan(
                                                text: 'I agree to the ',
                                                style: TextStyle(color: Color(0xFF94A3B8)),
                                              ),
                                              WidgetSpan(
                                                child: GestureDetector(
                                                  onTap: () {},
                                                  child: const Text(
                                                    'Terms of Service',
                                                    style: TextStyle(
                                                      color: Color(0xFF7C3AED),
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const TextSpan(
                                                text: ' and ',
                                                style: TextStyle(color: Color(0xFF94A3B8)),
                                              ),
                                              WidgetSpan(
                                                child: GestureDetector(
                                                  onTap: () {},
                                                  child: const Text(
                                                    'Privacy Policy',
                                                    style: TextStyle(
                                                      color: Color(0xFF7C3AED),
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),

                                  // Register Button
                                  SizedBox(
                                    width: double.infinity,
                                    height: 56,
                                    child: _isLoading
                                        ? const Center(
                                            child: CircularProgressIndicator(
                                              valueColor: AlwaysStoppedAnimation(Color(0xFF7C3AED)),
                                            ),
                                          )
                                        : ElevatedButton(
                                            onPressed: _register,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF7C3AED),
                                              foregroundColor: Colors.white,
                                              elevation: 8,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(15),
                                              ),
                                              textStyle: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              shadowColor: const Color(0xFF7C3AED).withOpacity(0.4),
                                            ),
                                            child: const Text('Create My Account'),
                                          ),
                                  ),
                                  const SizedBox(height: 24),

                                  // Login Link
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Already have an account? ',
                                        style: TextStyle(color: Colors.white.withOpacity(0.7)),
                                      ),
                                      GestureDetector(
                                        onTap: () => Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                                        ),
                                        child: const Text(
                                          'Sign In',
                                          style: TextStyle(
                                            color: Color(0xFF7C3AED),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
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
          ),
        ],
      ),
    );
  }
}