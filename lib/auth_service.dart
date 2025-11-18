import 'package:flutter/foundation.dart';

class AuthService with ChangeNotifier {
  String? _currentUser;
  String? _userName;
  String? _userBio = "Teen learner passionate about science and tech!";
  String? _userAvatar;
  int _userLevel = 5;
  int _userPoints = 750;
  int _friendsCount = 45;
  int _postsCount = 12;

  bool get isLoggedIn => _currentUser != null;
  String? get currentUser => _currentUser;
  String? get userName => _userName;
  String? get userBio => _userBio;
  String? get userAvatar => _userAvatar;
  int get userLevel => _userLevel;
  int get userPoints => _userPoints;
  int get friendsCount => _friendsCount;
  int get postsCount => _postsCount;

  Future<bool> signUp(String email, String password, String displayName) async {
    await Future.delayed(const Duration(seconds: 2));
    _currentUser = email;
    _userName = displayName;
    _userAvatar = displayName[0];
    notifyListeners();
    return true;
  }

  Future<bool> signIn(String email, String password) async {
    await Future.delayed(const Duration(seconds: 2));
    if (email.isNotEmpty && password.isNotEmpty) {
      _currentUser = email;
      _userName = email.split('@').first;
      _userAvatar = _userName![0];
      notifyListeners();
      return true;
    }
    return false;
  }

  void signOut() {
    _currentUser = null;
    _userName = null;
    _userAvatar = null;
    notifyListeners();
  }

  void addPoints(int points) {
    _userPoints += points;
    if (_userPoints >= 1000) {
      _userLevel++;
      _userPoints = _userPoints - 1000;
    }
    notifyListeners();
  }

  void updateProfile(String name, String bio) {
    _userName = name;
    _userBio = bio;
    notifyListeners();
  }

  void addFriend() {
    _friendsCount++;
    notifyListeners();
  }

  void addPost() {
    _postsCount++;
    notifyListeners();
  }
}