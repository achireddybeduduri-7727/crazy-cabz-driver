import 'package:flutter/material.dart';

import '../../../../core/services/communication_service.dart';
import '../../../../shared/models/ride_model.dart';
import '../../../../shared/models/driver_model.dart';
import 'dart:async';

class ChatScreen extends StatefulWidget {
  final RideModel ride;
  final DriverModel driver;
  final String customerId;
  final String customerName;

  const ChatScreen({
    super.key,
    required this.ride,
    required this.driver,
    required this.customerId,
    required this.customerName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final CommunicationService _communicationService = CommunicationService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<ChatMessage> _messages = [];
  StreamSubscription<ChatMessage>? _messageSubscription;
  StreamSubscription<CallEvent>? _callSubscription;
  bool _isConnected = false;
  bool _isInCall = false;
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    try {
      await _communicationService.initialize(userId: widget.driver.id);

      // Load chat history
      final history = await _communicationService.getChatHistory(
        widget.ride.id,
      );
      setState(() {
        _messages = history;
        _isConnected = _communicationService.isConnected;
      });

      // Listen to new messages
      _messageSubscription = _communicationService.messageStream.listen((
        message,
      ) {
        if (message.rideId == widget.ride.id) {
          setState(() {
            _messages.add(message);
          });
          _scrollToBottom();
        }
      });

      // Listen to call events
      _callSubscription = _communicationService.callStream.listen((callEvent) {
        if (callEvent.rideId == widget.ride.id) {
          _handleCallEvent(callEvent);
        }
      });

      _scrollToBottom();
    } catch (e) {
      print('Error initializing chat: $e');
      _showErrorSnackBar('Failed to initialize chat');
    }
  }

  void _handleCallEvent(CallEvent callEvent) {
    switch (callEvent.type) {
      case CallEventType.started:
        setState(() {
          _isInCall = true;
        });
        _showCallDialog(isIncoming: false);
        break;
      case CallEventType.answered:
        setState(() {
          _isInCall = true;
        });
        break;
      case CallEventType.ended:
        setState(() {
          _isInCall = false;
          _isMuted = false;
        });
        Navigator.of(context).pop(); // Close call dialog if open
        break;
      case CallEventType.joined:
        break;
      case CallEventType.declined:
        setState(() {
          _isInCall = false;
        });
        _showErrorSnackBar('Call declined');
        break;
    }
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

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    try {
      await _communicationService.sendMessage(
        rideId: widget.ride.id,
        toUserId: widget.customerId,
        message: message,
        type: MessageType.text,
      );

      _messageController.clear();
    } catch (e) {
      print('Error sending message: $e');
      _showErrorSnackBar('Failed to send message');
    }
  }

  Future<void> _startCall() async {
    try {
      await _communicationService.startCall(
        rideId: widget.ride.id,
        toUserId: widget.customerId,
      );
    } catch (e) {
      print('Error starting call: $e');
      _showErrorSnackBar('Failed to start call: ${e.toString()}');
    }
  }

  Future<void> _endCall() async {
    try {
      await _communicationService.endCall();
    } catch (e) {
      print('Error ending call: $e');
      _showErrorSnackBar('Failed to end call');
    }
  }

  void _showCallDialog({required bool isIncoming}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CallDialog(
        customerName: widget.customerName,
        isIncoming: isIncoming,
        isMuted: _isMuted,
        onEndCall: _endCall,
        onToggleMute: () {
          setState(() {
            _isMuted = !_isMuted;
          });
          _communicationService.toggleMute();
        },
        onAnswer: isIncoming
            ? () async {
                try {
                  await _communicationService.answerCall(
                    rideId: widget.ride.id,
                    fromUserId: widget.customerId,
                  );
                  if (mounted) {
                    Navigator.of(context).pop();
                  }
                } catch (e) {
                  _showErrorSnackBar('Failed to answer call');
                }
              }
            : null,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat with ${widget.customerName}'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isInCall ? Icons.call_end : Icons.call),
            onPressed: _isInCall ? _endCall : _startCall,
            color: _isInCall ? Colors.red : Colors.white,
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _isConnected ? Colors.green : Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Ride info banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.blue[50],
            child: Row(
              children: [
                Icon(Icons.local_taxi, color: Colors.blue[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ride ID: ${widget.ride.id}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'From: ${widget.ride.pickupLocation.address}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      Text(
                        'To: ${widget.ride.dropLocation.address}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(widget.ride.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.ride.status.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Messages list
          Expanded(
            child: _messages.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                        Text(
                          'Start a conversation with your customer',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 16,
                      bottom: 100, // Extra padding to ensure messages are not hidden by bottom nav + input field
                    ),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return MessageBubble(
                        message: message,
                        isFromDriver: message.fromUserId == widget.driver.id,
                      );
                    },
                  ),
          ),

          // Message input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton(
                    onPressed: _sendMessage,
                    backgroundColor: Colors.blue[600],
                    mini: true,
                    child: const Icon(Icons.send, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'assigned':
        return Colors.orange;
      case 'enroute':
        return Colors.blue;
      case 'arrived':
        return Colors.purple;
      case 'inprogress':
        return Colors.green;
      case 'completed':
        return Colors.grey;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _callSubscription?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isFromDriver;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isFromDriver,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isFromDriver
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isFromDriver) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[300],
              child: const Icon(Icons.person, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isFromDriver ? Colors.blue[600] : Colors.grey[200],
                borderRadius: BorderRadius.circular(20).copyWith(
                  bottomLeft: isFromDriver
                      ? const Radius.circular(20)
                      : const Radius.circular(4),
                  bottomRight: isFromDriver
                      ? const Radius.circular(4)
                      : const Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.message,
                    style: TextStyle(
                      color: isFromDriver ? Colors.white : Colors.black,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      color: isFromDriver ? Colors.white70 : Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isFromDriver) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue[100],
              child: const Icon(Icons.drive_eta, size: 16, color: Colors.blue),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.day}/${timestamp.month} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }
}

class CallDialog extends StatelessWidget {
  final String customerName;
  final bool isIncoming;
  final bool isMuted;
  final VoidCallback onEndCall;
  final VoidCallback onToggleMute;
  final VoidCallback? onAnswer;

  const CallDialog({
    super.key,
    required this.customerName,
    required this.isIncoming,
    required this.isMuted,
    required this.onEndCall,
    required this.onToggleMute,
    this.onAnswer,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.grey[600],
              child: const Icon(Icons.person, size: 40, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              customerName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isIncoming ? 'Incoming call...' : 'Calling...',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (isIncoming && onAnswer != null)
                  FloatingActionButton(
                    onPressed: onAnswer,
                    backgroundColor: Colors.green,
                    child: const Icon(Icons.call),
                  ),
                FloatingActionButton(
                  onPressed: onToggleMute,
                  backgroundColor: isMuted ? Colors.red : Colors.grey[600],
                  child: Icon(isMuted ? Icons.mic_off : Icons.mic),
                ),
                FloatingActionButton(
                  onPressed: onEndCall,
                  backgroundColor: Colors.red,
                  child: const Icon(Icons.call_end),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
