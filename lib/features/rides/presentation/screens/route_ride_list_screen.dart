import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../../../../shared/widgets/custom_app_bar.dart';
import '../../../../shared/widgets/persistent_navigation_wrapper.dart';
import '../../../../shared/models/route_model.dart';
import '../../../../shared/models/driver_model.dart';
import '../../../../core/theme/app_theme.dart';

import '../../../rides/presentation/screens/individual_ride_detail_screen.dart';
import '../bloc/route_bloc.dart';
import '../bloc/route_event.dart';
import '../bloc/route_state.dart';

class RouteRideListScreen extends StatefulWidget {
  final String driverId;
  final DriverModel? driver;

  const RouteRideListScreen({super.key, required this.driverId, this.driver});

  @override
  State<RouteRideListScreen> createState() => RouteRideListScreenState();
}

class RouteRideListScreenState extends State<RouteRideListScreen>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  late RouteBloc _routeBloc;
  bool _needsReload = false;

  @override
  bool get wantKeepAlive => true; // Keep state alive with IndexedStack

  // Public method to reload active route - can be called from parent
  void reloadActiveRoute() {
    print('🔄 [RIDES SCREEN] reloadActiveRoute called from parent');
    _routeBloc.add(LoadActiveRoute(widget.driverId));
  }

  @override
  void initState() {
    super.initState();
    _routeBloc = BlocProvider.of<RouteBloc>(context);
    _routeBloc.add(LoadActiveRoute(widget.driverId));
    WidgetsBinding.instance.addObserver(this);
    print('🟢 [RIDES SCREEN] initState called - Loading active route');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Reload when app comes back to foreground
    if (state == AppLifecycleState.resumed && _needsReload) {
      print('🔄 [RIDES SCREEN] App resumed - Reloading active route');
      _routeBloc.add(LoadActiveRoute(widget.driverId));
      _needsReload = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    // Check if we can pop - if yes, we're navigated from another screen (like profile)
    final bool canPop = Navigator.canPop(context);

    return NotificationListener<RouteScreenReloadNotification>(
      onNotification: (notification) {
        print('🔔 [RIDES SCREEN] Reload notification received');
        _routeBloc.add(LoadActiveRoute(widget.driverId));
        return true; // Consume the notification
      },
      child: Scaffold(
      appBar: widget.driver != null
          ? CustomAppBar(
              title: 'Route & Rides',
              driver: widget.driver!,
              onRefresh: () => _routeBloc.add(LoadActiveRoute(widget.driverId)),
              showBackButton:
                  canPop, // Show back button if navigated from another screen
            )
          : AppBar(
              title: const Text('Route & Rides'),
              backgroundColor: Theme.of(context).colorScheme.inversePrimary,
              automaticallyImplyLeading: canPop,
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
          } else if (state is RouteSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
            // Force reload to ensure the route is displayed
            // This handles cases where the screen is already visible
            Future.delayed(const Duration(milliseconds: 800), () {
              if (mounted) {
                print(
                  '🔄 RouteSuccess detected - Force reloading active route',
                );
                _routeBloc.add(LoadActiveRoute(widget.driverId));
              }
            });
          } else if (state is RouteCompleted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
            // Refresh to show no active routes after completion
            _routeBloc.add(LoadActiveRoute(widget.driverId));
          }
        },
        builder: (context, state) {
          if (state is RouteLoading) {
            return const LoadingOverlay(
              isLoading: true,
              child: SizedBox.expand(),
            );
          }

          if (state is RouteError) {
            return _buildErrorState(state.message);
          }

          if (state is RouteLoaded && state.activeRoute == null) {
            return _buildNoActiveRoute();
          }

          if (state is RouteLoaded && state.activeRoute != null) {
            return _buildRouteContent(state.activeRoute!);
          }

          if (state is RouteUpdating) {
            return LoadingOverlay(
              isLoading: true,
              loadingText: state.action,
              child: _buildRouteContent(state.currentRoute),
            );
          }

          if (state is RouteSuccess) {
            return _buildRouteContent(state.route);
          }

          if (state is RouteCompleted) {
            return _buildNoActiveRoute();
          }

          return _buildNoActiveRoute();
        },
      ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return RefreshIndicator(
      onRefresh: () async {
        _routeBloc.add(LoadActiveRoute(widget.driverId));
        // Wait a bit for the loading to start
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: 120, // Extra padding to ensure content is not hidden by bottom nav
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height - 200,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red[700],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Oops! Something went wrong',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.grey[800],
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {
                    _routeBloc.add(LoadActiveRoute(widget.driverId));
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Pull down to refresh',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoActiveRoute() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 120, // Extra padding to ensure content is not hidden by bottom nav
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Always show statistics even when no active route
          _buildEmptyRouteStats(),
          const SizedBox(height: 24),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.route, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No Active Route',
                  style: Theme.of(
                    context,
                  ).textTheme.headlineSmall?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'You don\'t have any active routes at the moment.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteContent(RouteModel route) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 120, // Extra padding to ensure content is not hidden by bottom nav (66px nav + padding + FAB)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRouteHeader(route),
          const SizedBox(height: 16),
          _buildRouteStats(route),
          const SizedBox(height: 24),
          _buildRidesList(route),
          const SizedBox(height: 24),
          _buildRouteActions(route),
        ],
      ),
    );
  }

  Widget _buildRouteHeader(RouteModel route) {
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
                  '${route.type.name.toUpperCase()} ROUTE',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getRouteStatusColor(route.status),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _getRouteStatusText(route.status),
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
                Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Scheduled: ${_formatTime(route.scheduledTime)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    route.type == RouteType.morning
                        ? 'Multiple homes → ${route.officeAddress}'
                        : '${route.officeAddress} → Multiple destinations',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            if (route.startedAt != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.play_arrow, size: 16, color: Colors.green[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Started: ${_formatTime(route.startedAt!)}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.green[600]),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRouteStats(RouteModel route) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Scheduled Rides',
            route.totalPassengers.toString(),
            Icons.route,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Completed',
            route.completedRides.toString(),
            Icons.check_circle,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Pending',
            route.pendingRides.toString(),
            Icons.pending,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyRouteStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Scheduled Rides',
            '0',
            Icons.route,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Completed',
            '0',
            Icons.check_circle,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard('Pending', '0', Icons.pending, Colors.orange),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRidesList(RouteModel route) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Passenger Rides',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: route.rides.length,
          itemBuilder: (context, index) {
            final ride = route.rides[index];
            return _buildRideItem(ride, index + 1);
          },
        ),
      ],
    );
  }

  Widget _buildRideItem(IndividualRide ride, int position) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _openRideDetail(ride),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: _getRideStatusColor(ride.status),
                    child: Text(
                      position.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ride.passenger.fullName,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${ride.passenger.department} • ${ride.passenger.employeeId}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getRideStatusColor(ride.status),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getRideStatusText(ride.status),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ride.pickupAddress,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.location_off, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ride.dropOffAddress,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (ride.scheduledPickupTime != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      'Scheduled: ${_formatTime(ride.scheduledPickupTime!)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
              if (!ride.isPresent) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person_off, size: 16, color: Colors.red[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Not Present',
                        style: TextStyle(
                          color: Colors.red[600],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRouteActions(RouteModel route) {
    if (route.status == RouteStatus.completed) {
      return const SizedBox.shrink();
    }

    // Removed "Start Route" button - routes are started automatically or manually
    return Column(
      children: [
        if (route.status == RouteStatus.inProgress) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: route.isComplete ? () => _completeRoute(route) : null,
              icon: const Icon(Icons.check_circle),
              label: const Text('Complete Route'),
              style: ElevatedButton.styleFrom(
                backgroundColor: route.isComplete ? Colors.green : Colors.grey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _openRideDetail(IndividualRide ride) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (context) =>
            IndividualRideDetailScreen(ride: ride, driverId: widget.driverId),
      ),
    );
  }

  void _completeRoute(RouteModel route) {
    _routeBloc.add(CompleteRoute(route.id));
  }

  Color _getRouteStatusColor(RouteStatus status) {
    switch (status) {
      case RouteStatus.scheduled:
        return Colors.blue;
      case RouteStatus.started:
      case RouteStatus.inProgress:
        return Colors.orange;
      case RouteStatus.completed:
        return Colors.green;
      case RouteStatus.cancelled:
        return Colors.red;
    }
  }

  String _getRouteStatusText(RouteStatus status) {
    switch (status) {
      case RouteStatus.scheduled:
        return 'Scheduled';
      case RouteStatus.started:
        return 'Started';
      case RouteStatus.inProgress:
        return 'In Progress';
      case RouteStatus.completed:
        return 'Completed';
      case RouteStatus.cancelled:
        return 'Cancelled';
    }
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

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
