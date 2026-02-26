import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../shared/models/route_model.dart';
import '../../../../shared/widgets/swipe_button.dart';
import '../bloc/route_bloc.dart';
import '../bloc/route_event.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_logger.dart';

class ActiveRideCard extends StatelessWidget {
  final RouteModel route;

  const ActiveRideCard({super.key, required this.route});

  @override
  Widget build(BuildContext context) {
    final ride = route.rides.isNotEmpty ? route.rides.first : null;

    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'ACTIVE RIDE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  _buildStatusChip(route.status),
                ],
              ),

              const SizedBox(height: 16),

              // Passenger Info
              if (ride != null) ...[
                Row(
                  children: [
                    const Icon(
                      Icons.person,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      ride.passenger.fullName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    const Icon(Icons.phone, color: Colors.grey, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      ride.passenger.phoneNumber,
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 16),

              // Pickup Location
              if (ride != null) ...[
                _buildLocationRow(
                  icon: Icons.location_on,
                  label: 'Pickup',
                  address: ride.pickupAddress,
                  color: Colors.green,
                ),

                const SizedBox(height: 12),

                _buildLocationRow(
                  icon: Icons.flag,
                  label: 'Drop-off',
                  address: ride.dropOffAddress,
                  color: Colors.red,
                ),
              ],

              const SizedBox(height: 16),

              // Time Info
              _buildTimeInfo(),

              const SizedBox(height: 20),

              // Single Action Button (based on ride status)
              if (ride != null) _buildSingleActionButton(context, ride),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSingleActionButton(BuildContext context, IndividualRide ride) {
    // Show only ONE action button based on current ride status
    switch (ride.status) {
      case IndividualRideStatus.scheduled:
        return SwipeButton(
          text: 'Swipe to Navigate Pick',
          onConfirm: () => _navigateToPickup(context),
          backgroundColor: Colors.blue,
        );
      case IndividualRideStatus.enRoute:
        return SwipeButton(
          text: 'Swipe when Arrived',
          onConfirm: () => _arrivedAtPickup(context),
          backgroundColor: Colors.orange,
        );
      case IndividualRideStatus.arrived:
        return SwipeButton(
          text: 'Swipe to Navigate Destination',
          onConfirm: () => _startNavigationToDestination(context),
          backgroundColor: Colors.green,
        );
      case IndividualRideStatus.pickedUp:
        return SwipeButton(
          text: 'Swipe to End Ride',
          onConfirm: () => _completeRide(context),
          backgroundColor: Colors.purple,
        );
      case IndividualRideStatus.completed:
      case IndividualRideStatus.cancelled:
        return const SizedBox.shrink(); // No action button for completed/cancelled rides
    }
  }

  Widget _buildStatusChip(RouteStatus status) {
    Color color;
    String text;

    switch (status) {
      case RouteStatus.scheduled:
        color = Colors.blue;
        text = 'SCHEDULED';
        break;
      case RouteStatus.started:
        color = Colors.orange;
        text = 'STARTED';
        break;
      case RouteStatus.inProgress:
        color = Colors.purple;
        text = 'IN PROGRESS';
        break;
      case RouteStatus.completed:
        color = Colors.green;
        text = 'COMPLETED';
        break;
      case RouteStatus.cancelled:
        color = Colors.red;
        text = 'CANCELLED';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildLocationRow({
    required IconData icon,
    required String label,
    required String address,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                address,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimeInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.schedule, color: Colors.grey, size: 16),
          const SizedBox(width: 8),
          Text(
            'Scheduled: ${_formatDateTime(route.scheduledTime)}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _navigateToPickup(BuildContext context) {
    final ride = route.rides.isNotEmpty ? route.rides.first : null;
    if (ride != null) {
      // Use time-tracked navigation event
      context.read<RouteBloc>().add(StartNavigationToPickup(rideId: ride.id));

      // Also trigger the original navigation (for GPS functionality)
      context.read<RouteBloc>().add(
        NavigateToPickup(
          pickupAddress: ride.pickupAddress,
          pickupLatitude: ride.pickupLatitude,
          pickupLongitude: ride.pickupLongitude,
        ),
      );

      AppLogger.info('Time-tracked navigation started for ride: ${ride.id}');
    }
  }

  void _arrivedAtPickup(BuildContext context) {
    final ride = route.rides.isNotEmpty ? route.rides.first : null;
    if (ride != null) {
      context.read<RouteBloc>().add(ArrivedAtPickup(rideId: ride.id));
      AppLogger.info('Marked arrived at pickup for ride: ${ride.id}');
    }
  }

  void _startNavigationToDestination(BuildContext context) {
    final ride = route.rides.isNotEmpty ? route.rides.first : null;
    if (ride != null) {
      context.read<RouteBloc>().add(
        StartNavigationToDestination(rideId: ride.id),
      );

      // Also start navigation to destination for GPS
      context.read<RouteBloc>().add(
        NavigateToPickup(
          pickupAddress: ride.dropOffAddress,
          pickupLatitude: ride.dropOffLatitude,
          pickupLongitude: ride.dropOffLongitude,
        ),
      );

      AppLogger.info('Started navigation to destination for ride: ${ride.id}');
    }
  }

  void _completeRide(BuildContext context) {
    final ride = route.rides.isNotEmpty ? route.rides.first : null;
    if (ride != null) {
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
      AppLogger.info('Completed ride: ${ride.id}');
    }
  }
}
