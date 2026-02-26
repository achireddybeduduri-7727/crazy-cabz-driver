import 'package:flutter/material.dart';
import '../../../../shared/models/driver_model.dart';
import '../../../../shared/widgets/persistent_navigation_wrapper.dart';
import 'route_ride_list_screen.dart';

class RideScreen extends StatelessWidget {
  final String driverId;
  final DriverModel? driver;

  const RideScreen({super.key, required this.driverId, this.driver});

  @override
  Widget build(BuildContext context) {
    if (driver != null) {
      // Use persistent navigation when driver is provided
      return PersistentNavigationWrapper(driver: driver!, initialIndex: 0);
    }
    // Fallback to regular screen
    return RouteRideListScreen(driverId: driverId);
  }
}
