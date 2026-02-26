import 'package:flutter_test/flutter_test.dart';
import 'package:driver_app/core/services/communication_service.dart';

void main() {
  group('CommunicationService', () {
    late CommunicationService communicationService;

    setUp(() {
      communicationService = CommunicationService();
    });

    group('Singleton Pattern', () {
      test('should return the same instance', () {
        final instance1 = CommunicationService();
        final instance2 = CommunicationService();

        expect(instance1, equals(instance2));
      });
    });

    group('Stream Controllers', () {
      test('should provide message stream', () {
        expect(communicationService.messageStream, isNotNull);
        expect(communicationService.messageStream, isA<Stream<ChatMessage>>());
      });

      test('should provide call stream', () {
        expect(communicationService.callStream, isNotNull);
        expect(communicationService.callStream, isA<Stream<CallEvent>>());
      });

      test('should provide connection stream', () {
        expect(communicationService.connectionStream, isNotNull);
        expect(
          communicationService.connectionStream,
          isA<Stream<ConnectionStatus>>(),
        );
      });
    });

    group('Connection Status', () {
      test('should start with disconnected status', () {
        expect(communicationService.isConnected, isFalse);
      });
    });

    group('Data Models', () {
      test('ChatMessage should serialize to/from JSON correctly', () {
        final originalMessage = ChatMessage(
          id: 'msg_1',
          rideId: 'ride_123',
          fromUserId: 'user_1',
          toUserId: 'user_2',
          message: 'Hello, driver!',
          type: MessageType.text,
          timestamp: DateTime(2024, 1, 1, 12, 0, 0),
          isRead: false,
        );

        final json = originalMessage.toJson();
        final deserializedMessage = ChatMessage.fromJson(json);

        expect(deserializedMessage.id, equals(originalMessage.id));
        expect(deserializedMessage.rideId, equals(originalMessage.rideId));
        expect(
          deserializedMessage.fromUserId,
          equals(originalMessage.fromUserId),
        );
        expect(deserializedMessage.toUserId, equals(originalMessage.toUserId));
        expect(deserializedMessage.message, equals(originalMessage.message));
        expect(deserializedMessage.type, equals(originalMessage.type));
        expect(deserializedMessage.isRead, equals(originalMessage.isRead));
      });

      test('CallEvent should serialize from JSON correctly', () {
        final json = {
          'type': 'started',
          'fromUserId': 'user_1',
          'toUserId': 'user_2',
          'rideId': 'ride_123',
          'timestamp': '2024-01-01T12:00:00.000Z',
        };

        final callEvent = CallEvent.fromJson(json);

        expect(callEvent.type, equals(CallEventType.started));
        expect(callEvent.fromUserId, equals('user_1'));
        expect(callEvent.toUserId, equals('user_2'));
        expect(callEvent.rideId, equals('ride_123'));
      });
    });

    group('Message Types', () {
      test('should handle text message type', () {
        const messageType = MessageType.text;
        expect(messageType.toString(), contains('text'));
      });

      test('should handle location message type', () {
        const messageType = MessageType.location;
        expect(messageType.toString(), contains('location'));
      });

      test('should handle system message type', () {
        const messageType = MessageType.system;
        expect(messageType.toString(), contains('system'));
      });
    });

    group('Call Event Types', () {
      test('should handle started call event', () {
        const eventType = CallEventType.started;
        expect(eventType.toString(), contains('started'));
      });

      test('should handle answered call event', () {
        const eventType = CallEventType.answered;
        expect(eventType.toString(), contains('answered'));
      });

      test('should handle ended call event', () {
        const eventType = CallEventType.ended;
        expect(eventType.toString(), contains('ended'));
      });

      test('should handle joined call event', () {
        const eventType = CallEventType.joined;
        expect(eventType.toString(), contains('joined'));
      });

      test('should handle declined call event', () {
        const eventType = CallEventType.declined;
        expect(eventType.toString(), contains('declined'));
      });
    });

    group('Connection Status Types', () {
      test('should handle connected status', () {
        const status = ConnectionStatus.connected;
        expect(status.toString(), contains('connected'));
      });

      test('should handle disconnected status', () {
        const status = ConnectionStatus.disconnected;
        expect(status.toString(), contains('disconnected'));
      });

      test('should handle connecting status', () {
        const status = ConnectionStatus.connecting;
        expect(status.toString(), contains('connecting'));
      });

      test('should handle error status', () {
        const status = ConnectionStatus.error;
        expect(status.toString(), contains('error'));
      });
    });

    group('Error Handling', () {
      test(
        'should throw exception when sending message without connection',
        () async {
          expect(
            () async => await communicationService.sendMessage(
              rideId: 'ride_123',
              toUserId: 'user_2',
              message: 'Test message',
            ),
            throwsException,
          );
        },
      );

      test('should throw exception when starting call without Agora', () async {
        expect(
          () async => await communicationService.startCall(
            rideId: 'ride_123',
            toUserId: 'user_2',
          ),
          throwsException,
        );
      });

      test(
        'should throw exception when answering call without Agora',
        () async {
          expect(
            () async => await communicationService.answerCall(
              rideId: 'ride_123',
              fromUserId: 'user_1',
            ),
            throwsException,
          );
        },
      );
    });

    group('Cleanup', () {
      test('should dispose resources properly', () {
        // This tests that dispose doesn't throw an exception
        expect(() => communicationService.dispose(), returnsNormally);
      });
    });

    group('Chat History', () {
      test('should handle error when storage is not initialized', () async {
        try {
          final history = await communicationService.getChatHistory(
            'non_existent_ride',
          );
          expect(history, isEmpty);
        } catch (e) {
          // Expected behavior when storage is not initialized
          expect(e.toString(), contains('not been initialized'));
        }
      });
    });

    group('Current User', () {
      test('should return null when not initialized', () {
        expect(communicationService.currentUserId, isNull);
      });
    });
  });
}
