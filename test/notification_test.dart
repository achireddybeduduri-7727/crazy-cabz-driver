import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Basic Notification Widget Tests', () {
    testWidgets('should display notification content', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: NotificationTestWidget())),
      );

      expect(find.text('Notification Test'), findsOneWidget);
      expect(find.byIcon(Icons.notifications), findsOneWidget);
    });

    testWidgets('should handle notification tap', (WidgetTester tester) async {
      bool wasTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  wasTapped = true;
                },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.notification_important),
                    SizedBox(width: 8),
                    Text('Show Notification'),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Notification'));
      await tester.pump();

      expect(wasTapped, isTrue);
    });

    testWidgets('should display notification badge', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: NotificationBadgeWidget(count: 5)),
        ),
      );

      expect(find.text('5'), findsOneWidget);
      expect(find.byIcon(Icons.notifications), findsOneWidget);
    });

    testWidgets('should hide badge when count is zero', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: NotificationBadgeWidget(count: 0)),
        ),
      );

      expect(find.text('0'), findsNothing);
      expect(find.byIcon(Icons.notifications), findsOneWidget);
    });
  });
}

class NotificationTestWidget extends StatelessWidget {
  const NotificationTestWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications, size: 48),
          SizedBox(height: 16),
          Text('Notification Test'),
        ],
      ),
    );
  }
}

class NotificationBadgeWidget extends StatelessWidget {
  final int count;

  const NotificationBadgeWidget({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        children: [
          const Icon(Icons.notifications, size: 48),
          if (count > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  count.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
