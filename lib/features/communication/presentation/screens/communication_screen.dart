import 'package:flutter/material.dart';
import '../../../../core/services/communication_service.dart';
import '../../../../shared/models/ride_model.dart';
import '../../../../shared/models/driver_model.dart';
import 'chat_screen.dart';
import 'dart:async';

class CommunicationScreen extends StatefulWidget {
  final DriverModel driver;

  const CommunicationScreen({super.key, required this.driver});

  @override
  State<CommunicationScreen> createState() => _CommunicationScreenState();
}

class _CommunicationScreenState extends State<CommunicationScreen> {
  final CommunicationService _communicationService = CommunicationService();
  List<ActiveChat> _activeChats = [];
  StreamSubscription<ChatMessage>? _messageSubscription;
  StreamSubscription<CallEvent>? _callSubscription;
  StreamSubscription<ConnectionStatus>? _connectionSubscription;
  bool _isConnected = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeCommunication();
  }

  Future<void> _initializeCommunication() async {
    try {
      await _communicationService.initialize(userId: widget.driver.id);

      setState(() {
        _isConnected = _communicationService.isConnected;
      });

      // Listen to connection status
      _connectionSubscription = _communicationService.connectionStream.listen((
        status,
      ) {
        setState(() {
          _isConnected = status == ConnectionStatus.connected;
        });
      });

      // Listen to new messages to update chat list
      _messageSubscription = _communicationService.messageStream.listen((
        message,
      ) {
        _handleNewMessage(message);
      });

      // Listen to call events
      _callSubscription = _communicationService.callStream.listen((callEvent) {
        _handleCallEvent(callEvent);
      });

      await _loadActiveChats();
    } catch (e) {
      print('Error initializing communication: $e');
      _showErrorSnackBar('Failed to initialize communication');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadActiveChats() async {
    // In a real app, this would fetch from your backend API
    // For now, we'll create mock data or load from local storage
    final mockChats = [
      ActiveChat(
        rideId: 'ride_001',
        customerId: 'customer_001',
        customerName: 'John Smith',
        customerPhone: '+1234567890',
        lastMessage: 'I\'m waiting at the pickup location',
        lastMessageTime: DateTime.now().subtract(const Duration(minutes: 5)),
        unreadCount: 2,
        isActive: true,
        ride: RideModel(
          id: 'ride_001',
          driverId: widget.driver.id,
          employeeName: 'John Smith',
          employeePhone: '+1234567890',
          pickupLocation: LocationInfo(
            address: '123 Main St, City',
            latitude: 40.7128,
            longitude: -74.0060,
          ),
          dropLocation: LocationInfo(
            address: '456 Oak Ave, City',
            latitude: 40.7589,
            longitude: -73.9851,
          ),
          fare: 25.50,
          status: 'assigned',
          createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
        ),
      ),
      ActiveChat(
        rideId: 'ride_002',
        customerId: 'customer_002',
        customerName: 'Sarah Johnson',
        customerPhone: '+1987654321',
        lastMessage: 'Thank you for the ride!',
        lastMessageTime: DateTime.now().subtract(const Duration(hours: 2)),
        unreadCount: 0,
        isActive: false,
        ride: RideModel(
          id: 'ride_002',
          driverId: widget.driver.id,
          employeeName: 'Sarah Johnson',
          employeePhone: '+1987654321',
          pickupLocation: LocationInfo(
            address: '789 Pine St, City',
            latitude: 40.7282,
            longitude: -74.0776,
          ),
          dropLocation: LocationInfo(
            address: '321 Cedar Rd, City',
            latitude: 40.7614,
            longitude: -73.9776,
          ),
          fare: 18.75,
          status: 'completed',
          createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        ),
      ),
    ];

    setState(() {
      _activeChats = mockChats;
    });
  }

  void _handleNewMessage(ChatMessage message) {
    setState(() {
      final chatIndex = _activeChats.indexWhere(
        (chat) => chat.rideId == message.rideId,
      );
      if (chatIndex != -1) {
        _activeChats[chatIndex] = _activeChats[chatIndex].copyWith(
          lastMessage: message.message,
          lastMessageTime: message.timestamp,
          unreadCount: message.fromUserId != widget.driver.id
              ? _activeChats[chatIndex].unreadCount + 1
              : _activeChats[chatIndex].unreadCount,
        );
        // Move to top of list
        final chat = _activeChats.removeAt(chatIndex);
        _activeChats.insert(0, chat);
      }
    });
  }

  void _handleCallEvent(CallEvent callEvent) {
    if (callEvent.type == CallEventType.started &&
        callEvent.toUserId == widget.driver.id) {
      // Show incoming call notification
      _showIncomingCallDialog(callEvent);
    }
  }

  void _showIncomingCallDialog(CallEvent callEvent) {
    final chat = _activeChats.firstWhere(
      (chat) => chat.rideId == callEvent.rideId,
      orElse: () => ActiveChat(
        rideId: callEvent.rideId,
        customerId: callEvent.fromUserId,
        customerName: 'Unknown Customer',
        customerPhone: '',
        lastMessage: '',
        lastMessageTime: DateTime.now(),
        unreadCount: 0,
        isActive: true,
        ride: RideModel(
          id: callEvent.rideId,
          driverId: widget.driver.id,
          employeeName: 'Unknown Customer',
          employeePhone: '',
          pickupLocation: LocationInfo(address: '', latitude: 0, longitude: 0),
          dropLocation: LocationInfo(address: '', latitude: 0, longitude: 0),
          fare: 0,
          status: 'assigned',
          createdAt: DateTime.now(),
        ),
      ),
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Incoming Call'),
        content: Text('${chat.customerName} is calling you'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Decline call logic would go here
            },
            child: const Text('Decline'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await _communicationService.answerCall(
                  rideId: callEvent.rideId,
                  fromUserId: callEvent.fromUserId,
                );
              } catch (e) {
                _showErrorSnackBar('Failed to answer call');
              }
            },
            child: const Text('Answer'),
          ),
        ],
      ),
    );
  }

  void _openChat(ActiveChat chat) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          ride: chat.ride,
          driver: widget.driver,
          customerId: chat.customerId,
          customerName: chat.customerName,
        ),
      ),
    ).then((_) {
      // Mark messages as read when returning from chat
      _communicationService.markMessagesAsRead(chat.rideId);
      setState(() {
        final chatIndex = _activeChats.indexWhere(
          (c) => c.rideId == chat.rideId,
        );
        if (chatIndex != -1) {
          _activeChats[chatIndex] = _activeChats[chatIndex].copyWith(
            unreadCount: 0,
          );
        }
      });
    });
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
        title: const Text('Communication'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _isConnected ? Colors.green : Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _isConnected ? 'Online' : 'Offline',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _activeChats.isEmpty
          ? _buildEmptyState()
          : _buildChatList(),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No active chats',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'Start accepting rides to communicate with customers',
            style: TextStyle(fontSize: 14, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildChatList() {
    return ListView.builder(
      padding: const EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 100, // Extra padding to ensure content is not hidden by bottom nav
      ),
      itemCount: _activeChats.length,
      itemBuilder: (context, index) {
        final chat = _activeChats[index];
        return ChatListItem(chat: chat, onTap: () => _openChat(chat));
      },
    );
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _callSubscription?.cancel();
    _connectionSubscription?.cancel();
    super.dispose();
  }
}

