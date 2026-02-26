import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class SafetyTipsCard extends StatelessWidget {
  const SafetyTipsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.security,
                    color: Colors.blue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Safety First',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSafetyTip(
              icon: Icons.swipe,
              title: 'Swipe Buttons',
              description:
                  'Use swipe gestures for ride actions to prevent accidental taps while driving.',
              context: context,
            ),
            const SizedBox(height: 12),
            _buildSafetyTip(
              icon: Icons.phone,
              title: 'Hands-Free Calling',
              description:
                  'Always use hands-free calling when contacting customers.',
              context: context,
            ),
            const SizedBox(height: 12),
            _buildSafetyTip(
              icon: Icons.emergency,
              title: 'Emergency Button',
              description:
                  'Emergency button is available in the top right corner for urgent situations.',
              context: context,
            ),
            const SizedBox(height: 12),
            _buildSafetyTip(
              icon: Icons.car_crash,
              title: 'Focus on Road',
              description:
                  'Pull over safely before interacting with the app extensively.',
              context: context,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSafetyTip({
    required IconData icon,
    required String title,
    required String description,
    required BuildContext context,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
