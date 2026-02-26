import 'dart:async';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_logger.dart';
import 'location_service.dart';

class GPSTrackingService {
  static final GPSTrackingService _instance = GPSTrackingService._internal();
  factory GPSTrackingService() => _instance;
  GPSTrackingService._internal();

  // Tracking state
  bool _isTracking = false;
  String? _currentRideId;
  String? _currentRouteId;
  Timer? _trackingTimer;
  StreamSubscription<Position>? _positionSubscription;

  // GPS data storage
  final List<GPSPoint> _currentRoute = [];
  final StreamController<GPSTrackingStatus> _statusController =
      StreamController<GPSTrackingStatus>.broadcast();
  final StreamController<List<GPSPoint>> _routeController =
      StreamController<List<GPSPoint>>.broadcast();

  // Getters
  bool get isTracking => _isTracking;
  String? get currentRideId => _currentRideId;
  List<GPSPoint> get currentRoute => List.unmodifiable(_currentRoute);
  Stream<GPSTrackingStatus> get statusStream => _statusController.stream;
  Stream<List<GPSPoint>> get routeStream => _routeController.stream;

  // Configuration
  static const Duration _trackingInterval = Duration(seconds: 10);
  static const double _minimumDistanceMeters = 5.0;
  static const int _maxStoredPoints = 10000;

  /// Start GPS tracking for a specific ride
  Future<bool> startTracking({
    required String rideId,
    required String routeId,
  }) async {
    try {
      AppLogger.info('Starting GPS tracking for ride: $rideId');

      if (_isTracking) {
        AppLogger.warning('GPS tracking already active');
        return false;
      }

      // Check location permissions and service
      final locationService = LocationService();
      if (!await locationService.requestLocationPermission()) {
        AppLogger.error('Location permission denied');
        _statusController.add(GPSTrackingStatus.permissionDenied);
        return false;
      }

      if (!await locationService.isLocationServiceEnabled()) {
        AppLogger.error('Location service disabled');
        _statusController.add(GPSTrackingStatus.serviceDisabled);
        return false;
      }

      // Initialize tracking
      _currentRideId = rideId;
      _currentRouteId = routeId;
      _isTracking = true;
      _currentRoute.clear();

      // Start position tracking
      await _startPositionTracking();

      // Start periodic saving
      _startPeriodicSaving();

      _statusController.add(GPSTrackingStatus.tracking);
      AppLogger.info('GPS tracking started successfully');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to start GPS tracking: $e');
      AppLogger.error('Stack trace: $stackTrace');
      _statusController.add(GPSTrackingStatus.error);
      return false;
    }
  }

  /// Stop GPS tracking and save final route
  Future<void> stopTracking() async {
    try {
      AppLogger.info('Stopping GPS tracking');

      if (!_isTracking) {
        AppLogger.warning('GPS tracking not active');
        return;
      }

      // Cancel subscriptions and timers
      await _positionSubscription?.cancel();
      _trackingTimer?.cancel();

      // Save final route data
      if (_currentRoute.isNotEmpty) {
        await _saveRouteData(isFinal: true);
      }

      // Reset state
      _isTracking = false;
      _currentRideId = null;
      _currentRouteId = null;
      _positionSubscription = null;
      _trackingTimer = null;

      _statusController.add(GPSTrackingStatus.stopped);
      AppLogger.info('GPS tracking stopped successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to stop GPS tracking: $e');
      AppLogger.error('Stack trace: $stackTrace');
      _statusController.add(GPSTrackingStatus.error);
    }
  }

  /// Start listening to position updates
  Future<void> _startPositionTracking() async {
    final locationService = LocationService();

    // Start location updates if not already started
    locationService.startLocationUpdates();

    // Subscribe to position stream
    _positionSubscription = locationService.positionStream.listen(
      (Position position) {
        _onPositionUpdate(position);
      },
      onError: (error) {
        AppLogger.error('Position stream error: $error');
        _statusController.add(GPSTrackingStatus.error);
      },
    );
  }

