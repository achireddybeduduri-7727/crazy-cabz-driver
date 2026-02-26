import 'package:flutter/material.dart';

// DEPRECATED: This screen has been replaced by RideHistoryScreen
// Location: features/rides/presentation/screens/ride_history_screen.dart
// This file is kept for backwards compatibility but redirects to the new screen

class HistoryScreen extends StatelessWidget {
  final String driverId;

  const HistoryScreen({super.key, required this.driverId});

  @override
  Widget build(BuildContext context) {
    // Redirect to the new RideHistoryScreen
    // Note: We don't need driverId anymore as it's handled by RouteBloc
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.orange),
            SizedBox(height: 16),
            Text(
              'This screen is deprecated',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Please use the Activities button instead',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
