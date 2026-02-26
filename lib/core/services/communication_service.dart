import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'storage_service.dart';

class CommunicationService {
  static final CommunicationService _instance =
      CommunicationService._internal();
  factory CommunicationService() => _instance;
  CommunicationService._internal();

  // Socket.IO client for real-time chat
  io.Socket? _socket;

  // Agora RTC Engine for voice calls
  RtcEngine? _agoraEngine;

  // Stream controllers for chat messages
  final StreamController<ChatMessage> _messageController =
      StreamController<ChatMessage>.broadcast();
  final StreamController<CallEvent> _callController =
      StreamController<CallEvent>.broadcast();
  final StreamController<ConnectionStatus> _connectionController =
      StreamController<ConnectionStatus>.broadcast();

  // Public streams
  Stream<ChatMessage> get messageStream => _messageController.stream;
  Stream<CallEvent> get callStream => _callController.stream;
  Stream<ConnectionStatus> get connectionStream => _connectionController.stream;

  // Connection status
  bool _isConnected = false;
  bool _isInitialized = false;
  String? _currentUserId;
  String? _currentRideId;

  // Agora configuration
  static const String agoraAppId =
      "YOUR_AGORA_APP_ID"; // Replace with your Agora App ID
  static const String agoraToken =
      "YOUR_AGORA_TOKEN"; // Replace with your Agora Token

  /// Initialize the communication service
  Future<void> initialize({required String userId}) async {
    if (_isInitialized) return;

    _currentUserId = userId;
    await _initializeSocket();
    await _initializeAgora();

    _isInitialized = true;
  }

  /// Initialize Socket.IO connection
  Future<void> _initializeSocket() async {
    try {
      _socket = io.io('ws://your-socket-server.com', <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
        'query': {'userId': _currentUserId},
      });

      _socket?.onConnect((_) {
        print('Connected to chat server');
        _isConnected = true;
        _connectionController.add(ConnectionStatus.connected);
      });

      _socket?.onDisconnect((_) {
        print('Disconnected from chat server');
        _isConnected = false;
        _connectionController.add(ConnectionStatus.disconnected);
      });

      _socket?.on('message', (data) {
        final message = ChatMessage.fromJson(data);
        _messageController.add(message);
      });

      _socket?.on('call_request', (data) {
        final callEvent = CallEvent.fromJson(data);
        _callController.add(callEvent);
      });

      _socket?.on('call_ended', (data) {
        final callEvent = CallEvent(
          type: CallEventType.ended,
          fromUserId: data['fromUserId'],
          toUserId: data['toUserId'],
          rideId: data['rideId'],
          timestamp: DateTime.now(),
        );
        _callController.add(callEvent);
      });

      _socket?.connect();
    } catch (e) {
      print('Error initializing socket: $e');
      _connectionController.add(ConnectionStatus.error);
    }
  }

  /// Initialize Agora RTC Engine
  Future<void> _initializeAgora() async {
    try {
      if (agoraAppId.isEmpty || agoraAppId == "YOUR_AGORA_APP_ID") {
        print(
          'Warning: Agora App ID not configured. Voice calling will not work.',
        );
        return;
      }

      _agoraEngine = createAgoraRtcEngine();
      await _agoraEngine!.initialize(RtcEngineContext(appId: agoraAppId));

      // Enable audio only mode for calls
      await _agoraEngine!.enableAudio();
      await _agoraEngine!.setChannelProfile(
        ChannelProfileType.channelProfileCommunication,
      );
      await _agoraEngine!.setClientRole(
        role: ClientRoleType.clientRoleBroadcaster,
      );

      // Set up event handlers
      _agoraEngine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            print('Joined call channel: ${connection.channelId}');
            _callController.add(
              CallEvent(
                type: CallEventType.joined,
                fromUserId: _currentUserId!,
                toUserId: '',
                rideId: _currentRideId ?? '',
                timestamp: DateTime.now(),
              ),
            );
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            print('User joined call: $remoteUid');
          },
          onUserOffline:
              (
                RtcConnection connection,
                int remoteUid,
                UserOfflineReasonType reason,
              ) {
                print('User left call: $remoteUid');
              },
          onLeaveChannel: (RtcConnection connection, RtcStats stats) {
            print('Left call channel');
            _callController.add(
              CallEvent(
                type: CallEventType.ended,
                fromUserId: _currentUserId!,
                toUserId: '',
                rideId: _currentRideId ?? '',
                timestamp: DateTime.now(),
              ),
            );
          },
        ),
      );
    } catch (e) {
      print('Error initializing Agora: $e');
    }
  }

  /// Send a chat message
  Future<void> sendMessage({
    required String rideId,
    required String toUserId,
    required String message,
    MessageType type = MessageType.text,
  }) async {
    if (!_isConnected || _socket == null) {
      throw Exception('Not connected to chat server');
    }

    final chatMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      rideId: rideId,
      fromUserId: _currentUserId!,
      toUserId: toUserId,
      message: message,
      type: type,
      timestamp: DateTime.now(),
      isRead: false,
    );

    _socket!.emit('send_message', chatMessage.toJson());

    // Add to local stream for immediate UI update
    _messageController.add(chatMessage);
  }

  /// Start a voice call
  Future<void> startCall({
    required String rideId,
    required String toUserId,
  }) async {
    if (_agoraEngine == null) {
      throw Exception('Voice calling not available - Agora not initialized');
    }

    // Check microphone permission
    final micPermission = await Permission.microphone.request();
    if (!micPermission.isGranted) {
      throw Exception('Microphone permission required for voice calls');
    }

    _currentRideId = rideId;

    // Notify other user about call request
    if (_socket != null && _isConnected) {
      _socket!.emit('call_request', {
        'rideId': rideId,
        'fromUserId': _currentUserId,
        'toUserId': toUserId,
        'timestamp': DateTime.now().toIso8601String(),
      });
    }

    // Join Agora channel
    final channelName = 'ride_$rideId';
    await _agoraEngine!.joinChannel(
      token: agoraToken.isEmpty ? "" : agoraToken,
      channelId: channelName,
      uid: int.parse(_currentUserId!.hashCode.toString().substring(0, 8)),
      options: const ChannelMediaOptions(),
    );

    _callController.add(
      CallEvent(
        type: CallEventType.started,
        fromUserId: _currentUserId!,
        toUserId: toUserId,
        rideId: rideId,
        timestamp: DateTime.now(),
      ),
    );
  }

  /// Answer an incoming call
  Future<void> answerCall({
    required String rideId,
    required String fromUserId,
  }) async {
    if (_agoraEngine == null) {
      throw Exception('Voice calling not available - Agora not initialized');
    }

    // Check microphone permission
    final micPermission = await Permission.microphone.request();
    if (!micPermission.isGranted) {
      throw Exception('Microphone permission required for voice calls');
    }

    _currentRideId = rideId;

    // Join Agora channel
    final channelName = 'ride_$rideId';
    await _agoraEngine!.joinChannel(
      token: agoraToken.isEmpty ? "" : agoraToken,
      channelId: channelName,
      uid: int.parse(_currentUserId!.hashCode.toString().substring(0, 8)),
      options: const ChannelMediaOptions(),
    );
  }

  /// End current call
  Future<void> endCall() async {
    if (_agoraEngine == null) return;

    await _agoraEngine!.leaveChannel();

    if (_socket != null && _isConnected && _currentRideId != null) {
      _socket!.emit('call_ended', {
        'rideId': _currentRideId,
        'fromUserId': _currentUserId,
        'timestamp': DateTime.now().toIso8601String(),
      });
    }

    _currentRideId = null;
  }

  /// Mute/unmute microphone
  Future<void> toggleMute() async {
    if (_agoraEngine == null) return;

    // This will be handled by the UI state, Agora handles the actual muting
    await _agoraEngine!.muteLocalAudioStream(true);
  }

  /// Get chat history for a ride
  Future<List<ChatMessage>> getChatHistory(String rideId) async {
    try {
      final history = await StorageService.getChatHistory(rideId);
      return history.map((json) => ChatMessage.fromJson(json)).toList();
    } catch (e) {
      print('Error getting chat history: $e');
      return [];
    }
  }

  /// Mark messages as read
  Future<void> markMessagesAsRead(String rideId) async {
    if (_socket != null && _isConnected) {
      _socket!.emit('mark_read', {'rideId': rideId, 'userId': _currentUserId});
    }
  }

  /// Get connection status
  bool get isConnected => _isConnected;

  /// Get current user ID
  String? get currentUserId => _currentUserId;

  /// Disconnect and cleanup
  Future<void> disconnect() async {
    _socket?.disconnect();
    await _agoraEngine?.leaveChannel();
    await _agoraEngine?.release();

    _isConnected = false;
    _isInitialized = false;
    _currentUserId = null;
    _currentRideId = null;
  }

  /// Dispose resources
  void dispose() {
    _messageController.close();
    _callController.close();
    _connectionController.close();
  }
}