  /// Handle new position update
  void _onPositionUpdate(Position position) {
    if (!_isTracking) return;

    final gpsPoint = GPSPoint(
      latitude: position.latitude,
      longitude: position.longitude,
      altitude: position.altitude,
      accuracy: position.accuracy,
      heading: position.heading,
      speed: position.speed,
      timestamp: DateTime.now(),
      rideId: _currentRideId!,
      routeId: _currentRouteId!,
    );

    // Check if we should add this point (distance filter)
    if (_shouldAddPoint(gpsPoint)) {
      _currentRoute.add(gpsPoint);

      // Emit updated route
      _routeController.add(List.from(_currentRoute));

      // Log tracking info
      AppLogger.info(
        'GPS point added: ${gpsPoint.latitude}, ${gpsPoint.longitude} '
        '(accuracy: ${gpsPoint.accuracy}m, speed: ${gpsPoint.speed}m/s)',
      );

      // Limit stored points to prevent memory issues
      if (_currentRoute.length > _maxStoredPoints) {
        _currentRoute.removeRange(0, _currentRoute.length - _maxStoredPoints);
      }
    }
  }

  /// Check if we should add this GPS point based on distance filter
  bool _shouldAddPoint(GPSPoint newPoint) {
    if (_currentRoute.isEmpty) return true;

    final lastPoint = _currentRoute.last;
    final distance = Geolocator.distanceBetween(
      lastPoint.latitude,
      lastPoint.longitude,
      newPoint.latitude,
      newPoint.longitude,
    );

    return distance >= _minimumDistanceMeters;
  }

  /// Start periodic saving of route data
  void _startPeriodicSaving() {
    _trackingTimer = Timer.periodic(_trackingInterval, (timer) {
      if (_isTracking && _currentRoute.isNotEmpty) {
        _saveRouteData();
      }
    });
  }

  /// Save current route data to storage
  Future<void> _saveRouteData({bool isFinal = false}) async {
    try {
      if (_currentRoute.isEmpty) return;

      final prefs = await SharedPreferences.getInstance();
      final key = 'gps_route_${_currentRouteId}_${_currentRideId}';

      // Create route data object
      final routeData = GPSRouteData(
        rideId: _currentRideId!,
        routeId: _currentRouteId!,
        points: List.from(_currentRoute),
        startTime: _currentRoute.first.timestamp,
        endTime: _currentRoute.last.timestamp,
        isComplete: isFinal,
        totalDistance: _calculateTotalDistance(),
        averageSpeed: _calculateAverageSpeed(),
      );

      // Save to storage
      await prefs.setString(key, jsonEncode(routeData.toJson()));

      AppLogger.info(
        'GPS route data saved: ${_currentRoute.length} points, '
        '${routeData.totalDistance.toStringAsFixed(2)}m total distance',
      );

      // Also save to ride history if final
      if (isFinal) {
        await _saveToRideHistory(routeData);
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to save GPS route data: $e');
      AppLogger.error('Stack trace: $stackTrace');
    }
  }

  /// Save GPS data to ride history
  Future<void> _saveToRideHistory(GPSRouteData routeData) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get existing GPS history
      final historyJson = prefs.getString('gps_history') ?? '[]';
      final List<dynamic> history = jsonDecode(historyJson);

      // Add new route data
      history.add(routeData.toJson());

      // Keep only last 100 routes to manage storage
      if (history.length > 100) {
        history.removeRange(0, history.length - 100);
      }

      // Save updated history
      await prefs.setString('gps_history', jsonEncode(history));

      AppLogger.info('GPS route data saved to ride history');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to save GPS data to ride history: $e');
      AppLogger.error('Stack trace: $stackTrace');
    }
  }

  /// Calculate total distance traveled
  double _calculateTotalDistance() {
    if (_currentRoute.length < 2) return 0.0;

    double totalDistance = 0.0;
    for (int i = 1; i < _currentRoute.length; i++) {
      final prev = _currentRoute[i - 1];
      final current = _currentRoute[i];

      totalDistance += Geolocator.distanceBetween(
        prev.latitude,
        prev.longitude,
        current.latitude,
        current.longitude,
      );
    }

    return totalDistance;
  }

  /// Calculate average speed
  double _calculateAverageSpeed() {
    if (_currentRoute.length < 2) return 0.0;

    final validSpeeds = _currentRoute
        .where((point) => point.speed > 0)
        .map((point) => point.speed)
        .toList();

    if (validSpeeds.isEmpty) return 0.0;

    return validSpeeds.reduce((a, b) => a + b) / validSpeeds.length;
  }

  /// Get GPS history for a specific ride
  Future<GPSRouteData?> getRouteData(String rideId, String routeId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'gps_route_${routeId}_$rideId';
      final jsonString = prefs.getString(key);

      if (jsonString != null) {
        final json = jsonDecode(jsonString);
        return GPSRouteData.fromJson(json);
      }

      return null;
    } catch (e) {
      AppLogger.error('Failed to get GPS route data: $e');
      return null;
    }
  }

  /// Get all GPS history
  Future<List<GPSRouteData>> getGPSHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString('gps_history') ?? '[]';
      final List<dynamic> history = jsonDecode(historyJson);

      return history.map((json) => GPSRouteData.fromJson(json)).toList();
    } catch (e) {
      AppLogger.error('Failed to get GPS history: $e');
      return [];
    }
  }

  /// Get current GPS status
  GPSTrackingStatus getCurrentStatus() {
    if (!_isTracking) return GPSTrackingStatus.stopped;
    if (_currentRoute.isEmpty) return GPSTrackingStatus.waiting;
    return GPSTrackingStatus.tracking;
  }

  /// Get tracking statistics
  Map<String, dynamic> getTrackingStats() {
    return {
      'isTracking': _isTracking,
      'currentRideId': _currentRideId,
      'pointsRecorded': _currentRoute.length,
      'totalDistance': _calculateTotalDistance(),
      'averageSpeed': _calculateAverageSpeed(),
      'trackingDuration': _isTracking && _currentRoute.isNotEmpty
          ? DateTime.now().difference(_currentRoute.first.timestamp)
          : Duration.zero,
    };
  }

  /// Dispose resources
  void dispose() {
    stopTracking();
    _statusController.close();
    _routeController.close();
  }
}

