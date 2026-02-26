import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../shared/models/route_model.dart';
import '../../../../core/services/ride_history_service.dart';
import '../bloc/route_bloc.dart';
import '../bloc/route_event.dart';
import '../bloc/route_state.dart';

enum DateFilter { today, week, month, custom, all }

class RideHistoryScreen extends StatefulWidget {
  const RideHistoryScreen({super.key});

  @override
  State<RideHistoryScreen> createState() => _RideHistoryScreenState();
}

class _RideHistoryScreenState extends State<RideHistoryScreen> {
  DateFilter _selectedFilter = DateFilter.all;
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  @override
  void initState() {
    super.initState();
    // Load ride history when screen opens
    _loadHistory();
  }

  void _loadHistory() async {
    print('📱 Requesting ride history from RouteBloc...');

    // Debug: Print stored history data
    await RideHistoryService.debugPrintStoredHistory();

    context.read<RouteBloc>().add(LoadRideHistory('current_driver_id'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activities'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filter',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadHistory,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: BlocConsumer<RouteBloc, RouteState>(
        listener: (context, state) {
          // Automatically reload history when a ride is completed
          if (state is RouteCompleted) {
            print('🔄 Ride completed - Auto-reloading history');
            // Immediate reload when route is completed
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) {
                _loadHistory();
              }
            });
          } else if (state is IndividualRideUpdated) {
            // Check if the ride was completed
            if (state.ride.status == IndividualRideStatus.completed) {
              print('🔄 Individual ride completed - Auto-reloading history');
              Future.delayed(const Duration(milliseconds: 300), () {
                if (mounted) {
                  _loadHistory();
                }
              });
            }
          }
        },
        builder: (context, state) {
          print('🏗️ RideHistoryScreen builder: State = ${state.runtimeType}');

          if (state is RouteLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is RouteError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading activities',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      context.read<RouteBloc>().add(
                        LoadRideHistory('current_driver_id'),
                      );
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is RideHistoryLoaded) {
            print(
              '📋 RideHistoryScreen: Received ${state.historyRoutes.length} routes',
            );
            final allRides = _extractRidesFromRoutes(state.historyRoutes);
            print(
              '📋 RideHistoryScreen: Extracted ${allRides.length} individual rides',
            );

            // Apply date filter
            final rides = _filterRidesByDate(allRides);
            print(
              '📋 RideHistoryScreen: After filter (${_getFilterLabel()}): ${rides.length} rides',
            );

            return Column(
              children: [
                // Filter indicator
                if (_selectedFilter != DateFilter.all)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    child: Row(
                      children: [
                        Icon(
                          Icons.filter_list,
                          size: 16,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Filter: ${_getFilterLabel()}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedFilter = DateFilter.all;
                              _customStartDate = null;
                              _customEndDate = null;
                            });
                          },
                          child: const Text(
                            'Clear',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),

                if (rides.isEmpty)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No activities found',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _selectedFilter != DateFilter.all
                                ? 'No rides found for selected period'
                                : 'Complete some rides to see your activities here',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ),
                  )
                else ...[
                  // Summary Stats
                  _buildSummaryStats(context, rides),

                  // Ride List
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.only(
                        left: 12,
                        right: 12,
                        top: 12,
                        bottom: 100, // Extra padding to ensure content is not hidden by bottom nav
                      ),
                      itemCount: rides.length,
                      itemBuilder: (context, index) {
                        final ride = rides[index];
                        return _buildRideHistoryCard(context, ride);
                      },
                    ),
                  ),
                ],
              ],
            );
          }

          return const Center(child: Text('Loading activities...'));
        },
      ),
    );
  }

  Widget _buildSummaryStats(BuildContext context, List<IndividualRide> rides) {
    final completedRides = rides
        .where((r) => r.status == IndividualRideStatus.completed)
        .length;
    final totalDuration = rides
        .where((r) => r.totalRideDuration != null)
        .fold<int>(0, (sum, r) => sum + r.totalRideDuration!);
    final averageDuration = completedRides > 0
        ? totalDuration / completedRides
        : 0;

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: _buildStatItem(
              'Total Rides',
              rides.length.toString(),
              Icons.directions_car,
            ),
          ),
          Container(width: 1, height: 30, color: Colors.white30),
          Expanded(
            child: _buildStatItem(
              'Completed',
              completedRides.toString(),
              Icons.check_circle,
            ),
          ),
          Container(width: 1, height: 30, color: Colors.white30),
          Expanded(
            child: _buildStatItem(
              'Avg Duration',
              averageDuration > 0 ? '${averageDuration.round()}m' : 'N/A',
              Icons.timer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildRideHistoryCard(BuildContext context, IndividualRide ride) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          leading: CircleAvatar(
            backgroundColor: _getStatusColor(ride.status).withOpacity(0.1),
            radius: 20,
            child: Icon(
              _getStatusIcon(ride.status),
              color: _getStatusColor(ride.status),
              size: 20,
            ),
          ),
          title: Text(
            ride.passenger.fullName,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              // Ride ID
              Row(
                children: [
                  Icon(
                    Icons.confirmation_number,
                    size: 12,
                    color: Colors.purple[700],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'ID: ${ride.id}',
                    style: TextStyle(
                      color: Colors.purple[700],
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Date and Time Row
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 12, color: Colors.blue[700]),
                  const SizedBox(width: 4),
                  Text(
                    _formatRideDateTime(ride),
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 12,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${ride.pickupAddress} → ${ride.dropOffAddress}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(ride.status).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _getStatusText(ride.status),
                      style: TextStyle(
                        color: _getStatusColor(ride.status),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (ride.totalRideDuration != null)
                    Text(
                      _formatDuration(ride.totalRideDuration!),
                      style: TextStyle(color: Colors.grey[600], fontSize: 11),
                    ),
                  const SizedBox(width: 8),
                  if (ride.distance != null)
                    Text(
                      '${(ride.distance! / 1000).toStringAsFixed(1)} km',
                      style: TextStyle(color: Colors.grey[600], fontSize: 11),
                    ),
                ],
              ),
            ],
          ),
          children: [_buildCompactTimeline(ride)],
        ),
      ),
    );
  }

  Widget _buildCompactTimeline(IndividualRide ride) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Ride Timeline',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const Spacer(),
              if (ride.totalRideDuration != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green, width: 1),
                  ),
                  child: Text(
                    'Total: ${_formatDuration(ride.totalRideDuration!)}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Build timeline with durations between events
          ..._buildTimelineWithDurations(ride),
        ],
      ),
    );
  }

  List<Widget> _buildTimelineWithDurations(IndividualRide ride) {
    List<Widget> widgets = [];

    // Track previous timestamp for duration calculation
    DateTime? previousTime;
    bool isFirstEvent = true;

    // 1. Navigate to Pickup
    if (ride.navigatedToPickupAt != null) {
      widgets.add(
        _buildTimelineEvent(
          'Navigate to Pickup',
          ride.navigatedToPickupAt!,
          Icons.navigation,
          Colors.blue[700]!,
          isFirst: isFirstEvent,
        ),
      );
      previousTime = ride.navigatedToPickupAt;
      isFirstEvent = false;
    }

    // 2. Arrived at Pickup (with navigation duration)
    if (ride.arrivedAtPickupAt != null) {
      if (previousTime != null) {
        widgets.add(
          _buildDurationIndicator(
            previousTime,
            ride.arrivedAtPickupAt!,
            'navigation',
          ),
        );
      }
      widgets.add(
        _buildTimelineEvent(
          'Arrived at Pickup',
          ride.arrivedAtPickupAt!,
          Icons.location_on,
          Colors.orange[700]!,
        ),
      );
      previousTime = ride.arrivedAtPickupAt;
    }

    // 3. Passenger Picked Up (with waiting duration)
    if (ride.passengerPickedUpAt != null) {
      if (previousTime != null) {
        widgets.add(
          _buildDurationIndicator(
            previousTime,
            ride.passengerPickedUpAt!,
            'waiting',
          ),
        );
      }
      widgets.add(
        _buildTimelineEvent(
          'Passenger Picked Up',
          ride.passengerPickedUpAt!,
          Icons.person_add,
          Colors.green,
        ),
      );
      previousTime = ride.passengerPickedUpAt;
    }

    // 4. Navigate to Destination
    if (ride.navigatedToDestinationAt != null) {
      // Usually same time as pickup, so no duration shown
      widgets.add(
        _buildTimelineEvent(
          'Navigate to Destination',
          ride.navigatedToDestinationAt!,
          Icons.directions,
          Colors.cyan[700]!,
        ),
      );
      previousTime = ride.navigatedToDestinationAt;
    }

    // 5. Arrived at Destination (with trip duration)
    if (ride.arrivedAtDestinationAt != null) {
      if (previousTime != null) {
        widgets.add(
          _buildDurationIndicator(
            previousTime,
            ride.arrivedAtDestinationAt!,
            'trip',
          ),
        );
      }
      widgets.add(
        _buildTimelineEvent(
          'Arrived at Destination',
          ride.arrivedAtDestinationAt!,
          Icons.flag,
          Colors.teal[700]!,
        ),
      );
      previousTime = ride.arrivedAtDestinationAt;
    }

    // 6. Ride Completed (with completion duration)
    if (ride.rideCompletedAt != null) {
      if (previousTime != null) {
        widgets.add(
          _buildDurationIndicator(
            previousTime,
            ride.rideCompletedAt!,
            'completion',
          ),
        );
      }
      widgets.add(
        _buildTimelineEvent(
          'Ride Completed',
          ride.rideCompletedAt!,
          Icons.check_circle,
          Colors.purple,
          isLast: true,
        ),
      );
    }

    return widgets;
  }

  Widget _buildDurationIndicator(DateTime start, DateTime end, String label) {
    final duration = end.difference(start).inMinutes;

    String durationText;
    if (duration < 1) {
      durationText = '< 1 min';
    } else {
      durationText = _formatDuration(duration);
    }

    String labelText;
    IconData icon;
    Color color;

    switch (label) {
      case 'navigation':
        labelText = 'navigation';
        icon = Icons.navigation;
        color = Colors.blue[700]!;
        break;
      case 'waiting':
        labelText = 'waiting';
        icon = Icons.timer;
        color = Colors.orange[700]!;
        break;
      case 'trip':
        labelText = 'trip time';
        icon = Icons.directions_car;
        color = Colors.green[700]!;
        break;
      case 'completion':
        labelText = 'finalizing';
        icon = Icons.check;
        color = Colors.purple;
        break;
      default:
        labelText = '';
        icon = Icons.arrow_downward;
        color = Colors.grey;
    }

    return Padding(
      padding: const EdgeInsets.only(left: 10),
      child: Row(
        children: [
          // Vertical line
          Container(width: 2, height: 24, color: Colors.grey[300]),
          const SizedBox(width: 10),
          // Duration badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.3), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 12, color: color),
                const SizedBox(width: 4),
                Text(
                  '$durationText $labelText',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineEvent(
    String title,
    DateTime time,
    IconData icon,
    Color color, {
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline indicator
        Column(
          children: [
            if (!isFirst)
              Container(width: 2, height: 8, color: Colors.grey[300]),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
              ),
              child: Icon(icon, size: 10, color: color),
            ),
            if (!isLast)
              Container(width: 2, height: 8, color: Colors.grey[300]),
          ],
        ),
        const SizedBox(width: 12),

        // Event details
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('h:mm a').format(time), // 12-hour format
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<IndividualRide> _extractRidesFromRoutes(List<RouteModel> routes) {
    List<IndividualRide> allRides = [];
    for (final route in routes) {
      allRides.addAll(route.rides);
    }
    // Sort by creation date (newest first)
    allRides.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return allRides;
  }

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

  IconData _getStatusIcon(IndividualRideStatus status) {
    switch (status) {
      case IndividualRideStatus.scheduled:
        return Icons.schedule;
      case IndividualRideStatus.enRoute:
        return Icons.navigation;
      case IndividualRideStatus.arrived:
        return Icons.location_on;
      case IndividualRideStatus.pickedUp:
        return Icons.person;
      case IndividualRideStatus.completed:
        return Icons.check_circle;
      case IndividualRideStatus.cancelled:
        return Icons.cancel;
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

  String _formatDuration(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours}h ${mins}m';
  }

  String _formatRideDateTime(IndividualRide ride) {
    // Prioritize different timestamps for displaying the ride date/time
    DateTime rideDateTime =
        ride.scheduledPickupTime ??
        ride.rideCompletedAt ??
        ride.actualPickupTime ??
        ride.createdAt;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final rideDate = DateTime(
      rideDateTime.year,
      rideDateTime.month,
      rideDateTime.day,
    );

    String dateStr;
    if (rideDate == today) {
      dateStr = 'Today';
    } else if (rideDate == yesterday) {
      dateStr = 'Yesterday';
    } else {
      dateStr = DateFormat('MMM dd, yyyy').format(rideDateTime);
    }

    String timeStr = DateFormat('h:mm a').format(rideDateTime);
    return '$dateStr at $timeStr';
  }

  // Filter rides based on selected date filter
  List<IndividualRide> _filterRidesByDate(List<IndividualRide> rides) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (_selectedFilter) {
      case DateFilter.all:
        return rides;

      case DateFilter.today:
        return rides.where((ride) {
          final completedDate = ride.rideCompletedAt ?? ride.actualDropOffTime;
          if (completedDate == null) return false;
          final dateOnly = DateTime(
            completedDate.year,
            completedDate.month,
            completedDate.day,
          );
          return dateOnly.isAtSameMomentAs(today);
        }).toList();

      case DateFilter.week:
        final weekAgo = today.subtract(const Duration(days: 7));
        return rides.where((ride) {
          final completedDate = ride.rideCompletedAt ?? ride.actualDropOffTime;
          if (completedDate == null) return false;
          return completedDate.isAfter(weekAgo);
        }).toList();

      case DateFilter.month:
        final monthAgo = DateTime(now.year, now.month - 1, now.day);
        return rides.where((ride) {
          final completedDate = ride.rideCompletedAt ?? ride.actualDropOffTime;
          if (completedDate == null) return false;
          return completedDate.isAfter(monthAgo);
        }).toList();

      case DateFilter.custom:
        if (_customStartDate == null && _customEndDate == null) return rides;
        return rides.where((ride) {
          final completedDate = ride.rideCompletedAt ?? ride.actualDropOffTime;
          if (completedDate == null) return false;

          if (_customStartDate != null &&
              completedDate.isBefore(_customStartDate!)) {
            return false;
          }
          if (_customEndDate != null) {
            final endOfDay = DateTime(
              _customEndDate!.year,
              _customEndDate!.month,
              _customEndDate!.day,
              23,
              59,
              59,
            );
            if (completedDate.isAfter(endOfDay)) {
              return false;
            }
          }
          return true;
        }).toList();
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Filter Activities'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RadioListTile<DateFilter>(
                      title: const Text('All Time'),
                      subtitle: const Text('Show all activities'),
                      value: DateFilter.all,
                      groupValue: _selectedFilter,
                      onChanged: (DateFilter? value) {
                        setDialogState(() {
                          _selectedFilter = value!;
                        });
                      },
                    ),
                    RadioListTile<DateFilter>(
                      title: const Text('Today'),
                      subtitle: Text(
                        DateFormat('MMM dd, yyyy').format(DateTime.now()),
                      ),
                      value: DateFilter.today,
                      groupValue: _selectedFilter,
                      onChanged: (DateFilter? value) {
                        setDialogState(() {
                          _selectedFilter = value!;
                        });
                      },
                    ),
                    RadioListTile<DateFilter>(
                      title: const Text('This Week'),
                      subtitle: const Text('Last 7 days'),
                      value: DateFilter.week,
                      groupValue: _selectedFilter,
                      onChanged: (DateFilter? value) {
                        setDialogState(() {
                          _selectedFilter = value!;
                        });
                      },
                    ),
                    RadioListTile<DateFilter>(
                      title: const Text('This Month'),
                      subtitle: const Text('Last 30 days'),
                      value: DateFilter.month,
                      groupValue: _selectedFilter,
                      onChanged: (DateFilter? value) {
                        setDialogState(() {
                          _selectedFilter = value!;
                        });
                      },
                    ),
                    RadioListTile<DateFilter>(
                      title: const Text('Custom Date Range'),
                      subtitle:
                          _customStartDate != null || _customEndDate != null
                          ? Text(
                              '${_customStartDate != null ? DateFormat('MMM dd').format(_customStartDate!) : 'Start'} - ${_customEndDate != null ? DateFormat('MMM dd, yyyy').format(_customEndDate!) : 'End'}',
                            )
                          : const Text('Select custom dates'),
                      value: DateFilter.custom,
                      groupValue: _selectedFilter,
                      onChanged: (DateFilter? value) {
                        setDialogState(() {
                          _selectedFilter = value!;
                        });
                      },
                    ),
                    if (_selectedFilter == DateFilter.custom) ...[
                      const SizedBox(height: 16),
                      ListTile(
                        leading: const Icon(Icons.calendar_today),
                        title: Text(
                          _customStartDate != null
                              ? 'Start: ${DateFormat('MMM dd, yyyy').format(_customStartDate!)}'
                              : 'Select Start Date',
                        ),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _customStartDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setDialogState(() {
                              _customStartDate = date;
                            });
                          }
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.calendar_today),
                        title: Text(
                          _customEndDate != null
                              ? 'End: ${DateFormat('MMM dd, yyyy').format(_customEndDate!)}'
                              : 'Select End Date',
                        ),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _customEndDate ?? DateTime.now(),
                            firstDate: _customStartDate ?? DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setDialogState(() {
                              _customEndDate = date;
                            });
                          }
                        },
                      ),
                      if (_customStartDate != null || _customEndDate != null)
                        TextButton.icon(
                          icon: const Icon(Icons.clear),
                          label: const Text('Clear Dates'),
                          onPressed: () {
                            setDialogState(() {
                              _customStartDate = null;
                              _customEndDate = null;
                            });
                          },
                        ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      // Apply filter
                    });
                    Navigator.of(context).pop();
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _getFilterLabel() {
    switch (_selectedFilter) {
      case DateFilter.all:
        return 'All Time';
      case DateFilter.today:
        return 'Today';
      case DateFilter.week:
        return 'This Week';
      case DateFilter.month:
        return 'This Month';
      case DateFilter.custom:
        if (_customStartDate != null || _customEndDate != null) {
          return 'Custom Range';
        }
        return 'Custom';
    }
  }
}
