import 'dart:async';

/// Stubbed NotificationService - notifications disabled for now
/// Will be implemented when the business/company app is ready
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Stream controllers for different notification types (stubbed)
  final StreamController<Map<String, dynamic>> _rideAssignmentController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _rideUpdateController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _paymentController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _systemController =
      StreamController<Map<String, dynamic>>.broadcast();

  // Getters for streams
  Stream<Map<String, dynamic>> get rideAssignmentStream =>
      _rideAssignmentController.stream;
  Stream<Map<String, dynamic>> get rideUpdateStream =>
      _rideUpdateController.stream;
  Stream<Map<String, dynamic>> get paymentStream => _paymentController.stream;
  Stream<Map<String, dynamic>> get systemStream => _systemController.stream;
  Stream<Map<String, dynamic>> get systemAlertStream =>
      _systemController.stream;

  // Stubbed properties and methods
  String? get fcmToken => null;

  Future<void> initialize() async {
    print(
      'NotificationService: Stubbed initialization (notifications disabled)',
    );
  }

  Future<bool> areNotificationsEnabled() async {
    return false;
  }

  Future<bool> requestPermissions() async {
    return false;
  }

  Future<void> showRideAssignmentNotification({
    required String rideId,
    required String customerName,
    required String pickupAddress,
    required double estimatedEarnings,
  }) async {
    print('NotificationService: Stubbed ride assignment notification');
    print('Ride ID: $rideId, Customer: $customerName');
    print(
      'Pickup: $pickupAddress, Earnings: \$${estimatedEarnings.toStringAsFixed(2)}',
    );
  }

  Future<String?> getFCMToken() async {
    return null;
  }

  Future<void> subscribeToTopic(String topic) async {
    print('NotificationService: Stubbed topic subscription');
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    print('NotificationService: Stubbed topic unsubscription');
  }

  void dispose() {
    _rideAssignmentController.close();
    _rideUpdateController.close();
    _paymentController.close();
    _systemController.close();
  }
}
