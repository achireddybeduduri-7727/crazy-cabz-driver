import 'package:flutter/material.dart';
import '../../shared/models/driver_model.dart';
import '../../core/theme/app_theme.dart';
import '../../core/animations/app_animations.dart';
import '../../features/rides/presentation/screens/route_ride_list_screen.dart';
import '../../features/earnings/presentation/screens/earnings_screen.dart';
import '../../features/rides/presentation/screens/ride_history_screen.dart';
import '../../features/rides/presentation/screens/add_manual_ride_screen.dart';

// Notification to reload the Rides screen
class RouteScreenReloadNotification extends Notification {}

class PersistentNavigationWrapper extends StatefulWidget {
  final DriverModel driver;
  final int initialIndex;

  const PersistentNavigationWrapper({
    super.key,
    required this.driver,
    this.initialIndex = 0,
  });

  @override
  State<PersistentNavigationWrapper> createState() =>
      _PersistentNavigationWrapperState();
}

class _PersistentNavigationWrapperState
    extends State<PersistentNavigationWrapper> {
  late int _currentIndex;
  late List<Widget> _screens;
  final GlobalKey<RouteRideListScreenState> _ridesScreenKey = GlobalKey<RouteRideListScreenState>();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;

    // Initialize all screens once with key for Rides screen
    _screens = [
      RouteRideListScreen(key: _ridesScreenKey, driverId: widget.driver.id, driver: widget.driver),
      EarningsScreen(driver: widget.driver),
      const RideHistoryScreen(),
    ];

    print(
      '🔵 DEBUG INIT: PersistentNavigationWrapper initialized with index: $_currentIndex',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 24,
              offset: const Offset(0, -4),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, -2),
              spreadRadius: 0,
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: SizedBox(
              height: 50,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    icon: Icons.directions_car_rounded,
                    label: 'Rides',
                    index: 0,
                    onTap: () => _navigateToScreen(0),
                  ),
                  _buildNavItem(
                    icon: Icons.account_balance_wallet_rounded,
                    label: 'Earnings',
                    index: 1,
                    onTap: () => _navigateToScreen(1),
                  ),
                  _buildNavItem(
                    icon: Icons.history_rounded,
                    label: 'Activities',
                    index: 2,
                    onTap: () => _navigateToScreen(2),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: _currentIndex == 0
          ? Builder(
              builder: (context) {
                print('🔵 DEBUG FAB: Visible on Rides screen');
                return AppAnimations.animatedFAB(
                  isVisible: true,
                  onPressed: () {
                    print('🔵 DEBUG FAB: FAB pressed!');
                    _showAddManualRideDialog();
                  },
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor,
                          AppTheme.primaryColor.withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.5),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                          spreadRadius: 0,
                        ),
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
                  ),
                );
              },
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required VoidCallback onTap,
    bool showBadge = false,
  }) {
    final isSelected = _currentIndex == index;
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            splashColor: AppTheme.primaryColor.withOpacity(0.1),
            highlightColor: AppTheme.primaryColor.withOpacity(0.05),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(
                                  colors: [
                                    AppTheme.primaryColor,
                                    AppTheme.primaryColor.withOpacity(0.8),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppTheme.primaryColor.withOpacity(0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                    spreadRadius: 0,
                                  ),
                                ]
                              : null,
                        ),
                        child: Icon(
                          icon,
                          color: isSelected ? Colors.white : Colors.grey[600],
                          size: 22,
                        ),
                      ),
                      if (showBadge)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFFF6B6B),
                                  Color(0xFFFF8E53),
                                ],
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withOpacity(0.4),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 8,
                              minHeight: 8,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 1),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    style: TextStyle(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : Colors.grey[600],
                      fontSize: 10,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      letterSpacing: 0.2,
                      height: 1.1,
                    ),
                    child: Text(label),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToScreen(int index) {
    print(
      '🔵 DEBUG NAV: Switching to screen index: $index from current index: $_currentIndex',
    );

    if (index < 0 || index >= _screens.length) {
      print('❌ ERROR NAV: Invalid index: $index');
      return;
    }

    final int previousIndex = _currentIndex;

    setState(() {
      _currentIndex = index;
    });

    print('✅ DEBUG NAV: Screen switched to index: $index');

    // Trigger reload for Rides screen when navigating to it from another screen
    if (index == 0 && previousIndex != 0) {
      print('🔄 DEBUG NAV: Navigated to Rides screen from index $previousIndex - Triggering reload');
      // Use post-frame callback to ensure the screen is visible
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Directly call reload on the Rides screen using GlobalKey
        if (_ridesScreenKey.currentState != null) {
          print('🔄 DEBUG NAV: Calling reloadActiveRoute on Rides screen');
          _ridesScreenKey.currentState!.reloadActiveRoute();
        } else {
          print('❌ DEBUG NAV: Rides screen state is null');
        }
      });
    }
  }

  void _showAddManualRideDialog() {
    print('🔵 DEBUG: _showAddManualRideDialog called');
    print('🔵 DEBUG: Current index: $_currentIndex');
    print('🔵 DEBUG: Widget mounted: $mounted');

    // Ensure we're on the rides screen (index 0) before navigating
    if (_currentIndex != 0) {
      print('🔵 DEBUG: Switching to rides screen first');
      setState(() {
        _currentIndex = 0;
      });
      // Wait for the state to update before navigating
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateToAddManualRide();
      });
    } else {
      print('🔵 DEBUG: Already on rides screen, navigating directly');
      _navigateToAddManualRide();
    }
  }

  void _navigateToAddManualRide() {
    print('🔵 DEBUG: _navigateToAddManualRide called');

    // Check if context is still valid and mounted
    if (!mounted) {
      print('❌ ERROR: Widget not mounted, cannot navigate');
      return;
    }

    print('✅ DEBUG: Widget is mounted, attempting navigation');

    try {
      // Use Navigator.push with MaterialPageRoute for more stability
      // Use rootNavigator: true to show above bottom navigation
      print('🔵 DEBUG: Pushing AddManualRideScreen');
      Navigator.of(context, rootNavigator: true)
          .push(
            MaterialPageRoute(
              builder: (context) {
                print('✅ DEBUG: Building AddManualRideScreen');
                return AddManualRideScreen(driver: widget.driver);
              },
            ),
          )
          .then((_) {
            print('✅ DEBUG: Returned from AddManualRideScreen');
          })
          .catchError((error) {
            print('❌ ERROR: Navigation error caught: $error');
          });
      print('✅ DEBUG: Navigation command sent successfully');
    } catch (e, stackTrace) {
      print('❌ ERROR: Exception navigating to add manual ride: $e');
      print('📋 Stack trace: $stackTrace');

      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening add ride screen: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
