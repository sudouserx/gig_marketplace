// lib/models/message.dart
class Message {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime sentAt;
  final bool isRead;
  final String? attachmentUrl;

  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.sentAt,
    required this.isRead,
    this.attachmentUrl,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      senderId: json['senderId'],
      receiverId: json['receiverId'],
      content: json['content'],
      sentAt: DateTime.parse(json['sentAt']),
      isRead: json['isRead'],
      attachmentUrl: json['attachmentUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'sentAt': sentAt.toIso8601String(),
      'isRead': isRead,
      'attachmentUrl': attachmentUrl,
    };
  }
}

class Conversation {
  final String id;
  final String userId;  // The other user's ID
  final String userFullName;
  final String? userProfilePicture;
  final Message lastMessage;
  final int unreadCount;

  Conversation({
    required this.id,
    required this.userId,
    required this.userFullName,
    this.userProfilePicture,
    required this.lastMessage,
    required this.unreadCount,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'],
      userId: json['userId'],
      userFullName: json['userFullName'],
      userProfilePicture: json['userProfilePicture'],
      lastMessage: Message.fromJson(json['lastMessage']),
      unreadCount: json['unreadCount'],
    );
  }
}