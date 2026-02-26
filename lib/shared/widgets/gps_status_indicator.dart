import 'package:flutter/material.dart';
import '../../core/services/gps_tracking_service.dart';

class GPSStatusIndicator extends StatelessWidget {
  final bool compact;

  const GPSStatusIndicator({super.key, this.compact = true});

  @override
  Widget build(BuildContext context) {
    final gpsService = GPSTrackingService();

    return StreamBuilder<GPSTrackingStatus>(
      stream: gpsService.statusStream,
      initialData: gpsService.getCurrentStatus(),
      builder: (context, snapshot) {
        final status = snapshot.data ?? GPSTrackingStatus.stopped;
        final isTracking = status == GPSTrackingStatus.tracking;

        if (compact) {
          return _buildCompactIndicator(context, status, isTracking);
        } else {
          return _buildExpandedIndicator(context, status, isTracking);
        }
      },
    );
  }

  Widget _buildCompactIndicator(
    BuildContext context,
    GPSTrackingStatus status,
    bool isTracking,
  ) {
    final color = _getStatusColor(status);
    final icon = _getStatusIcon(status);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isTracking)
            TweenAnimationBuilder<double>(
              duration: const Duration(seconds: 1),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: 0.8 + (0.4 * value),
                  child: Icon(icon, color: color, size: 16),
                );
              },
            )
          else
            Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Text(
            _getStatusText(status),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedIndicator(
    BuildContext context,
    GPSTrackingStatus status,
    bool isTracking,
  ) {
    final color = _getStatusColor(status);
    final icon = _getStatusIcon(status);
    final stats = GPSTrackingService().getTrackingStats();

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            if (isTracking)
              TweenAnimationBuilder<double>(
                duration: const Duration(seconds: 2),
                tween: Tween(begin: 0.8, end: 1.2),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Icon(icon, color: color, size: 24),
                  );
                },
              )
            else
              Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'GPS Tracking',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _getStatusText(status),
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: color),
                  ),
                ],
              ),
            ),
            if (isTracking && stats['pointsRecorded'] > 0) ...[
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${stats['pointsRecorded']} points',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  Text(
                    '${((stats['totalDistance'] as double) / 1000).toStringAsFixed(1)} km',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(GPSTrackingStatus status) {
    switch (status) {
      case GPSTrackingStatus.tracking:
        return Colors.green;
      case GPSTrackingStatus.waiting:
        return Colors.orange;
      case GPSTrackingStatus.stopped:
        return Colors.grey;
      case GPSTrackingStatus.permissionDenied:
      case GPSTrackingStatus.serviceDisabled:
      case GPSTrackingStatus.error:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(GPSTrackingStatus status) {
    switch (status) {
      case GPSTrackingStatus.tracking:
        return Icons.gps_fixed;
      case GPSTrackingStatus.waiting:
        return Icons.gps_not_fixed;
      case GPSTrackingStatus.stopped:
        return Icons.gps_off;
      case GPSTrackingStatus.permissionDenied:
        return Icons.gps_off;
      case GPSTrackingStatus.serviceDisabled:
        return Icons.location_disabled;
      case GPSTrackingStatus.error:
        return Icons.error;
    }
  }

  String _getStatusText(GPSTrackingStatus status) {
    switch (status) {
      case GPSTrackingStatus.tracking:
        return 'Tracking';
      case GPSTrackingStatus.waiting:
        return 'Waiting';
      case GPSTrackingStatus.stopped:
        return 'Stopped';
      case GPSTrackingStatus.permissionDenied:
        return 'No Permission';
      case GPSTrackingStatus.serviceDisabled:
        return 'Disabled';
      case GPSTrackingStatus.error:
        return 'Error';
    }
  }
}