/// GPS point data model
class GPSPoint {
  final double latitude;
  final double longitude;
  final double altitude;
  final double accuracy;
  final double heading;
  final double speed;
  final DateTime timestamp;
  final String rideId;
  final String routeId;

  GPSPoint({
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.accuracy,
    required this.heading,
    required this.speed,
    required this.timestamp,
    required this.rideId,
    required this.routeId,
  });

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'altitude': altitude,
    'accuracy': accuracy,
    'heading': heading,
    'speed': speed,
    'timestamp': timestamp.toIso8601String(),
    'rideId': rideId,
    'routeId': routeId,
  };

  factory GPSPoint.fromJson(Map<String, dynamic> json) => GPSPoint(
    latitude: json['latitude']?.toDouble() ?? 0.0,
    longitude: json['longitude']?.toDouble() ?? 0.0,
    altitude: json['altitude']?.toDouble() ?? 0.0,
    accuracy: json['accuracy']?.toDouble() ?? 0.0,
    heading: json['heading']?.toDouble() ?? 0.0,
    speed: json['speed']?.toDouble() ?? 0.0,
    timestamp: DateTime.parse(json['timestamp']),
    rideId: json['rideId'] ?? '',
    routeId: json['routeId'] ?? '',
  );
}

/// GPS route data model
class GPSRouteData {
  final String rideId;
  final String routeId;
  final List<GPSPoint> points;
  final DateTime startTime;
  final DateTime endTime;
  final bool isComplete;
  final double totalDistance;
  final double averageSpeed;

  GPSRouteData({
    required this.rideId,
    required this.routeId,
    required this.points,
    required this.startTime,
    required this.endTime,
    required this.isComplete,
    required this.totalDistance,
    required this.averageSpeed,
  });

  Duration get duration => endTime.difference(startTime);

  Map<String, dynamic> toJson() => {
    'rideId': rideId,
    'routeId': routeId,
    'points': points.map((p) => p.toJson()).toList(),
    'startTime': startTime.toIso8601String(),
    'endTime': endTime.toIso8601String(),
    'isComplete': isComplete,
    'totalDistance': totalDistance,
    'averageSpeed': averageSpeed,
  };

  factory GPSRouteData.fromJson(Map<String, dynamic> json) => GPSRouteData(
    rideId: json['rideId'] ?? '',
    routeId: json['routeId'] ?? '',
    points:
        (json['points'] as List?)?.map((p) => GPSPoint.fromJson(p)).toList() ??
        [],
    startTime: DateTime.parse(json['startTime']),
    endTime: DateTime.parse(json['endTime']),
    isComplete: json['isComplete'] ?? false,
    totalDistance: json['totalDistance']?.toDouble() ?? 0.0,
    averageSpeed: json['averageSpeed']?.toDouble() ?? 0.0,
  );
}

/// GPS tracking status enumeration
enum GPSTrackingStatus {
  stopped,
  waiting,
  tracking,
  permissionDenied,
  serviceDisabled,
  error,
}
