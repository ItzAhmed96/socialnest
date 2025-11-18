class Story {
  final String id;
  final String userId;
  final String userName;
  final String userAvatar;
  final String? imageUrl;
  final String? textContent;
  final String? backgroundColor;
  final String? textColor;
  final DateTime createdAt;
  final DateTime expiresAt;

  Story({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    this.imageUrl,
    this.textContent,
    this.backgroundColor,
    this.textColor,
    required this.createdAt,
    required this.expiresAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'imageUrl': imageUrl,
      'textContent': textContent,
      'backgroundColor': backgroundColor,
      'textColor': textColor,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'expiresAt': expiresAt.millisecondsSinceEpoch,
    };
  }

  factory Story.fromMap(Map<String, dynamic> map) {
    return Story(
      id: map['id'],
      userId: map['userId'],
      userName: map['userName'],
      userAvatar: map['userAvatar'],
      imageUrl: map['imageUrl'],
      textContent: map['textContent'],
      backgroundColor: map['backgroundColor'],
      textColor: map['textColor'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      expiresAt: DateTime.fromMillisecondsSinceEpoch(map['expiresAt']),
    );
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;
  bool get hasText => textContent != null && textContent!.isNotEmpty;

  Duration get timeRemaining => expiresAt.difference(DateTime.now());
}