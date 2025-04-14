// lib/repositories/messaging_repository.dart
import 'dart:io';
import 'package:gig_marketplace/models/message.dart';
import 'package:gig_marketplace/services/api_service.dart';

class MessagingRepository {
  final ApiService apiService;

  MessagingRepository({required this.apiService});

  // Get user conversations
  Future<List<Conversation>> getConversations({required String userId}) async {
    try {
      final response = await apiService.get(
        endpoint: '/users/$userId/conversations',
        requiresAuth: true,
      );

      final List<dynamic> conversationsData = response['data'];
      return conversationsData.map((convoData) => Conversation.fromJson(convoData)).toList();
    } catch (e) {
      throw Exception('Failed to get conversations: ${e.toString()}');
    }
  }

  // Get messages for a conversation
  Future<List<Message>> getMessages({required String conversationId}) async {
    try {
      final response = await apiService.get(
        endpoint: '/conversations/$conversationId/messages',
        requiresAuth: true,
      );

      final List<dynamic> messagesData = response['data'];
      return messagesData.map((msgData) => Message.fromJson(msgData)).toList();
    } catch (e) {
      throw Exception('Failed to get messages: ${e.toString()}');
    }
  }

  // Send a message
  Future<Message> sendMessage({
    required String senderId,
    required String receiverId,
    required String content,
    File? attachment,
  }) async {
    try {
      // If there's an attachment, use multipart request
      if (attachment != null) {
        final Map<String, dynamic> fields = {
          'senderId': senderId,
          'receiverId': receiverId,
          'content': content,
        };
        
        final Map<String, File> files = {'attachment': attachment};

        final response = await apiService.multipartRequest(
          method: 'POST',
          endpoint: '/messages',
          fields: fields,
          files: files,
          requiresAuth: true,
        );

        return Message.fromJson(response['data']);
      } else {
        // Regular JSON request for messages without attachments
        final response = await apiService.post(
          endpoint: '/messages',
          body: {
            'senderId': senderId,
            'receiverId': receiverId,
            'content': content,
          },
          requiresAuth: true,
        );

        return Message.fromJson(response['data']);
      }
    } catch (e) {
      throw Exception('Failed to send message: ${e.toString()}');
    }
  }

  // Mark conversation as read
  Future<void> markConversationAsRead({
    required String conversationId,
    required String userId,
  }) async {
    try {
      await apiService.patch(
        endpoint: '/conversations/$conversationId/read',
        body: {'userId': userId},
        requiresAuth: true,
      );
    } catch (e) {
      throw Exception('Failed to mark conversation as read: ${e.toString()}');
    }
  }
}