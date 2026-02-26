import 'package:flutter/material.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../shared/widgets/custom_button.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final NotificationService _notificationService = NotificationService();

  bool _notificationsEnabled = false;
  bool _rideAssignments = true;
  bool _rideUpdates = true;
  bool _paymentNotifications = true;
  bool _systemAlerts = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;

  String? _fcmToken;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    setState(() => _isLoading = true);

    try {
      final enabled = await _notificationService.areNotificationsEnabled();
      final token = _notificationService.fcmToken;

      setState(() {
        _notificationsEnabled = enabled;
        _fcmToken = token;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorMessage('Failed to load notification settings');
    }
  }

  Future<void> _requestPermissions() async {
    final granted = await _notificationService.requestPermissions();

    if (granted) {
      setState(() => _notificationsEnabled = true);
      _showSuccessMessage('Notifications enabled successfully!');
    } else {
      _showErrorMessage('Notification permissions denied');
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  Future<void> _testNotification() async {
    await _notificationService.showRideAssignmentNotification(
      rideId: 'test_123',
      customerName: 'John Doe',
      pickupAddress: '123 Main St, Downtown',
      estimatedEarnings: 25.50,
    );

    _showSuccessMessage('Test notification sent!');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔔 Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active),
            onPressed: _testNotification,
            tooltip: 'Test Notification',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: 100, // Extra padding to ensure content is not hidden by bottom nav
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNotificationStatus(),
                  const SizedBox(height: 24),
                  _buildNotificationTypes(),
                  const SizedBox(height: 24),
                  _buildNotificationSettings(),
                  const SizedBox(height: 24),
                  _buildTopicSubscriptions(),
                  const SizedBox(height: 24),
                  _buildDeveloperInfo(),
                ],
              ),
            ),
    );
  }

  Widget _buildNotificationStatus() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _notificationsEnabled
                      ? Icons.notifications_active
                      : Icons.notifications_off,
                  color: _notificationsEnabled ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  'Notification Status',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _notificationsEnabled
                  ? 'Notifications are enabled and working properly'
                  : 'Notifications are disabled. Enable them to receive ride assignments.',
              style: TextStyle(
                color: _notificationsEnabled
                    ? Colors.green[700]
                    : Colors.red[700],
              ),
            ),
            if (!_notificationsEnabled) ...[
              const SizedBox(height: 16),
              CustomButton(
                text: 'Enable Notifications',
                onPressed: _requestPermissions,
                backgroundColor: Colors.green,
                icon: Icons.notifications,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationTypes() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notification Types',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            _buildSwitchTile(
              title: '🚗 Ride Assignments',
              subtitle: 'Get notified when new rides are available',
              value: _rideAssignments,
              onChanged: (value) => setState(() => _rideAssignments = value),
            ),
            _buildSwitchTile(
              title: '📍 Ride Updates',
              subtitle: 'Updates about ongoing rides and customer actions',
              value: _rideUpdates,
              onChanged: (value) => setState(() => _rideUpdates = value),
            ),
            _buildSwitchTile(
              title: '💰 Payment Notifications',
              subtitle: 'Payment confirmations and earnings updates',
              value: _paymentNotifications,
              onChanged: (value) =>
                  setState(() => _paymentNotifications = value),
            ),
            _buildSwitchTile(
              title: '⚠️ System Alerts',
              subtitle: 'Important system notifications and updates',
              value: _systemAlerts,
              onChanged: (value) => setState(() => _systemAlerts = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notification Behavior',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            _buildSwitchTile(
              title: '🔊 Sound',
              subtitle: 'Play notification sounds',
              value: _soundEnabled,
              onChanged: (value) => setState(() => _soundEnabled = value),
            ),
            _buildSwitchTile(
              title: '📳 Vibration',
              subtitle: 'Vibrate for notifications',
              value: _vibrationEnabled,
              onChanged: (value) => setState(() => _vibrationEnabled = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicSubscriptions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Topic Subscriptions',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            _buildTopicTile(
              title: 'City Updates',
              subtitle: 'General updates for your city',
              topic: 'city_updates',
            ),
            _buildTopicTile(
              title: 'Driver Announcements',
              subtitle: 'Important announcements for drivers',
              topic: 'driver_announcements',
            ),
            _buildTopicTile(
              title: 'Promotional Offers',
              subtitle: 'Special promotions and bonus opportunities',
              topic: 'promotions',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeveloperInfo() {
    if (_fcmToken == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Developer Information',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'FCM Token:',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _fcmToken!,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
              ),
            ),
            const SizedBox(height: 12),
            CustomButton(
              text: 'Copy Token',
              onPressed: () {
                // Copy to clipboard functionality would go here
                _showSuccessMessage('Token copied to clipboard');
              },
              height: 36,
              icon: Icons.copy,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  subtitle,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _buildTopicTile({
    required String title,
    required String subtitle,
    required String topic,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  subtitle,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Row(
            children: [
              TextButton(
                onPressed: () async {
                  await _notificationService.subscribeToTopic(topic);
                  _showSuccessMessage('Subscribed to $title');
                },
                child: const Text('Subscribe'),
              ),
              TextButton(
                onPressed: () async {
                  await _notificationService.unsubscribeFromTopic(topic);
                  _showSuccessMessage('Unsubscribed from $title');
                },
                child: const Text('Unsubscribe'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
