import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Basic Widget Tests', () {
    testWidgets('should create a basic widget', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(title: const Text('Test App')),
            body: const Center(child: Text('Hello World')),
          ),
        ),
      );

      expect(find.text('Test App'), findsOneWidget);
      expect(find.text('Hello World'), findsOneWidget);
    });

    testWidgets('should handle button taps', (WidgetTester tester) async {
      int counter = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    Text('Counter: $counter'),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          counter++;
                        });
                      },
                      child: const Text('Increment'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Counter: 0'), findsOneWidget);

      await tester.tap(find.text('Increment'));
      await tester.pump();

      expect(find.text('Counter: 1'), findsOneWidget);
    });

    testWidgets('should display list items', (WidgetTester tester) async {
      final items = ['Item 1', 'Item 2', 'Item 3'];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                return ListTile(title: Text(items[index]));
              },
            ),
          ),
        ),
      );

      for (final item in items) {
        expect(find.text(item), findsOneWidget);
      }
    });

    testWidgets('should handle navigation', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const Scaffold(
                        body: Center(child: Text('Second Screen')),
                      ),
                    ),
                  );
                },
                child: const Text('Navigate'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Navigate'));
      await tester.pumpAndSettle();

      expect(find.text('Second Screen'), findsOneWidget);
    });

    testWidgets('should show and hide widgets conditionally', (
      WidgetTester tester,
    ) async {
      bool showWidget = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    if (showWidget) const Text('Conditional Widget'),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          showWidget = !showWidget;
                        });
                      },
                      child: const Text('Toggle'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Conditional Widget'), findsNothing);

      await tester.tap(find.text('Toggle'));
      await tester.pump();

      expect(find.text('Conditional Widget'), findsOneWidget);

      await tester.tap(find.text('Toggle'));
      await tester.pump();

      expect(find.text('Conditional Widget'), findsNothing);
    });
  });

  group('Form Widget Tests', () {
    testWidgets('should handle text input', (WidgetTester tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(hintText: 'Enter text'),
                ),
                Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Input: ${controller.text}')),
                      );
                    },
                    child: const Text('Submit'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'Test input');
      await tester.tap(find.text('Submit'));
      await tester.pump();

      expect(find.text('Input: Test input'), findsOneWidget);
    });
  });
}