// Data models
class ChatMessage {
  final String id;
  final String rideId;
  final String fromUserId;
  final String toUserId;
  final String message;
  final MessageType type;
  final DateTime timestamp;
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.rideId,
    required this.fromUserId,
    required this.toUserId,
    required this.message,
    required this.type,
    required this.timestamp,
    required this.isRead,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? '',
      rideId: json['rideId'] ?? '',
      fromUserId: json['fromUserId'] ?? '',
      toUserId: json['toUserId'] ?? '',
      message: json['message'] ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.toString() == 'MessageType.${json['type']}',
        orElse: () => MessageType.text,
      ),
      timestamp: DateTime.parse(
        json['timestamp'] ?? DateTime.now().toIso8601String(),
      ),
      isRead: json['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rideId': rideId,
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'message': message,
      'type': type.toString().split('.').last,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
    };
  }
}

class CallEvent {
  final CallEventType type;
  final String fromUserId;
  final String toUserId;
  final String rideId;
  final DateTime timestamp;

  CallEvent({
    required this.type,
    required this.fromUserId,
    required this.toUserId,
    required this.rideId,
    required this.timestamp,
  });

  factory CallEvent.fromJson(Map<String, dynamic> json) {
    return CallEvent(
      type: CallEventType.values.firstWhere(
        (e) => e.toString() == 'CallEventType.${json['type']}',
        orElse: () => CallEventType.started,
      ),
      fromUserId: json['fromUserId'] ?? '',
      toUserId: json['toUserId'] ?? '',
      rideId: json['rideId'] ?? '',
      timestamp: DateTime.parse(
        json['timestamp'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}

enum MessageType { text, location, system }

enum CallEventType { started, answered, ended, joined, declined }

enum ConnectionStatus { connected, disconnected, connecting, error }
