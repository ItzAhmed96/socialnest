import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_service.dart';
import 'screens/welcome_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/create_screen.dart';
import 'screens/friends_screen.dart';
import 'screens/explore_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/comments_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/create_story_screen.dart';
import 'screens/story_screen.dart';
import 'screens/saved_posts_screen.dart'; // NEW

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
        theme: ThemeData(
          primaryColor: const Color(0xFF7C3AED),
          primaryColorDark: const Color(0xFF6D28D9),
          primaryColorLight: const Color(0xFF8B5CF6),
          scaffoldBackgroundColor: const Color(0xFF0F172A),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF7C3AED),
            secondary: Color(0xFF06B6D4),
            surface: Color(0xFF1E293B),
            background: Color(0xFF0F172A),
            onPrimary: Colors.white,
            onSurface: Colors.white,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1E293B),
            elevation: 0,
            centerTitle: true,
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
        routes: {
          '/welcome': (context) => const WelcomeScreen(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/home': (context) => const HomeScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/create': (context) => const CreateScreen(),
          '/friends': (context) => const FriendsScreen(),
          '/explore': (context) => const ExploreScreen(),
          '/notifications': (context) => const NotificationsScreen(),
          '/create_story': (context) => const CreateStoryScreen(),
          '/saved_posts': (context) => SavedPostsScreen(), // FIXED: Removed const
          // Note: CommentsScreen and StoryScreen require parameters, so they should be navigated to using Navigator.push
        },
      ),
    );
  }
}