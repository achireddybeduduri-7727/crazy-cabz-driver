import 'package:flutter/material.dart';
import '../../core/services/gps_tracking_service.dart';

class GPSTrackingWidget extends StatefulWidget {
  final String? currentRideId;
  final bool showDetails;

  const GPSTrackingWidget({
    super.key,
    this.currentRideId,
    this.showDetails = true,
  });

  @override
  State<GPSTrackingWidget> createState() => _GPSTrackingWidgetState();
}

class _GPSTrackingWidgetState extends State<GPSTrackingWidget>
    with TickerProviderStateMixin {
  final GPSTrackingService _gpsService = GPSTrackingService();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize pulse animation for tracking indicator
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Start pulse animation if tracking
    if (_gpsService.isTracking) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<GPSTrackingStatus>(
      stream: _gpsService.statusStream,
      initialData: _gpsService.getCurrentStatus(),
      builder: (context, statusSnapshot) {
        final status = statusSnapshot.data ?? GPSTrackingStatus.stopped;

        // Update pulse animation based on status
        if (status == GPSTrackingStatus.tracking) {
          if (!_pulseController.isAnimating) {
            _pulseController.repeat(reverse: true);
          }
        } else {
          _pulseController.stop();
          _pulseController.reset();
        }

        return StreamBuilder<List<GPSPoint>>(
          stream: _gpsService.routeStream,
          builder: (context, routeSnapshot) {
            final stats = _gpsService.getTrackingStats();

            return Card(
              elevation: 2,
              margin: const EdgeInsets.all(8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(status),
                    if (widget.showDetails) ...[
                      const SizedBox(height: 12),
                      _buildStats(stats),
                    ],
                    if (status == GPSTrackingStatus.error ||
                        status == GPSTrackingStatus.permissionDenied ||
                        status == GPSTrackingStatus.serviceDisabled) ...[
                      const SizedBox(height: 12),
                      _buildErrorActions(status),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeader(GPSTrackingStatus status) {
    final statusInfo = _getStatusInfo(status);

    return Row(
      children: [
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: status == GPSTrackingStatus.tracking
                  ? _pulseAnimation.value
                  : 1.0,
              child: Icon(statusInfo.icon, color: statusInfo.color, size: 24),
            );
          },
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'GPS Tracking',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                statusInfo.message,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: statusInfo.color),
              ),
            ],
          ),
        ),
        if (status == GPSTrackingStatus.tracking)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'ACTIVE',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.green[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStats(Map<String, dynamic> stats) {
    final pointsRecorded = stats['pointsRecorded'] as int;
    final totalDistance = stats['totalDistance'] as double;
    final averageSpeed = stats['averageSpeed'] as double;
    final trackingDuration = stats['trackingDuration'] as Duration;

    return Column(
      children: [
        const Divider(),
        Row(
          children: [
            Expanded(
              child: _buildStatItem(
                'Points',
                pointsRecorded.toString(),
                Icons.place,
              ),
            ),
            Expanded(
              child: _buildStatItem(
                'Distance',
                '${(totalDistance / 1000).toStringAsFixed(1)} km',
                Icons.straighten,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildStatItem(
                'Avg Speed',
                '${(averageSpeed * 3.6).toStringAsFixed(1)} km/h',
                Icons.speed,
              ),
            ),
            Expanded(
              child: _buildStatItem(
                'Duration',
                _formatDuration(trackingDuration),
                Icons.timer,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: Colors.grey[600]),
            ),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildErrorActions(GPSTrackingStatus status) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(),
        if (status == GPSTrackingStatus.permissionDenied)
          ElevatedButton.icon(
            onPressed: () {
              // Try to request permissions again
              _requestPermissions();
            },
            icon: const Icon(Icons.security),
            label: const Text('Grant Location Permission'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        if (status == GPSTrackingStatus.serviceDisabled)
          ElevatedButton.icon(
            onPressed: () {
              // Show dialog to enable location services
              _showLocationServiceDialog();
            },
            icon: const Icon(Icons.location_off),
            label: const Text('Enable Location Services'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        if (status == GPSTrackingStatus.error)
          ElevatedButton.icon(
            onPressed: () {
              // Try to restart GPS tracking
              _restartTracking();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry GPS Tracking'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
      ],
    );
  }

  StatusInfo _getStatusInfo(GPSTrackingStatus status) {
    switch (status) {
      case GPSTrackingStatus.tracking:
        return StatusInfo(
          icon: Icons.gps_fixed,
          color: Colors.green,
          message: 'Recording GPS location',
        );
      case GPSTrackingStatus.waiting:
        return StatusInfo(
          icon: Icons.gps_not_fixed,
          color: Colors.orange,
          message: 'Waiting for GPS signal',
        );
      case GPSTrackingStatus.stopped:
        return StatusInfo(
          icon: Icons.gps_off,
          color: Colors.grey,
          message: 'GPS tracking stopped',
        );
      case GPSTrackingStatus.permissionDenied:
        return StatusInfo(
          icon: Icons.gps_off,
          color: Colors.red,
          message: 'Location permission denied',
        );
      case GPSTrackingStatus.serviceDisabled:
        return StatusInfo(
          icon: Icons.location_disabled,
          color: Colors.red,
          message: 'Location services disabled',
        );
      case GPSTrackingStatus.error:
        return StatusInfo(
          icon: Icons.error,
          color: Colors.red,
          message: 'GPS tracking error',
        );
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  Future<void> _requestPermissions() async {
    // This would typically trigger a permission request
    // For now, just show a message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please grant location permission in app settings'),
      ),
    );
  }

  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Services Disabled'),
        content: const Text(
          'Please enable location services in your device settings to use GPS tracking.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _restartTracking() async {
    if (widget.currentRideId != null) {
      // This would typically restart tracking
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attempting to restart GPS tracking...')),
      );
    }
  }
}

class StatusInfo {
  final IconData icon;
  final Color color;
  final String message;

  StatusInfo({required this.icon, required this.color, required this.message});
}
