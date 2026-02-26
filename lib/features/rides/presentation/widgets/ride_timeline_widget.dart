import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../../shared/models/route_model.dart';

class RideTimelineWidget extends StatefulWidget {
  final IndividualRide ride;
  final bool showOnlyCompletedEvents;

  const RideTimelineWidget({
    super.key,
    required this.ride,
    this.showOnlyCompletedEvents = false,
  });

  @override
  State<RideTimelineWidget> createState() => _RideTimelineWidgetState();
}

class _RideTimelineWidgetState extends State<RideTimelineWidget>
    with TickerProviderStateMixin {
  late AnimationController _carAnimationController;
  late AnimationController _pulseController;
  late AnimationController _liquidController;
  late Animation<double> _carPosition;
  late Animation<double> _pulseAnimation;
  late Animation<double> _liquidFlow;

  @override
  void initState() {
    super.initState();

    // Car movement animation
    _carAnimationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    // Pulse animation for active elements
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    // Liquid flow animation
    _liquidController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    _carPosition = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _carAnimationController,
        curve: Curves.easeInOutCubic,
      ),
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _liquidFlow = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _liquidController, curve: Curves.linear));

    // Start car animation based on completion progress
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateCarPosition();
    });
  }

  @override
  void didUpdateWidget(RideTimelineWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if the ride data has changed
    if (oldWidget.ride != widget.ride) {
      print('🔄 Timeline widget updating - ride changed');
      // Update car position when ride data changes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateCarPosition();
      });
    }
  }

  @override
  void dispose() {
    _carAnimationController.dispose();
    _pulseController.dispose();
    _liquidController.dispose();
    super.dispose();
  }

  void _updateCarPosition() {
    final completedEvents = _getCompletedEventsCount();
    final totalEvents = _getAllPossibleEvents().length;
    final progress = totalEvents > 0 ? completedEvents / totalEvents : 0.0;

    print(
      '🚗 Updating car position: $completedEvents/$totalEvents = $progress',
    );
    _carAnimationController.animateTo(progress);
  }

  @override
  Widget build(BuildContext context) {
    final timeline = widget.ride.timeline;
    final filteredTimeline = widget.showOnlyCompletedEvents
        ? timeline
        : _getAllPossibleEvents();

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.timeline,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Ride Timeline',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (widget.ride.totalRideDuration != null)
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
                      'Total: ${_formatDuration(widget.ride.totalRideDuration!)}',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 6),

            // Horizontal Timeline
            Builder(
              builder: (context) {
                print(
                  '🚗 Building HORIZONTAL 3D Timeline with ${filteredTimeline.length} events',
                );
                return _buildHorizontalTimeline(context, filteredTimeline);
              },
            ),

            // Summary statistics if ride is completed
            if (widget.ride.hasCompleteTimeline) ...[
              const SizedBox(height: 6),
              _buildCompactRideSummary(context),
            ],
          ],
        ),
      ),
    );
  }

  List<RideTimelineEvent> _getAllPossibleEvents() {
    List<RideTimelineEvent> events = [];
    final now = DateTime.now();

    // Always show these events, completed or placeholder
    events.add(
      RideTimelineEvent(
        type: TimelineEventType.navigatedToPickup,
        timestamp: widget.ride.navigatedToPickupAt ?? now,
        description: 'Navigate to pickup location',
      ),
    );

    events.add(
      RideTimelineEvent(
        type: TimelineEventType.arrivedAtPickup,
        timestamp: widget.ride.arrivedAtPickupAt ?? now,
        description: 'Arrive at pickup location',
        duration: widget.ride.navigationToPickupDuration,
      ),
    );

    events.add(
      RideTimelineEvent(
        type: TimelineEventType.passengerPickedUp,
        timestamp: widget.ride.passengerPickedUpAt ?? now,
        description: 'Pick up passenger',
        duration: widget.ride.waitingAtPickupDuration,
      ),
    );

    events.add(
      RideTimelineEvent(
        type: TimelineEventType.navigatedToDestination,
        timestamp: widget.ride.navigatedToDestinationAt ?? now,
        description: 'Navigate to destination',
      ),
    );

    events.add(
      RideTimelineEvent(
        type: TimelineEventType.arrivedAtDestination,
        timestamp: widget.ride.arrivedAtDestinationAt ?? now,
        description: 'Arrive at destination',
        duration: widget.ride.navigationToDestinationDuration,
      ),
    );

    // Note: Removed 'rideCompleted' event from timeline as per user request
    // The ride completion is handled through status updates, not timeline events

    return events;
  }

  Widget _buildHorizontalTimeline(
    BuildContext context,
    List<RideTimelineEvent> timeline,
  ) {
    print('🚗 _buildHorizontalTimeline called with ${timeline.length} events');
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.red[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[400]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background gradient
          Container(
            height: 55,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blue[50]!.withOpacity(0.3),
                  Colors.purple[50]!.withOpacity(0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
          ),

          // Liquid flowing background
          AnimatedBuilder(
            animation: _liquidFlow,
            builder: (context, child) {
              return Container(
                height: 55,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(-1.0 + 2.0 * _liquidFlow.value, -1.0),
                    end: Alignment(1.0 + 2.0 * _liquidFlow.value, 1.0),
                    colors: [
                      Colors.transparent,
                      Colors.blue.withOpacity(0.1),
                      Colors.purple.withOpacity(0.05),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.3, 0.7, 1.0],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
              );
            },
          ),

          // Road/Track Background
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: LinearGradient(
                  colors: [
                    Colors.grey[300]!,
                    Colors.grey[400]!,
                    Colors.grey[300]!,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Road lane dividers
                  ...List.generate(timeline.length - 1, (index) {
                    return Positioned(
                      left: (index + 1) * 100 - 50,
                      top: 2,
                      child: Container(
                        width: 2,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    );
                  }),
                  // Progress checkpoints
                  ...timeline.asMap().entries.map((entry) {
                    final index = entry.key;
                    final isCompleted = _isEventCompleted(entry.value.type);
                    return Positioned(
                      left: index * 100 + 25,
                      top: -6,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCompleted
                              ? Colors.green[400]
                              : Colors.grey[300],
                          border: Border.all(
                            color: isCompleted
                                ? Colors.green[600]!
                                : Colors.grey[400]!,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (isCompleted ? Colors.green : Colors.grey)
                                  .withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: isCompleted
                            ? Icon(Icons.check, size: 12, color: Colors.white)
                            : Container(),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          // Timeline content
          Positioned.fill(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  ...timeline.asMap().entries.map((entry) {
                    final index = entry.key;
                    final event = entry.value;
                    final isCompleted = _isEventCompleted(event.type);
                    final isLast = index == timeline.length - 1;

                    return _buildAdvancedTimelineItem(
                      context,
                      event,
                      isCompleted,
                      isLast,
                      index,
                    );
                  }),
                ],
              ),
            ),
          ),

          // 3D Animated Car with Enhanced Movement
          AnimatedBuilder(
            animation: _carPosition,
            builder: (context, child) {
              final completedEvents = _getCompletedEventsCount();
              final totalEvents = timeline.length;
              final progress = totalEvents > 0
                  ? completedEvents / totalEvents
                  : 0.0;

              // Enhanced car positioning with smooth easing
              final basePosition = 20.0;
              final eventSpacing = 100.0;
              final maxTravel = timeline.length * eventSpacing - 60;
              final easedProgress = Curves.easeInOutCubic.transform(progress);
              final carLeft = basePosition + (easedProgress * maxTravel);

              // Dynamic vertical position with road following
              final roadOffset = math.sin(progress * math.pi * 2) * 3;
              final carTop = 15.0 + roadOffset;

              return Positioned(
                left: carLeft,
                top: carTop,
                child: Transform.scale(
                  scale:
                      1.0 +
                      (progress * 0.1), // Car grows slightly as it progresses
                  child: _build3DAnimatedCar(),
                ),
              );
            },
          ),

          // Car trail effect
          AnimatedBuilder(
            animation: _carPosition,
            builder: (context, child) {
              final completedEvents = _getCompletedEventsCount();
              final totalEvents = timeline.length;
              final progress = totalEvents > 0
                  ? completedEvents / totalEvents
                  : 0.0;

              if (progress > 0) {
                return Positioned(
                  left: 25,
                  top: 25,
                  child: Container(
                    width: (progress * (timeline.length * 100 - 60)),
                    height: 3,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      gradient: LinearGradient(
                        colors: [
                          Colors.blue.withOpacity(0.3),
                          Colors.blue.withOpacity(0.6),
                          Colors.blue.withOpacity(0.2),
                        ],
                        stops: const [0.0, 0.7, 1.0],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedTimelineItem(
    BuildContext context,
    RideTimelineEvent event,
    bool isCompleted,
    bool isLast,
    int index,
  ) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        // Enhanced hover effect simulation
        final hoverScale = isCompleted
            ? (1.0 + math.sin(_pulseAnimation.value * math.pi * 2) * 0.05)
            : 1.0;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            children: [
              // Timeline step with enhanced 3D styling
              TweenAnimationBuilder<double>(
                duration: Duration(milliseconds: 300 + (index * 100)),
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, animationValue, child) {
                  return Transform.scale(
                    scale: (isCompleted ? hoverScale : 0.95) * animationValue,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isCompleted
                              ? [
                                  Colors.green[300]!,
                                  Colors.green[500]!,
                                  Colors.green[700]!,
                                  Colors.green[900]!,
                                ]
                              : [
                                  Colors.grey[200]!,
                                  Colors.grey[300]!,
                                  Colors.grey[400]!,
                                  Colors.grey[600]!,
                                ],
                        ),
                        boxShadow: [
                          // Primary shadow
                          BoxShadow(
                            color: isCompleted
                                ? Colors.green.withOpacity(0.6)
                                : Colors.grey.withOpacity(0.3),
                            blurRadius: isCompleted ? 20 : 8,
                            offset: const Offset(0, 8),
                          ),
                          // Secondary glow effect
                          if (isCompleted)
                            BoxShadow(
                              color: Colors.green.withOpacity(0.3),
                              blurRadius: 30,
                              offset: const Offset(0, 12),
                            ),
                          // Inner shadow for depth
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Glossy overlay effect
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.center,
                                colors: [
                                  Colors.white.withOpacity(0.4),
                                  Colors.white.withOpacity(0.1),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                          // Icon with enhanced styling
                          Center(
                            child: isCompleted
                                ? Stack(
                                    children: [
                                      // Icon glow effect
                                      Icon(
                                        Icons.check_circle,
                                        size: 32,
                                        color: Colors.white.withOpacity(0.3),
                                      ),
                                      // Main icon
                                      Icon(
                                        Icons.check_circle,
                                        size: 28,
                                        color: Colors.white,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black.withOpacity(
                                              0.3,
                                            ),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                    ],
                                  )
                                : Icon(
                                    _getEventIcon(event.type),
                                    size: 24,
                                    color: Colors.grey[700],
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 2,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                          ),
                          // Animated ring effect for completed events
                          if (isCompleted)
                            AnimatedBuilder(
                              animation: _pulseController,
                              builder: (context, child) {
                                return Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.green.withOpacity(
                                        0.5 * (1.0 - _pulseAnimation.value),
                                      ),
                                      width: 2 * _pulseAnimation.value,
                                    ),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 12),

              // Enhanced event title with 3D text effect
              Container(
                width: 90,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? Colors.green.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isCompleted
                        ? Colors.green.withOpacity(0.3)
                        : Colors.grey.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  _getShortDescription(event.type),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isCompleted ? FontWeight.bold : FontWeight.w500,
                    color: isCompleted ? Colors.green[800] : Colors.grey[600],
                    shadows: isCompleted
                        ? [
                            Shadow(
                              color: Colors.green.withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ]
                        : [
                            Shadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Animated time display with enhanced styling
              if (isCompleted)
                TweenAnimationBuilder<double>(
                  duration: Duration(milliseconds: 800 + (index * 200)),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Container(
                        margin: const EdgeInsets.only(top: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.green[200]!,
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          event.formattedTime,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.green[700],
                          ),
                        ),
                      ),
                    );
                  },
                ),

              // Connection line to next event
              if (!isLast)
                Container(
                  width: 60,
                  height: 3,
                  margin: const EdgeInsets.only(top: 8, left: 30),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    gradient: LinearGradient(
                      colors: isCompleted
                          ? [Colors.green[400]!, Colors.green[300]!]
                          : [Colors.grey[300]!, Colors.grey[400]!],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isCompleted ? Colors.green : Colors.grey)
                            .withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _build3DAnimatedCar() {
    return AnimatedBuilder(
      animation: Listenable.merge([_carAnimationController, _pulseController]),
      builder: (context, child) {
        final bounceEffect =
            math.sin(_carAnimationController.value * math.pi * 2) * 2;
        final completedEvents = _getCompletedEventsCount();
        final totalEvents = _getAllPossibleEvents().length;
        final progress = totalEvents > 0 ? completedEvents / totalEvents : 0.0;

        // Dynamic car color based on progress
        final carColors = progress > 0.8
            ? [Colors.green[400]!, Colors.green[600]!, Colors.green[800]!]
            : progress > 0.5
            ? [Colors.orange[400]!, Colors.orange[600]!, Colors.orange[800]!]
            : [Colors.blue[400]!, Colors.blue[600]!, Colors.blue[800]!];

        return Transform.translate(
          offset: Offset(0, bounceEffect),
          child: Transform.scale(
            scale: 1.0 + (_pulseAnimation.value - 1.0) * 0.15,
            child: Transform.rotate(
              angle: math.sin(_carAnimationController.value * math.pi) * 0.05,
              child: Stack(
                children: [
                  // Car shadow
                  Positioned(
                    top: 30,
                    left: 2,
                    child: Container(
                      width: 48,
                      height: 15,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: RadialGradient(
                          colors: [
                            Colors.black.withOpacity(0.3),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Main car body
                  Container(
                    width: 52,
                    height: 28,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: carColors,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: carColors[1].withOpacity(0.5),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 25,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Car windshield
                        Positioned(
                          top: 3,
                          left: 8,
                          right: 8,
                          child: Container(
                            height: 12,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.lightBlue[100]!.withOpacity(0.8),
                                  Colors.lightBlue[200]!.withOpacity(0.6),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                        // Car headlights
                        Positioned(
                          top: 18,
                          left: 2,
                          child: Container(
                            width: 8,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.yellow[200],
                              borderRadius: BorderRadius.circular(2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.yellow.withOpacity(0.5),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          top: 18,
                          right: 2,
                          child: Container(
                            width: 8,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.yellow[200],
                              borderRadius: BorderRadius.circular(2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.yellow.withOpacity(0.5),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Car wheels
                        Positioned(
                          bottom: -3,
                          left: 8,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [Colors.grey[800]!, Colors.grey[600]!],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 3,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: -3,
                          right: 8,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [Colors.grey[800]!, Colors.grey[600]!],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 3,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Car reflection shine effect
                        AnimatedBuilder(
                          animation: _liquidFlow,
                          builder: (context, child) {
                            return Positioned(
                              left: -15 + (82 * _liquidFlow.value),
                              top: 2,
                              child: Container(
                                width: 8,
                                height: 24,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      Colors.white.withOpacity(0.7),
                                      Colors.white.withOpacity(0.9),
                                      Colors.white.withOpacity(0.7),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        // Progress indicator on car
                        if (progress > 0)
                          Positioned(
                            top: -8,
                            left: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                '${(progress * 100).toInt()}%',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: carColors[2],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  int _getCompletedEventsCount() {
    return _getAllPossibleEvents()
        .where((event) => _isEventCompleted(event.type))
        .length;
  }

  bool _isEventCompleted(TimelineEventType type) {
    switch (type) {
      case TimelineEventType.navigatedToPickup:
        return widget.ride.navigatedToPickupAt != null;
      case TimelineEventType.arrivedAtPickup:
        return widget.ride.arrivedAtPickupAt != null;
      case TimelineEventType.passengerPickedUp:
        return widget.ride.passengerPickedUpAt != null;
      case TimelineEventType.navigatedToDestination:
        return widget.ride.navigatedToDestinationAt != null;
      case TimelineEventType.arrivedAtDestination:
        return widget.ride.arrivedAtDestinationAt != null;
      case TimelineEventType.rideCompleted:
        // This case is kept for backwards compatibility but not used in timeline
        return widget.ride.rideCompletedAt != null;
    }
  }

  IconData _getEventIcon(TimelineEventType type) {
    switch (type) {
      case TimelineEventType.navigatedToPickup:
        return Icons.navigation;
      case TimelineEventType.arrivedAtPickup:
        return Icons.location_on;
      case TimelineEventType.passengerPickedUp:
        return Icons.person_add;
      case TimelineEventType.navigatedToDestination:
        return Icons.navigation;
      case TimelineEventType.arrivedAtDestination:
        return Icons.location_on;
      case TimelineEventType.rideCompleted:
        // Not used in timeline anymore, but kept for compatibility
        return Icons.check_circle;
    }
  }

  String _getShortDescription(TimelineEventType type) {
    switch (type) {
      case TimelineEventType.navigatedToPickup:
        return 'Navigate';
      case TimelineEventType.arrivedAtPickup:
        return 'Arrive';
      case TimelineEventType.passengerPickedUp:
        return 'Pickup';
      case TimelineEventType.navigatedToDestination:
        return 'Drive';
      case TimelineEventType.arrivedAtDestination:
        return 'Destination';
      case TimelineEventType.rideCompleted:
        // Not used in timeline anymore, but kept for compatibility
        return 'Complete';
    }
  }

  Widget _buildCompactRideSummary(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildCompactSummaryItem(
            'Pickup Nav',
            widget.ride.navigationToPickupDuration,
            Icons.navigation,
          ),
          _buildCompactSummaryItem(
            'Wait Time',
            widget.ride.waitingAtPickupDuration,
            Icons.schedule,
          ),
          _buildCompactSummaryItem(
            'To Dest',
            widget.ride.navigationToDestinationDuration,
            Icons.location_on,
          ),
          _buildCompactSummaryItem(
            'Total',
            widget.ride.totalRideDuration,
            Icons.timer,
          ),
        ],
      ),
    );
  }

  Widget _buildCompactSummaryItem(String label, int? duration, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.blue[600]),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
        Text(
          duration != null ? _formatDuration(duration) : 'N/A',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.blue[800],
          ),
        ),
      ],
    );
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours}h ${mins}m';
  }
}