class ChatListItem extends StatelessWidget {
  final ActiveChat chat;
  final VoidCallback onTap;

  const ChatListItem({super.key, required this.chat, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.blue[100],
              child: Text(
                chat.customerName.isNotEmpty
                    ? chat.customerName[0].toUpperCase()
                    : 'C',
                style: TextStyle(
                  color: Colors.blue[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (chat.isActive)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                chat.customerName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (chat.unreadCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  chat.unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ride: ${chat.rideId}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              chat.lastMessage.isNotEmpty
                  ? chat.lastMessage
                  : 'No messages yet',
              style: TextStyle(
                color: chat.unreadCount > 0 ? Colors.black : Colors.grey[600],
                fontWeight: chat.unreadCount > 0
                    ? FontWeight.w500
                    : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _formatTime(chat.lastMessageTime),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _getStatusColor(chat.ride.status),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                chat.ride.status.toUpperCase(),
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
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else {
      return '${timestamp.day}/${timestamp.month}';
    }
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
}

class ActiveChat {
  final String rideId;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final bool isActive;
  final RideModel ride;

  ActiveChat({
    required this.rideId,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
    required this.isActive,
    required this.ride,
  });

  ActiveChat copyWith({
    String? rideId,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? lastMessage,
    DateTime? lastMessageTime,
    int? unreadCount,
    bool? isActive,
    RideModel? ride,
  }) {
    return ActiveChat(
      rideId: rideId ?? this.rideId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      isActive: isActive ?? this.isActive,
      ride: ride ?? this.ride,
    );
  }
}
