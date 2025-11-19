import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_service.dart';
import 'screens/welcome_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyAlm6Q5DpoDgYD2bhzdQ3n7B0oG1OsAV9E",
        authDomain: "socialnest-ahmed.firebaseapp.com",
        projectId: "socialnest-ahmed",
        storageBucket: "socialnest-ahmed.firebasestorage.app",
        messagingSenderId: "66708866665",
        appId: "1:66708866665:web:04c786b456322b885404f8",
      ),
    );
    print('🔥 Firebase initialized successfully');
  } catch (e) {
    print('❌ Firebase initialization failed: $e');
  }
  
  runApp(const SocialNestApp());
}

class SocialNestApp extends StatelessWidget {
  const SocialNestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => FirebaseService(),
      child: MaterialApp(
        title: 'SocialNest',
        theme: ThemeData.dark().copyWith(
          primaryColor: const Color(0xFF7C3AED),
          scaffoldBackgroundColor: const Color(0xFF0F172A),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1E293B),
            elevation: 0,
          ),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF7C3AED),
            secondary: Color(0xFF06B6D4),
          ),
        ),
        home: Consumer<FirebaseService>(
          builder: (context, firebaseService, child) {
            if (firebaseService.isLoggedIn) {
              return const HomeScreen();
            } else {
              return const WelcomeScreen();
            }
          },
        ),
      ),
    );
  }
}