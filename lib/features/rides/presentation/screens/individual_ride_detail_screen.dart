import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../../../shared/widgets/swipe_button.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../../../../shared/widgets/gps_tracking_widget.dart';
import '../../../../shared/models/route_model.dart';
import '../bloc/route_bloc.dart';
import '../bloc/route_event.dart';
import '../bloc/route_state.dart';

class IndividualRideDetailScreen extends StatefulWidget {
  final IndividualRide ride;
  final String driverId;

  const IndividualRideDetailScreen({
    super.key,
    required this.ride,
    required this.driverId,
  });

  @override
  State<IndividualRideDetailScreen> createState() =>
      _IndividualRideDetailScreenState();
}

class _IndividualRideDetailScreenState
    extends State<IndividualRideDetailScreen> {
  late RouteBloc _routeBloc;
  late IndividualRide _currentRide;

  @override
  void initState() {
    super.initState();
    _routeBloc = BlocProvider.of<RouteBloc>(context);
    _currentRide = widget.ride;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentRide.passenger.fullName),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: () => _showEmergencyDialog(),
            icon: const Icon(Icons.emergency, color: Colors.red),
            tooltip: 'Emergency Alert',
          ),
          IconButton(
            onPressed: () => _callPassenger(),
            icon: const Icon(Icons.phone),
            tooltip: 'Call Passenger',
          ),
        ],
      ),
      body: BlocConsumer<RouteBloc, RouteState>(
        listener: (context, state) {
          if (state is RouteError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is IndividualRideUpdated) {
            if (state.ride.id == _currentRide.id) {
              setState(() {
                _currentRide = state.ride;
              });
              // Don't show snackbar for every timeline update to avoid spam
              // The message will be shown only for major events
            }
          } else if (state is PassengerPresenceUpdated) {
            if (state.ride.id == _currentRide.id) {
              setState(() {
                _currentRide = state.ride;
              });
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.blue,
              ),
            );
          } else if (state is EmergencyAlertSent) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.orange,
              ),
            );
          } else if (state is RouteCompleted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
            // Don't navigate back here - let _completeRide() handle it
          }
        },
        builder: (context, state) {
          bool isLoading = state is RouteUpdating;
          String? loadingText;

          if (state is RouteUpdating) {
            loadingText = state.action;
          }

          return LoadingOverlay(
            isLoading: isLoading,
            loadingText: loadingText,
            child: _buildRideDetails(),
          );
        },
      ),
    );
  }

  Widget _buildRideDetails() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPassengerCard(),
          const SizedBox(height: 16),
          _buildRideStatusCard(),
          const SizedBox(height: 16),
          _buildLocationCard(),
          const SizedBox(height: 16),
          _buildTimelineCard(),
          const SizedBox(height: 16),
          GPSTrackingWidget(currentRideId: _currentRide.id, showDetails: true),
          const SizedBox(height: 16),
          _buildPaymentSummaryCard(),
          const SizedBox(height: 24),
          _buildRideActions(),
        ],
      ),
    );
  }

  Widget _buildPassengerCard() {
    final passenger = _currentRide.passenger;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: passenger.profilePhotoUrl != null
                      ? NetworkImage(passenger.profilePhotoUrl!)
                      : null,
                  child: passenger.profilePhotoUrl == null
                      ? Text(
                          _getInitials(passenger.fullName),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        passenger.fullName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${passenger.employeeId}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        'Dept: ${passenger.department}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _callPassenger(),
                  icon: const Icon(Icons.phone),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.green[100],
                    foregroundColor: Colors.green[700],
                  ),
                ),
              ],
            ),
            if (passenger.specialInstructions != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, size: 16, color: Colors.blue[600]),
                        const SizedBox(width: 8),
                        Text(
                          'Special Instructions',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      passenger.specialInstructions!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRideStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ride Status',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getRideStatusColor(_currentRide.status),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _getRideStatusText(_currentRide.status),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'Route Order: ',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
                Text(
                  '#${_currentRide.routeOrder}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.blue[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (_currentRide.scheduledPickupTime != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: Colors.blue[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Scheduled: ',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    DateFormat(
                      'MMM dd, h:mm a',
                    ).format(_currentRide.scheduledPickupTime!),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.blue[600],
                      fontWeight: FontWeight.bold,
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

  Widget _buildLocationCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Locations',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildLocationItem(
              'Pickup Location',
              _currentRide.pickupAddress,
              Icons.location_on,
              Colors.green,
              () => _openMapsNavigation(
                _currentRide.pickupLatitude,
                _currentRide.pickupLongitude,
                _currentRide.pickupAddress,
              ),
            ),
            const SizedBox(height: 12),
            _buildLocationItem(
              'Drop-off Location',
              _currentRide.dropOffAddress,
              Icons.location_off,
              Colors.red,
              () => _openMapsNavigation(
                _currentRide.dropOffLatitude,
                _currentRide.dropOffLongitude,
                _currentRide.dropOffAddress,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationItem(
    String title,
    String address,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(address, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            Icon(Icons.navigation, color: Colors.blue[600], size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timeline, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Live Ride Timeline',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_currentRide.totalRideDuration != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green),
                    ),
                    child: Text(
                      'Total: ${_currentRide.totalRideDuration}m',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // Horizontal Timeline
            _buildHorizontalTimeline(),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalTimeline() {
    final List<Map<String, dynamic>> timelineSteps = [
      {
        'title': 'Navigate to\nPickup',
        'timestamp': _currentRide.navigatedToPickupAt,
        'icon': Icons.navigation,
        'color': Colors.blue,
        'isCompleted': _currentRide.navigatedToPickupAt != null,
      },
      {
        'title': 'Arrived at\nPickup',
        'timestamp': _currentRide.arrivedAtPickupAt,
        'icon': Icons.location_on,
        'color': Colors.orange,
        'isCompleted': _currentRide.arrivedAtPickupAt != null,
        'duration': _currentRide.navigationToPickupDuration,
      },
      {
        'title': 'Passenger\nPicked Up',
        'timestamp': _currentRide.passengerPickedUpAt,
        'icon': Icons.person,
        'color': Colors.green,
        'isCompleted': _currentRide.passengerPickedUpAt != null,
        'duration': _currentRide.waitingAtPickupDuration,
      },
      {
        'title': 'Navigate to\nDestination',
        'timestamp': _currentRide.navigatedToDestinationAt,
        'icon': Icons.navigation,
        'color': Colors.cyan,
        'isCompleted': _currentRide.navigatedToDestinationAt != null,
      },
      {
        'title': 'Arrived at\nDestination',
        'timestamp': _currentRide.arrivedAtDestinationAt,
        'icon': Icons.flag,
        'color': Colors.teal,
        'isCompleted': _currentRide.arrivedAtDestinationAt != null,
        'duration': _currentRide.navigationToDestinationDuration,
      },
      {
        'title': 'Ride\nCompleted',
        'timestamp': _currentRide.rideCompletedAt,
        'icon': Icons.check_circle,
        'color': Colors.purple,
        'isCompleted': _currentRide.rideCompletedAt != null,
      },
    ];

    // Calculate current progress
    int completedSteps = timelineSteps
        .where((step) => step['isCompleted'] == true)
        .length;
    double progress = completedSteps / timelineSteps.length;

    return Column(
      children: [
        // Timeline line with car indicator
        SizedBox(
          height: 60,
          child: Stack(
            children: [
              // Background line
              Positioned(
                left: 20,
                right: 20,
                top: 20,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Progress line
              Positioned(
                left: 20,
                top: 20,
                child: Container(
                  width: (MediaQuery.of(context).size.width - 104) * progress,
                  height: 4,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue, Colors.green, Colors.purple],
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Car indicator
              if (progress > 0)
                Positioned(
                  left:
                      20 +
                      (MediaQuery.of(context).size.width - 104) * progress -
                      15,
                  top: 5,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.directions_car,
                      color: Theme.of(context).primaryColor,
                      size: 22,
                    ),
                  ),
                ),
              // Timeline dots
              ...List.generate(timelineSteps.length, (index) {
                final step = timelineSteps[index];
                final isCompleted = step['isCompleted'] as bool;
                final stepPosition =
                    20 +
                    (MediaQuery.of(context).size.width - 104) *
                        (index / (timelineSteps.length - 1));

                return Positioned(
                  left: stepPosition - 6,
                  top: 16,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted ? step['color'] : Colors.grey[300],
                      border: Border.all(
                        color: isCompleted ? step['color'] : Colors.grey,
                        width: 2,
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Timeline labels scrollable
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(timelineSteps.length, (index) {
              final step = timelineSteps[index];
              final isCompleted = step['isCompleted'] as bool;
              final timestamp = step['timestamp'] as DateTime?;
              final duration = step['duration'] as int?;

              return SizedBox(
                width:
                    (MediaQuery.of(context).size.width - 64) /
                    timelineSteps.length,
                child: Column(
                  children: [
                    Icon(
                      step['icon'],
                      color: isCompleted ? step['color'] : Colors.grey,
                      size: 24,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      step['title'],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isCompleted
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: isCompleted ? Colors.black87 : Colors.grey[600],
                        height: 1.2,
                      ),
                    ),
                    if (isCompleted && timestamp != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _formatTime(timestamp),
                        style: TextStyle(
                          fontSize: 10,
                          color: step['color'],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                    if (duration != null && isCompleted) ...[
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: (step['color'] as Color).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${duration}m',
                          style: TextStyle(
                            fontSize: 9,
                            color: step['color'],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentSummaryCard() {
    if (_currentRide.status == IndividualRideStatus.completed) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.payment, color: Colors.green[700]),
                  const SizedBox(width: 8),
                  Text(
                    'Payment Summary',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (_currentRide.navigationToPickupDuration != null)
                _buildPaymentRow(
                  'Navigation to Pickup',
                  '${_currentRide.navigationToPickupDuration}m',
                  Icons.navigation,
                ),

              if (_currentRide.waitingAtPickupDuration != null)
                _buildPaymentRow(
                  'Waiting at Pickup',
                  '${_currentRide.waitingAtPickupDuration}m',
                  Icons.schedule,
                ),

              if (_currentRide.navigationToDestinationDuration != null)
                _buildPaymentRow(
                  'Trip to Destination',
                  '${_currentRide.navigationToDestinationDuration}m',
                  Icons.drive_eta,
                ),

              if (_currentRide.totalRideDuration != null) ...[
                const Divider(),
                _buildPaymentRow(
                  'Total Ride Time',
                  '${_currentRide.totalRideDuration}m',
                  Icons.timer,
                  isTotal: true,
                ),
              ],
            ],
          ),
        ),
      );
    } else {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.timer, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Text(
                    'Live Timing',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Time tracking active - all actions are being logged for accurate payment calculation.',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildPaymentRow(
    String label,
    String duration,
    IconData icon, {
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: isTotal ? Colors.green[700] : Colors.grey[600],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                color: isTotal ? Colors.green[700] : Colors.black87,
              ),
            ),
          ),
          Text(
            duration,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isTotal ? Colors.green[700] : Colors.blue[600],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return DateFormat('h:mm a').format(dateTime);
  }

  Widget _buildRideActions() {
    final status = _currentRide.status;

    return Column(
      children: [
        // Edit Address and Cancel Ride buttons (available for scheduled and en-route rides)
        if (status == IndividualRideStatus.scheduled ||
            status == IndividualRideStatus.enRoute) ...[
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showEditAddressDialog(),
                  icon: const Icon(Icons.edit_location),
                  label: const Text('Edit Address'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showCancelRideDialog(),
                  icon: const Icon(Icons.cancel),
                  label: const Text('Cancel Ride'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],

        // Step 1: Start navigation to pickup location
        if (status == IndividualRideStatus.scheduled) ...[
          SwipeButton(
            text: 'Swipe to Navigate Pick',
            onConfirm: () => _startNavigationToPickup(),
            backgroundColor: Colors.blue,
          ),
        ]
        // Step 2: Mark arrival at pickup location
        else if (status == IndividualRideStatus.enRoute) ...[
          SwipeButton(
            text: 'Swipe when Arrived',
            onConfirm: () => _arrivedAtPickup(),
            backgroundColor: Colors.orange,
          ),
        ]
        // Step 3: Navigate to destination (passenger picked up)
        else if (status == IndividualRideStatus.arrived) ...[
          SwipeButton(
            text: 'Swipe to Navigate Destination',
            onConfirm: () => _startNavigationToDestination(),
            backgroundColor: Colors.green,
          ),
        ]
        // Step 4: End the ride
        else if (status == IndividualRideStatus.pickedUp) ...[
          SwipeButton(
            text: 'Swipe to End Ride',
            onConfirm: () => _completeRide(),
            backgroundColor: Colors.purple,
          ),
        ],
      ],
    );
  }

  // Time-tracked event methods for precise ride timeline

  void _startNavigationToPickup() {
    _routeBloc.add(StartNavigationToPickup(rideId: _currentRide.id));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Navigation to pickup started - time logged!'),
      ),
    );
  }

  void _arrivedAtPickup() {
    _routeBloc.add(ArrivedAtPickup(rideId: _currentRide.id));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Arrival at pickup logged - time saved!')),
    );
  }

  void _startNavigationToDestination() {
    // First mark passenger as picked up, then start navigation to destination
    _routeBloc.add(PassengerPickedUp(rideId: _currentRide.id));
    _routeBloc.add(StartNavigationToDestination(rideId: _currentRide.id));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Passenger picked up - navigating to destination!'),
      ),
    );
  }

  void _completeRide() async {
    // Complete the full timeline sequence before marking ride as complete

    // Step 1: Ensure passenger pickup is logged
    if (_currentRide.passengerPickedUpAt == null) {
      _routeBloc.add(PassengerPickedUp(rideId: _currentRide.id));
      // Wait a moment for state to update
      await Future.delayed(const Duration(milliseconds: 300));
    }

    // Step 2: Ensure navigation to destination is logged
    if (_currentRide.navigatedToDestinationAt == null) {
      _routeBloc.add(StartNavigationToDestination(rideId: _currentRide.id));
      await Future.delayed(const Duration(milliseconds: 300));
    }

    // Step 3: Mark arrival at destination
    if (_currentRide.arrivedAtDestinationAt == null) {
      _routeBloc.add(ArrivedAtDestination(rideId: _currentRide.id));
      await Future.delayed(const Duration(milliseconds: 300));
    }

    // Step 4: Finally complete the ride with timestamp
    _routeBloc.add(CompleteRideWithTimestamp(rideId: _currentRide.id));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ride completed - all timeline steps logged!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Give user time to see the completion message and updated timeline
      await Future.delayed(const Duration(milliseconds: 1500));

      // Navigate back to show the ride is now in history
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  void _callPassenger() async {
    final phoneNumber = _currentRide.passenger.phoneNumber;
    final uri = Uri.parse('tel:$phoneNumber');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not launch phone app'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _openMapsNavigation(
    double latitude,
    double longitude,
    String address,
  ) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open maps navigation'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showEmergencyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Emergency Alert'),
        content: const Text('Send emergency alert to office and authorities?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Send emergency alert with current location
              _routeBloc.add(
                SendEmergencyAlert(
                  driverId: widget.driverId,
                  routeId: _currentRide.routeId,
                  latitude: _currentRide
                      .pickupLatitude, // Use pickup location as fallback
                  longitude: _currentRide.pickupLongitude,
                  message:
                      'Emergency during ride for ${_currentRide.passenger.fullName}',
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Send Alert',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRideStatusColor(IndividualRideStatus status) {
    switch (status) {
      case IndividualRideStatus.scheduled:
        return Colors.blue;
      case IndividualRideStatus.enRoute:
        return Colors.orange;
      case IndividualRideStatus.arrived:
        return Colors.purple;
      case IndividualRideStatus.pickedUp:
        return Colors.amber;
      case IndividualRideStatus.completed:
        return Colors.green;
      case IndividualRideStatus.cancelled:
        return Colors.red;
    }
  }

  String _getRideStatusText(IndividualRideStatus status) {
    switch (status) {
      case IndividualRideStatus.scheduled:
        return 'Scheduled';
      case IndividualRideStatus.enRoute:
        return 'En Route';
      case IndividualRideStatus.arrived:
        return 'Arrived';
      case IndividualRideStatus.pickedUp:
        return 'Picked Up';
      case IndividualRideStatus.completed:
        return 'Completed';
      case IndividualRideStatus.cancelled:
        return 'Cancelled';
    }
  }

  String _getInitials(String name) {
    return name.split(' ').map((word) => word[0]).take(2).join().toUpperCase();
  }

  void _showEditAddressDialog() {
    final pickupController = TextEditingController(
      text: _currentRide.pickupAddress,
    );
    final dropoffController = TextEditingController(
      text: _currentRide.dropOffAddress,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Addresses'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: pickupController,
                decoration: const InputDecoration(
                  labelText: 'Pickup Address',
                  hintText: 'Enter new pickup address',
                  prefixIcon: Icon(Icons.location_on),
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: dropoffController,
                decoration: const InputDecoration(
                  labelText: 'Drop-off Address',
                  hintText: 'Enter new drop-off address',
                  prefixIcon: Icon(Icons.flag),
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              const Text(
                'Note: Coordinates will be updated automatically',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newPickup = pickupController.text.trim();
              final newDropoff = dropoffController.text.trim();

              if (newPickup.isEmpty || newDropoff.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Both addresses are required'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              Navigator.pop(context);

              // Update addresses
              _routeBloc.add(
                UpdateRideAddress(
                  rideId: _currentRide.id,
                  newPickupAddress: newPickup != _currentRide.pickupAddress
                      ? newPickup
                      : null,
                  newDropOffAddress: newDropoff != _currentRide.dropOffAddress
                      ? newDropoff
                      : null,
                ),
              );

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Address updated successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showCancelRideDialog() {
    final reasonController = TextEditingController();
    String? selectedReason;

    final cancellationReasons = [
      'Passenger not available',
      'Passenger cancelled',
      'Vehicle issue',
      'Traffic/Road conditions',
      'Emergency',
      'Other',
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Cancel Ride'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Please select a reason for cancellation:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 12),
                ...cancellationReasons.map(
                  (reason) => RadioListTile<String>(
                    title: Text(reason),
                    value: reason,
                    groupValue: selectedReason,
                    onChanged: (value) {
                      setState(() {
                        selectedReason = value;
                      });
                    },
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                if (selectedReason == 'Other') ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: reasonController,
                    decoration: const InputDecoration(
                      labelText: 'Specify reason',
                      hintText: 'Enter cancellation reason',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.orange.shade700),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'This action cannot be undone. The ride will be removed from your active rides.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Keep Ride'),
            ),
            ElevatedButton(
              onPressed: selectedReason == null
                  ? null
                  : () {
                      final finalReason = selectedReason == 'Other'
                          ? reasonController.text.trim()
                          : selectedReason!;

                      if (finalReason.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Please provide a cancellation reason',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      Navigator.pop(context);

                      // Cancel the ride
                      _routeBloc.add(
                        CancelIndividualRide(
                          rideId: _currentRide.id,
                          cancellationReason: finalReason,
                          cancelledAt: DateTime.now(),
                        ),
                      );

                      // Navigate back after a short delay
                      Future.delayed(const Duration(milliseconds: 500), () {
                        if (mounted) {
                          Navigator.of(context).pop();
                        }
                      });
                    },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text(
                'Cancel Ride',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
