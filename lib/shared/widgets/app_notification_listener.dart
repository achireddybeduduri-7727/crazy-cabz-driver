import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/services/notification_service.dart';

class AppNotificationListener extends StatefulWidget {
  final Widget child;
  final Function(Map<String, dynamic>)? onRideAssignment;
  final Function(Map<String, dynamic>)? onRideUpdate;
  final Function(Map<String, dynamic>)? onPaymentNotification;
  final Function(Map<String, dynamic>)? onSystemAlert;

  const AppNotificationListener({
    super.key,
    required this.child,
    this.onRideAssignment,
    this.onRideUpdate,
    this.onPaymentNotification,
    this.onSystemAlert,
  });

  @override
  State<AppNotificationListener> createState() =>
      _AppNotificationListenerState();
}

class _AppNotificationListenerState extends State<AppNotificationListener> {
  final NotificationService _notificationService = NotificationService();
  late List<StreamSubscription> _subscriptions;

  @override
  void initState() {
    super.initState();
    _setupNotificationListeners();
  }

  void _setupNotificationListeners() {
    _subscriptions = [
      _notificationService.rideAssignmentStream.listen(_handleRideAssignment),
      _notificationService.rideUpdateStream.listen(_handleRideUpdate),
      _notificationService.paymentStream.listen(_handlePaymentNotification),
      _notificationService.systemAlertStream.listen(_handleSystemAlert),
    ];
  }

  void _handleRideAssignment(Map<String, dynamic> data) {
    if (widget.onRideAssignment != null) {
      widget.onRideAssignment!(data);
    } else {
      _showDefaultRideAssignmentDialog(data);
    }
  }

  void _handleRideUpdate(Map<String, dynamic> data) {
    if (widget.onRideUpdate != null) {
      widget.onRideUpdate!(data);
    } else {
      _showDefaultNotificationSnackBar('Ride Update', data);
    }
  }

  void _handlePaymentNotification(Map<String, dynamic> data) {
    if (widget.onPaymentNotification != null) {
      widget.onPaymentNotification!(data);
    } else {
      _showDefaultNotificationSnackBar('Payment Notification', data);
    }
  }

  void _handleSystemAlert(Map<String, dynamic> data) {
    if (widget.onSystemAlert != null) {
      widget.onSystemAlert!(data);
    } else {
      _showDefaultSystemAlertDialog(data);
    }
  }

  void _showDefaultRideAssignmentDialog(Map<String, dynamic> data) {
    final rideId = data['ride_id'] as String? ?? '';
    final customerName = data['customer_name'] as String? ?? 'Unknown';
    final pickupAddress = data['pickup_address'] as String? ?? '';
    final estimatedEarnings = data['estimated_earnings'] as double? ?? 0.0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => RideAssignmentDialog(
        rideId: rideId,
        customerName: customerName,
        pickupAddress: pickupAddress,
        estimatedEarnings: estimatedEarnings,
        onAccept: () {
          Navigator.of(context).pop();
          _acceptRide(rideId);
        },
        onDecline: () {
          Navigator.of(context).pop();
          _declineRide(rideId);
        },
      ),
    );
  }

  void _showDefaultSystemAlertDialog(Map<String, dynamic> data) {
    final title = data['title'] as String? ?? 'System Alert';
    final message = data['message'] as String? ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning, color: Colors.orange),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showDefaultNotificationSnackBar(
    String title,
    Map<String, dynamic> data,
  ) {
    final message = data['message'] as String? ?? 'New notification received';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.notifications, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(message),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () {
            // Handle notification tap
          },
        ),
      ),
    );
  }

  void _acceptRide(String rideId) {
    // TODO: Implement ride acceptance logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ride $rideId accepted!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _declineRide(String rideId) {
    // TODO: Implement ride decline logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ride $rideId declined'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class RideAssignmentDialog extends StatefulWidget {
  final String rideId;
  final String customerName;
  final String pickupAddress;
  final double estimatedEarnings;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const RideAssignmentDialog({
    super.key,
    required this.rideId,
    required this.customerName,
    required this.pickupAddress,
    required this.estimatedEarnings,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  State<RideAssignmentDialog> createState() => _RideAssignmentDialogState();
}

class _RideAssignmentDialogState extends State<RideAssignmentDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  static const int _timeoutSeconds = 15;
  int _remainingSeconds = _timeoutSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _animationController.forward();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _remainingSeconds--;
      });

      if (_remainingSeconds <= 0) {
        timer.cancel();
        widget.onDecline();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.car_rental, color: Colors.green),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'New Ride Request',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _remainingSeconds <= 5 ? Colors.red : Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_remainingSeconds}s',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(
                  icon: Icons.person,
                  label: 'Customer',
                  value: widget.customerName,
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  icon: Icons.location_on,
                  label: 'Pickup',
                  value: widget.pickupAddress,
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  icon: Icons.monetization_on,
                  label: 'Estimated Earnings',
                  value: '\$${widget.estimatedEarnings.toStringAsFixed(2)}',
                  valueColor: Colors.green[700],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: widget.onDecline,
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Decline'),
              ),
              ElevatedButton(
                onPressed: widget.onAccept,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Accept'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: valueColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
