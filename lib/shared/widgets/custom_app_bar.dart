import 'package:flutter/material.dart';
import '../../shared/models/driver_model.dart';
import '../../core/theme/app_theme.dart';
import '../../features/communication/presentation/screens/communication_screen.dart';
import '../../features/notifications/presentation/screens/notification_screen.dart';
import '../../features/profile/presentation/screens/profile_view_screen.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final DriverModel driver;
  final List<Widget>? additionalActions;
  final Color? backgroundColor;
  final VoidCallback? onRefresh;
  final bool showBackButton;

  const CustomAppBar({
    super.key,
    required this.title,
    required this.driver,
    this.additionalActions,
    this.backgroundColor,
    this.onRefresh,
    this.showBackButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            backgroundColor ?? AppTheme.primaryColor,
            (backgroundColor ?? AppTheme.primaryColor).withOpacity(0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: (backgroundColor ?? AppTheme.primaryColor).withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: showBackButton,
        elevation: 0,
        actions: [
          // Additional actions from specific screens with spacing
          if (additionalActions != null) ...[
            ...additionalActions!,
            const SizedBox(width: 4),
          ],

          // Constant top-right navigation buttons with modern design
          _buildTopNavButton(
            icon: Icons.refresh_rounded,
            tooltip: 'Refresh',
            onPressed: () =>
                onRefresh != null ? onRefresh!() : _performRefresh(context),
          ),
          _buildTopNavButton(
            icon: Icons.chat_bubble_outline_rounded,
            tooltip: 'Chat',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CommunicationScreen(driver: driver),
              ),
            ),
          ),
          _buildTopNavButton(
            icon: Icons.notifications_none_rounded,
            tooltip: 'Alerts',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NotificationScreen(),
              ),
            ),
          ),
          _buildTopNavButton(
            icon: Icons.account_circle_outlined,
            tooltip: 'Profile',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileViewScreen(driver: driver),
              ),
            ),
          ),
          const SizedBox(width: 12), // Add some spacing from edge
        ],
      ),
    );
  }

  Widget _buildTopNavButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          splashColor: Colors.white.withOpacity(0.2),
          highlightColor: Colors.white.withOpacity(0.1),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.15),
                  Colors.white.withOpacity(0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, size: 20, color: Colors.white),
          ),
        ),
      ),
    );
  }

  void _performRefresh(BuildContext context) {
    // This can be overridden by passing a custom refresh function
    // For now, we'll just show a generic refresh action
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Refreshing...'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
