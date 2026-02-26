import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../shared/models/route_model.dart';
import '../../../../shared/widgets/swipe_button.dart';
import '../bloc/route_bloc.dart';
import '../bloc/route_event.dart';
import '../bloc/route_state.dart';
import '../widgets/ride_timeline_widget.dart';

class DetailedRideManagementWidget extends StatelessWidget {
  final IndividualRide ride;

  const DetailedRideManagementWidget({super.key, required this.ride});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RouteBloc, RouteState>(
      builder: (context, state) {
        // Get the updated ride data from the current route state
        IndividualRide currentRide = ride;

        if (state is RouteLoaded && state.activeRoute != null) {
          // Find the updated ride in the active route
          final updatedRide = state.activeRoute!.rides.firstWhere(
            (r) => r.id == ride.id,
            orElse: () => ride,
          );
          currentRide = updatedRide;
          print('🔄 DetailedRideManagementWidget: Updated ride data received');
        }

        return Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ride Header
                _buildRideHeader(context, currentRide),

                const SizedBox(height: 16),

                // Current Status Actions
                _buildCurrentActions(context, currentRide),

                const SizedBox(height: 20),

                // Timeline Preview - Always show with current ride data
                Text(
                  'Timeline Progress',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                RideTimelineWidget(
                  key: ValueKey(
                    '${currentRide.id}_${currentRide.hashCode}',
                  ), // Force rebuild when ride changes
                  ride: currentRide,
                  showOnlyCompletedEvents: false,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRideHeader(BuildContext context, IndividualRide currentRide) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Icon(Icons.person, color: Theme.of(context).primaryColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                currentRide.passenger.fullName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                currentRide.passenger.phoneNumber,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getStatusColor(currentRide.status).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _getStatusColor(currentRide.status)),
          ),
          child: Text(
            _getStatusText(currentRide.status),
            style: TextStyle(
              color: _getStatusColor(currentRide.status),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentActions(
    BuildContext context,
    IndividualRide currentRide,
  ) {
    switch (currentRide.status) {
      case IndividualRideStatus.scheduled:
        return _buildScheduledActions(context, currentRide);
      case IndividualRideStatus.enRoute:
        return _buildEnRouteActions(context, currentRide);
      case IndividualRideStatus.arrived:
        return _buildArrivedActions(context, currentRide);
      case IndividualRideStatus.pickedUp:
        return _buildPickedUpActions(context, currentRide);
      case IndividualRideStatus.completed:
        return _buildCompletedActions(context, currentRide);
      case IndividualRideStatus.cancelled:
        return _buildCancelledActions(context, currentRide);
    }
  }

  Widget _buildScheduledActions(
    BuildContext context,
    IndividualRide currentRide,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ready to start pickup',
          style: TextStyle(fontSize: 16, color: Colors.grey[700]),
        ),
        const SizedBox(height: 12),
        SwipeButton(
          text: 'Swipe to Navigate Pick',
          onConfirm: () => _startNavigationToPickup(context),
          backgroundColor: Colors.blue,
        ),
        const SizedBox(height: 8),
        _buildLocationInfo('Pickup Location', currentRide.pickupAddress),
      ],
    );
  }

  Widget _buildEnRouteActions(
    BuildContext context,
    IndividualRide currentRide,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.navigation, color: Colors.blue, size: 20),
            const SizedBox(width: 8),
            Text(
              'En route to pickup',
              style: TextStyle(
                fontSize: 16,
                color: Colors.blue[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        if (currentRide.navigatedToPickupAt != null) ...[
          const SizedBox(height: 8),
          Text(
            'Started: ${_formatTime(currentRide.navigatedToPickupAt!)}',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
        const SizedBox(height: 12),
        SwipeButton(
          text: 'Swipe when Arrived',
          onConfirm: () => _arrivedAtPickup(context),
          backgroundColor: Colors.orange,
        ),
      ],
    );
  }

  Widget _buildArrivedActions(
    BuildContext context,
    IndividualRide currentRide,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.location_on, color: Colors.green, size: 20),
            const SizedBox(width: 8),
            Text(
              'Arrived at pickup location',
              style: TextStyle(
                fontSize: 16,
                color: Colors.green[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        if (currentRide.arrivedAtPickupAt != null) ...[
          const SizedBox(height: 8),
          Text(
            'Arrived: ${_formatTime(currentRide.arrivedAtPickupAt!)}',
            style: TextStyle(color: Colors.grey[600]),
          ),
          if (currentRide.navigationToPickupDuration != null)
            Text(
              'Travel time: ${currentRide.navigationToPickupDuration} minutes',
              style: TextStyle(color: Colors.blue[600], fontSize: 12),
            ),
        ],
        const SizedBox(height: 12),
        SwipeButton(
          text: 'Swipe to Navigate Destination',
          onConfirm: () => _startNavigationToDestination(context),
          backgroundColor: Colors.green,
        ),
      ],
    );
  }

  Widget _buildPickedUpActions(
    BuildContext context,
    IndividualRide currentRide,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.person, color: Colors.purple, size: 20),
            const SizedBox(width: 8),
            Text(
              'Passenger picked up',
              style: TextStyle(
                fontSize: 16,
                color: Colors.purple[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        if (currentRide.passengerPickedUpAt != null) ...[
          const SizedBox(height: 8),
          Text(
            'Picked up: ${_formatTime(currentRide.passengerPickedUpAt!)}',
            style: TextStyle(color: Colors.grey[600]),
          ),
          if (currentRide.waitingAtPickupDuration != null)
            Text(
              'Waiting time: ${currentRide.waitingAtPickupDuration} minutes',
              style: TextStyle(color: Colors.orange[600], fontSize: 12),
            ),
        ],
        const SizedBox(height: 12),
        _buildLocationInfo('Destination', currentRide.dropOffAddress),
        const SizedBox(height: 12),
        SwipeButton(
          text: 'Swipe to End Ride',
          onConfirm: () => _completeRide(context),
          backgroundColor: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildCompletedActions(
    BuildContext context,
    IndividualRide currentRide,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 24),
              const SizedBox(width: 12),
              Text(
                'Ride Completed Successfully',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.green[800],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (ride.rideCompletedAt != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Completed: ${_formatTime(ride.rideCompletedAt!)}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const Spacer(),
                if (ride.totalRideDuration != null)
                  Text(
                    'Total time: ${ride.totalRideDuration} minutes',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCancelledActions(
    BuildContext context,
    IndividualRide currentRide,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.cancel, color: Colors.red, size: 24),
          const SizedBox(width: 12),
          Text(
            'Ride Cancelled',
            style: TextStyle(
              fontSize: 16,
              color: Colors.red[800],
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationInfo(String label, String address) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.location_on, color: Colors.grey[600], size: 16),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          Expanded(
            child: Text(address, style: TextStyle(color: Colors.grey[700])),
          ),
        ],
      ),
    );
  }

  // Event handlers with automatic timestamp tracking

  void _startNavigationToPickup(BuildContext context) {
    context.read<RouteBloc>().add(StartNavigationToPickup(rideId: ride.id));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Navigation to pickup started - time logged!'),
      ),
    );
  }

  void _arrivedAtPickup(BuildContext context) {
    context.read<RouteBloc>().add(ArrivedAtPickup(rideId: ride.id));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Arrival at pickup logged - time saved!')),
    );
  }

  void _startNavigationToDestination(BuildContext context) {
    // First mark passenger as picked up, then start navigation to destination
    context.read<RouteBloc>().add(PassengerPickedUp(rideId: ride.id));
    context.read<RouteBloc>().add(
      StartNavigationToDestination(rideId: ride.id),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Passenger picked up - navigating to destination!'),
      ),
    );
  }

  void _completeRide(BuildContext context) {
    // Ensure all timeline steps are completed before final completion
    if (ride.passengerPickedUpAt == null) {
      context.read<RouteBloc>().add(PassengerPickedUp(rideId: ride.id));
    }

    if (ride.navigatedToDestinationAt == null) {
      context.read<RouteBloc>().add(
        StartNavigationToDestination(rideId: ride.id),
      );
    }

    context.read<RouteBloc>().add(CompleteRideWithTimestamp(rideId: ride.id));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text('Ride completed and saved to history!')),
          ],
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  // Helper methods

  Color _getStatusColor(IndividualRideStatus status) {
    switch (status) {
      case IndividualRideStatus.scheduled:
        return Colors.blue;
      case IndividualRideStatus.enRoute:
        return Colors.orange;
      case IndividualRideStatus.arrived:
        return Colors.purple;
      case IndividualRideStatus.pickedUp:
        return Colors.cyan;
      case IndividualRideStatus.completed:
        return Colors.green;
      case IndividualRideStatus.cancelled:
        return Colors.red;
    }
  }

  String _getStatusText(IndividualRideStatus status) {
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

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
