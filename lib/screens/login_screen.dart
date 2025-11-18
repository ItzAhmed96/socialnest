import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../firebase_service.dart';
import 'register_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
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
    super.dispose();
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      try {
        bool success = await Provider.of<FirebaseService>(context, listen: false)
            .signIn(_emailController.text, _passwordController.text);
            
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
        if (mounted) _showErrorDialog();
      }
    }
  }

  void _showErrorDialog() {
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
                'Authentication Failed',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please check your credentials and try again.',
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
            expandedHeight: 200,
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
                child: const Center(
                  child: Text(
                    'Welcome Back',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
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
                            'Continue Your Journey 🚀',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Sign in to access your courses, groups, and progress',
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
                                    validator: (v) => v!.isEmpty ? 'Password is required' : null,
                                  ),
                                  const SizedBox(height: 16),

                                  // Forgot Password
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () {},
                                      child: const Text(
                                        'Forgot Password?',
                                        style: TextStyle(color: Color(0xFF7C3AED)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // Login Button
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
                                            onPressed: _login,
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
                                            child: const Text('Sign In to Your Account'),
                                          ),
                                  ),
                                  const SizedBox(height: 32),

                                  // Register Link
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'New to SocialNest? ',
                                        style: TextStyle(color: Colors.white.withOpacity(0.7)),
                                      ),
                                      GestureDetector(
                                        onTap: () => Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(builder: (_) => const RegisterScreen()),
                                        ),
                                        child: const Text(
                                          'Create Account',
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
