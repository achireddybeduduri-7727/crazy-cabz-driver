import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:driver_app/core/services/storage_service.dart';

void main() {
  group('StorageService', () {
    setUpAll(() async {
      // Set up SharedPreferences mock instance
      SharedPreferences.setMockInitialValues({});
    });

    setUp(() async {
      await StorageService.init();
    });

    group('Basic Storage Operations', () {
      test('should store and retrieve string values', () async {
        const key = 'test_key';
        const value = 'test_value';

        await StorageService.storeString(key, value);
        final result = StorageService.getString(key);

        expect(result, equals(value));
      });

      test('should store and retrieve bool values', () async {
        const key = 'test_bool_key';
        const value = true;

        await StorageService.storeBool(key, value);
        final result = StorageService.getBool(key);

        expect(result, equals(value));
      });

      test('should store and retrieve int values', () async {
        const key = 'test_int_key';
        const value = 42;

        await StorageService.storeInt(key, value);
        final result = StorageService.getInt(key);

        expect(result, equals(value));
      });

      test('should store and retrieve double values', () async {
        const key = 'test_double_key';
        const value = 3.14;

        await StorageService.storeDouble(key, value);
        final result = StorageService.getDouble(key);

        expect(result, equals(value));
      });
    });

    group('Chat Storage Operations', () {
      test('should save and retrieve chat messages', () async {
        const rideId = 'ride_123';
        final message = {
          'id': 'msg_1',
          'rideId': rideId,
          'fromUserId': 'user_1',
          'toUserId': 'user_2',
          'message': 'Hello, driver!',
          'type': 'text',
          'timestamp': '2024-01-01T12:00:00.000Z',
          'isRead': false,
        };

        await StorageService.saveChatMessage(message);
        final result = await StorageService.getChatHistory(rideId);

        expect(result, hasLength(1));
        expect(result[0]['id'], equals('msg_1'));
        expect(result[0]['message'], equals('Hello, driver!'));
      });

      test(
        'should retrieve empty chat history for non-existent ride',
        () async {
          const rideId = 'non_existent_ride';

          final result = await StorageService.getChatHistory(rideId);

          expect(result, isEmpty);
        },
      );

      test('should clear chat history', () async {
        const rideId = 'ride_to_clear';
        final message = {
          'id': 'msg_1',
          'rideId': rideId,
          'fromUserId': 'user_1',
          'toUserId': 'user_2',
          'message': 'Test message',
          'type': 'text',
          'timestamp': '2024-01-01T12:00:00.000Z',
          'isRead': false,
        };

        // Add a message first
        await StorageService.saveChatMessage(message);

        // Verify it exists
        var result = await StorageService.getChatHistory(rideId);
        expect(result, hasLength(1));

        // Clear and verify it's gone
        await StorageService.clearChatHistory(rideId);
        result = await StorageService.getChatHistory(rideId);
        expect(result, isEmpty);
      });
    });

    group('Error Handling', () {
      test('should return null for non-existent string keys', () {
        const key = 'non_existent_key';
        final result = StorageService.getString(key);
        expect(result, isNull);
      });

      test('should return null for non-existent bool keys', () {
        const key = 'non_existent_bool_key';
        final result = StorageService.getBool(key);
        expect(result, isNull);
      });

      test('should return null for non-existent int keys', () {
        const key = 'non_existent_int_key';
        final result = StorageService.getInt(key);
        expect(result, isNull);
      });

      test('should return null for non-existent double keys', () {
        const key = 'non_existent_double_key';
        final result = StorageService.getDouble(key);
        expect(result, isNull);
      });
    });

    group('Remove Operations', () {
      test('should remove specific keys', () async {
        const key = 'key_to_remove';
        const value = 'value_to_remove';

        // Store a value first
        await StorageService.storeString(key, value);
        expect(StorageService.getString(key), equals(value));

        // Remove it
        await StorageService.remove(key);
        expect(StorageService.getString(key), isNull);
      });
    });
  });
}
