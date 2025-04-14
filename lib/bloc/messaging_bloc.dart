// lib/bloc/messaging_bloc.dart
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gig_marketplace/models/message.dart';
import 'package:gig_marketplace/repositories/messaging_repository.dart';

// Events
abstract class MessagingEvent {}

class LoadConversationsEvent extends MessagingEvent {
  final String userId;

  LoadConversationsEvent({required this.userId});
}

class LoadMessagesEvent extends MessagingEvent {
  final String conversationId;

  LoadMessagesEvent({required this.conversationId});
}

class SendMessageEvent extends MessagingEvent {
  final String senderId;
  final String receiverId;
  final String content;
  final File? attachment;

  SendMessageEvent({
    required this.senderId,
    required this.receiverId,
    required this.content,
    this.attachment,
  });
}

class MarkConversationAsReadEvent extends MessagingEvent {
  final String conversationId;
  final String userId;

  MarkConversationAsReadEvent({
    required this.conversationId,
    required this.userId,
  });
}

// States
abstract class MessagingState {}

class MessagingInitial extends MessagingState {}

class MessagingLoading extends MessagingState {}

class ConversationsLoaded extends MessagingState {
  final List<Conversation> conversations;

  ConversationsLoaded({required this.conversations});
}

class MessagesLoaded extends MessagingState {
  final List<Message> messages;
  final String conversationId;

  MessagesLoaded({
    required this.messages,
    required this.conversationId,
  });
}

class MessageSent extends MessagingState {
  final Message message;

  MessageSent({required this.message});
}

class MessagingError extends MessagingState {
  final String message;

  MessagingError({required this.message});
}

// BLoC
class MessagingBloc extends Bloc<MessagingEvent, MessagingState> {
  final MessagingRepository messagingRepository;

  MessagingBloc({required this.messagingRepository}) : super(MessagingInitial()) {
    on<LoadConversationsEvent>(_onLoadConversations);
    on<LoadMessagesEvent>(_onLoadMessages);
    on<SendMessageEvent>(_onSendMessage);
    on<MarkConversationAsReadEvent>(_onMarkConversationAsRead);
  }

  Future<void> _onLoadConversations(LoadConversationsEvent event, Emitter<MessagingState> emit) async {
    emit(MessagingLoading());
    try {
      final conversations = await messagingRepository.getConversations(userId: event.userId);
      emit(ConversationsLoaded(conversations: conversations));
    } catch (e) {
      emit(MessagingError(message: e.toString()));
    }
  }

  Future<void> _onLoadMessages(LoadMessagesEvent event, Emitter<MessagingState> emit) async {
    emit(MessagingLoading());
    try {
      final messages = await messagingRepository.getMessages(conversationId: event.conversationId);
      emit(MessagesLoaded(messages: messages, conversationId: event.conversationId));
    } catch (e) {
      emit(MessagingError(message: e.toString()));
    }
  }

  Future<void> _onSendMessage(SendMessageEvent event, Emitter<MessagingState> emit) async {
    try {
      final message = await messagingRepository.sendMessage(
        senderId: event.senderId,
        receiverId: event.receiverId,
        content: event.content,
        attachment: event.attachment,
      );
      emit(MessageSent(message: message));
    } catch (e) {
      emit(MessagingError(message: e.toString()));
    }
  }

  Future<void> _onMarkConversationAsRead(MarkConversationAsReadEvent event, Emitter<MessagingState> emit) async {
    try {
      await messagingRepository.markConversationAsRead(
        conversationId: event.conversationId,
        userId: event.userId,
      );
      // No need to emit a new state here as the UI will probably reload messages anyway
    } catch (e) {
      emit(MessagingError(message: e.toString()));
    }
  }
}