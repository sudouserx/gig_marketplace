import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({Key? key}) : super(key: key);

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final Random _random = Random();
  
  WebSocketChannel? _channel;
  Timer? _connectionTimer;
  Timer? _retryTimer;
  Timer? _heartbeatTimer;
  
  bool _isConnected = false;
  bool _isConnecting = true;
  bool _isLoading = false;
  int _connectionAttempts = 0;
  final int _maxConnectionAttempts = 5;
  final List<String> _messageQueue = [];

  @override
  void initState() {
    super.initState();
    
    // Add welcome messages
    _messages.addAll([
      ChatMessage(
        text: "Hi there! I'm your job assistant. Ask me anything about job applications, interviews, or career advice!",
        isUser: false,
        timestamp: DateTime.now(),
      ),
      ChatMessage(
        text: "Establishing secure connection... This might take a moment on first launch.",
        isUser: false,
        timestamp: DateTime.now(),
        isSystem: true,
      ),
    ]);
    
    _initializeConnection();
  }

  void _initializeConnection() {
    setState(() {
      _isConnecting = true;
      _isConnected = false;
    });
    
    _connectWebSocket();

    // Schedule a check after 4 minutes to see if we're still trying to connect
    Future.delayed(const Duration(minutes: 4), () {
      if (mounted && _isConnecting && !_isConnected) {
        _showSystemMessage(
          "Still trying to connect. This is taking longer than expected. You can try asking a question anyway - I'll queue it until connected.",
          false
        );
      }
    });
  }

  void _connectWebSocket() {
    _cancelTimers();
    _connectionAttempts++;
    print("Attempting connection $_connectionAttempts...");

    // Connection attempt timeout
    _connectionTimer = Timer(const Duration(seconds: 25), () {
      if (!_isConnected && mounted) {
        _handleConnectionError('Connection timeout');
        _channel?.sink.close();
      }
    });

    try {
      _channel = WebSocketChannel.connect(
        Uri.parse('ws://retrieval-augmented-generation-chatbot.onrender.com/ws/chat'),
      );

      _channel!.stream.listen(
        (message) {
          print("Received message: $message");
          _handleIncomingMessage(message);
          if (!_isConnected) {
            _handleSuccessfulConnection();
          }
        },
        onDone: _handleDisconnect,
        onError: (error) => _handleConnectionError(error.toString()),
      );
    } catch (e) {
      print("WebSocket connection exception: $e");
      _handleConnectionError(e.toString());
    }
  }

  void _handleSuccessfulConnection() {
    _cancelTimers();
    if (!mounted) return;
    
    setState(() {
      _isConnected = true;
      _isConnecting = false;
      _connectionAttempts = 0;
    });
    
    _showSystemMessage("Connection established! I'm ready to help you.", false);
    _startHeartbeat();
    _processMessageQueue();
  }

  void _handleDisconnect() {
    if (!mounted) return;
    print("WebSocket connection done.");
    _cancelTimers();
    
    setState(() {
      _isConnected = false;
      _isConnecting = false;
    });
    
    if (_connectionAttempts <= _maxConnectionAttempts * 2) {
      _showSystemMessage("Connection closed. Reconnecting...", true);
      _scheduleRetry();
    } else {
      _showSystemMessage("I'm having trouble connecting to the server. You can still type your questions and I'll queue them until I'm connected.", false);
      _scheduleBackgroundRetry();
    }
  }

  void _handleConnectionError(String error) {
    if (!mounted) return;
    print("WebSocket error: $error");
    _cancelTimers();
    
    setState(() {
      _isConnected = false;
      _isConnecting = false;
    });
    
    if (_connectionAttempts <= _maxConnectionAttempts) {
      _showSystemMessage("Connection issue. Retrying...", true);
      _scheduleRetry();
    } else {
      _showSystemMessage("I'm having trouble connecting to the server. You can still type your questions and I'll queue them until I'm connected.", false);
      _scheduleBackgroundRetry();
    }
  }

  void _scheduleRetry() {
    final baseDelay = pow(2, _connectionAttempts).clamp(1, 30).toInt();
    final jitter = _random.nextInt(10);
    final delay = Duration(seconds: baseDelay + jitter);
    
    _retryTimer = Timer(delay, () {
      if (mounted && !_isConnected) {
        _connectWebSocket();
      }
    });
  }

  void _scheduleBackgroundRetry() {
    _retryTimer = Timer(const Duration(minutes: 4), () {
      if (mounted) {
        setState(() => _connectionAttempts = 0);
        _initializeConnection();
      }
    });
  }

  void _startHeartbeat() {
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 25), (timer) {
      if (_isConnected && _channel != null) {
        try {
          _channel?.sink.add(jsonEncode({'type': 'heartbeat'}));
        } catch (e) {
          print("Error sending heartbeat: $e");
          _handleDisconnect();
        }
      }
    });
  }

  void _processMessageQueue() {
    while (_messageQueue.isNotEmpty && _isConnected) {
      final message = _messageQueue.removeAt(0);
      _sendToWebSocket(message);
    }
  }

  void _showSystemMessage(String text, bool isWarning) {
    if (!mounted) return;
    
    // Remove duplicate system messages to keep the chat clean
    _messages.removeWhere((msg) => 
      msg.isSystem && 
      (msg.text.contains("Establishing secure connection...") ||
       msg.text.contains("Still trying to connect.") ||
       msg.text.contains("Connection closed. Reconnecting...") ||
       msg.text.contains("Connection issue. Retrying..."))
    );
    
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: false,
        timestamp: DateTime.now(),
        isSystem: true,
        warning: isWarning,
      ));
    });
    _scrollToBottom();
  }

  void _handleIncomingMessage(dynamic message) {
    if (!mounted) return;
    try {
      final Map<String, dynamic> parsedMessage = jsonDecode(message);
      if (parsedMessage.containsKey('answer')) {
        setState(() {
          _isLoading = false;
          _messages.add(
            ChatMessage(
              text: parsedMessage['answer'],
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
        });
        _scrollToBottom();
      }
    } catch (e) {
      print("Error decoding message: $e");
      setState(() {
        _isLoading = false;
        _messages.add(
          ChatMessage(
            text: "Sorry, I had trouble processing that response. Please try again in a moment.",
            isUser: false,
            timestamp: DateTime.now(),
            warning: true,
          ),
        );
      });
      _scrollToBottom();
    }
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    // Add user message to chat
    setState(() {
      _messages.add(
        ChatMessage(
          text: text,
          isUser: true,
          timestamp: DateTime.now(),
        ),
      );
      _messageController.clear();
    });

    _scrollToBottom();

    // Send or queue the message
    if (_isConnected) {
      _sendToWebSocket(text);
    } else {
      _messageQueue.add(text);
      _showSystemMessage("I'll answer your question as soon as I'm connected to the server.", false);
      
      // If not already connecting, initialize connection
      if (!_isConnecting) {
        _initializeConnection();
      }
    }
  }

  void _sendToWebSocket(String text) {
    if (!mounted) return;
    try {
      if (_channel != null && _isConnected) {
        _channel!.sink.add(jsonEncode({"question": text}));
        setState(() => _isLoading = true);
      } else {
        _messageQueue.add(text);
        _showSystemMessage("Message queued. Will send when connected", false);
        _initializeConnection();
      }
    } catch (e) {
      print("Error sending message: $e");
      _showSystemMessage("Failed to send message. I'll try again shortly.", true);
      
      // Queue the message and reconnect
      _messageQueue.add(text);
      _isConnected = false;
      _initializeConnection();
    }
  }

  void _cancelTimers() {
    _connectionTimer?.cancel();
    _retryTimer?.cancel();
    _heartbeatTimer?.cancel();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _cancelTimers();
    _messageController.dispose();
    _scrollController.dispose();
    if (_channel != null) {
      _channel!.sink.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Job Assistant'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          _connectionStatusIndicator(),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: const Color(0xFFF8F9FA),
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  return _buildChatMessageTile(_messages[index]);
                },
              ),
            ),
          ),
          if (_isLoading)
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.white,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF2A3990),
                        ),
                      ),
                    ),
                  ),
                  Text(
                    "Thinking...",
                    style: TextStyle(
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  )
                ],
              ),
            ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _connectionStatusIndicator() {
    Color statusColor;
    String tooltip;

    if (_isConnected) {
      statusColor = Colors.green;
      tooltip = "Connected";
    } else if (_isConnecting) {
      statusColor = Colors.amber;
      tooltip = "Connecting...";
    } else {
      statusColor = Colors.red;
      tooltip = "Disconnected";
    }

    return Tooltip(
      message: tooltip,
      child: Container(
        width: 12,
        height: 12,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: statusColor,
        ),
      ),
    );
  }

  Widget _buildChatMessageTile(ChatMessage message) {
    final isUser = message.isUser;
    
    // Apply different styling for system messages
    if (message.isSystem) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: message.warning ? Colors.amber.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: message.warning ? Colors.amber : Colors.grey.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                message.warning ? Icons.info_outline : Icons.system_update_alt,
                size: 16,
                color: message.warning ? Colors.amber[800] : Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message.text,
                  style: TextStyle(
                    fontSize: 13,
                    color: message.warning ? Colors.amber[800] : Colors.grey[800],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Regular chat message styling
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser)
            Container(
              margin: const EdgeInsets.only(right: 12),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF2A3990),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.smart_toy_outlined,
                color: Colors.white,
                size: 20,
              ),
            ),
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isUser ? const Color(0xFF2A3990) : Colors.white,
                    borderRadius: BorderRadius.circular(16).copyWith(
                      bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(0),
                      bottomRight: !isUser ? const Radius.circular(16) : const Radius.circular(0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      color: isUser ? Colors.white : Colors.black87,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('h:mm a').format(message.timestamp),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          if (isUser)
            Container(
              margin: const EdgeInsets.only(left: 12),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 20,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: 'Type your question...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            FloatingActionButton(
              onPressed: _sendMessage,
              backgroundColor: const Color(0xFF2A3990),
              mini: true,
              child: const Icon(Icons.send, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isSystem;
  final bool warning;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isSystem = false,
    this.warning = false,
  });
}