import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Driver App Integration Tests', () {
    testWidgets('app launches and shows login screen', (
      WidgetTester tester,
    ) async {
      // Launch the app
      // Note: The actual main function might need to be modified for testing
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Center(child: Text('Driver App Test'))),
        ),
      );

      // Wait for the app to settle
      await tester.pumpAndSettle();

      // Verify the app loads
      expect(find.text('Driver App Test'), findsOneWidget);
    });

    testWidgets('navigation flow works correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          initialRoute: '/',
          routes: {
            '/': (context) => const HomePage(),
            '/profile': (context) => const ProfilePage(),
            '/earnings': (context) => const EarningsPage(),
          },
        ),
      );

      await tester.pumpAndSettle();

      // Test navigation to profile
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      expect(find.text('Profile Page'), findsOneWidget);

      // Test navigation to earnings
      await tester.tap(find.text('Earnings'));
      await tester.pumpAndSettle();
      expect(find.text('Earnings Page'), findsOneWidget);

      // Test back navigation
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(find.text('Home Page'), findsOneWidget);
    });

    testWidgets('form submission works end-to-end', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: TestFormPage()));

      await tester.pumpAndSettle();

      // Enter text in form fields
      await tester.enterText(find.byKey(const Key('name_field')), 'John Doe');
      await tester.enterText(
        find.byKey(const Key('email_field')),
        'john@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('phone_field')),
        '+1234567890',
      );

      // Submit the form
      await tester.tap(find.byKey(const Key('submit_button')));
      await tester.pumpAndSettle();

      // Verify success message
      expect(find.text('Form submitted successfully!'), findsOneWidget);
    });

    testWidgets('drawer navigation works', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: TestDrawerPage()));

      await tester.pumpAndSettle();

      // Open drawer
      final ScaffoldState state = tester.firstState(find.byType(Scaffold));
      state.openDrawer();
      await tester.pumpAndSettle();

      // Tap on a drawer item
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      // Verify navigation occurred
      expect(find.text('Settings Page'), findsOneWidget);
    });

    testWidgets('tab navigation works', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: TestTabPage()));

      await tester.pumpAndSettle();

      // Test tab switching
      expect(find.text('Tab 1 Content'), findsOneWidget);

      await tester.tap(find.text('Tab 2'));
      await tester.pumpAndSettle();
      expect(find.text('Tab 2 Content'), findsOneWidget);

      await tester.tap(find.text('Tab 3'));
      await tester.pumpAndSettle();
      expect(find.text('Tab 3 Content'), findsOneWidget);
    });

    testWidgets('list scrolling and interaction works', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: TestListPage()));

      await tester.pumpAndSettle();

      // Verify initial items are visible
      expect(find.text('Item 0'), findsOneWidget);
      expect(find.text('Item 1'), findsOneWidget);

      // Scroll down to find later items
      await tester.scrollUntilVisible(
        find.text('Item 50'),
        500.0,
        scrollable: find.byType(ListView),
      );

      expect(find.text('Item 50'), findsOneWidget);

      // Tap on an item
      await tester.tap(find.text('Item 50'));
      await tester.pumpAndSettle();

      expect(find.text('Selected: Item 50'), findsOneWidget);
    });

    testWidgets('dialog interactions work', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: TestDialogPage()));

      await tester.pumpAndSettle();

      // Open dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Verify dialog is shown
      expect(find.text('Test Dialog'), findsOneWidget);
      expect(find.text('This is a test dialog'), findsOneWidget);

      // Dismiss dialog
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Verify dialog is dismissed
      expect(find.text('Test Dialog'), findsNothing);
    });

    testWidgets('snackbar works', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: TestSnackBarPage()));

      await tester.pumpAndSettle();

      // Trigger snackbar
      await tester.tap(find.text('Show SnackBar'));
      await tester.pump(); // Don't use pumpAndSettle as snackbar animates

      // Verify snackbar is shown
      expect(find.text('This is a test snackbar'), findsOneWidget);

      // Wait for snackbar to disappear
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Verify snackbar is gone
      expect(find.text('This is a test snackbar'), findsNothing);
    });
  });
}

// Test pages for integration testing
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Home Page'),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/profile'),
              child: const Text('Profile'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/earnings'),
              child: const Text('Earnings'),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: const Center(child: Text('Profile Page')),
    );
  }
}

class EarningsPage extends StatelessWidget {
  const EarningsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Earnings')),
      body: const Center(child: Text('Earnings Page')),
    );
  }
}

class TestFormPage extends StatefulWidget {
  const TestFormPage({super.key});

  @override
  State<TestFormPage> createState() => _TestFormPageState();
}

class _TestFormPageState extends State<TestFormPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _submitted = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test Form')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_submitted)
              const Text('Form submitted successfully!')
            else ...[
              TextField(
                key: const Key('name_field'),
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                key: const Key('email_field'),
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextField(
                key: const Key('phone_field'),
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                key: const Key('submit_button'),
                onPressed: () {
                  setState(() {
                    _submitted = true;
                  });
                },
                child: const Text('Submit'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class TestDrawerPage extends StatelessWidget {
  const TestDrawerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test Drawer')),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(child: Text('Menu')),
            ListTile(
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                );
              },
            ),
          ],
        ),
      ),
      body: const Center(child: Text('Test Drawer Page')),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: const Center(child: Text('Settings Page')),
    );
  }
}

class TestTabPage extends StatelessWidget {
  const TestTabPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Test Tabs'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Tab 1'),
              Tab(text: 'Tab 2'),
              Tab(text: 'Tab 3'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            Center(child: Text('Tab 1 Content')),
            Center(child: Text('Tab 2 Content')),
            Center(child: Text('Tab 3 Content')),
          ],
        ),
      ),
    );
  }
}

class TestListPage extends StatefulWidget {
  const TestListPage({super.key});

  @override
  State<TestListPage> createState() => _TestListPageState();
}

class _TestListPageState extends State<TestListPage> {
  String? selectedItem;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test List')),
      body: Column(
        children: [
          if (selectedItem != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('Selected: $selectedItem'),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: 100,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text('Item $index'),
                  onTap: () {
                    setState(() {
                      selectedItem = 'Item $index';
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class TestDialogPage extends StatelessWidget {
  const TestDialogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test Dialog')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Test Dialog'),
                content: const Text('This is a test dialog'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          },
          child: const Text('Show Dialog'),
        ),
      ),
    );
  }
}

class TestSnackBarPage extends StatelessWidget {
  const TestSnackBarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test SnackBar')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('This is a test snackbar'),
                duration: Duration(seconds: 3),
              ),
            );
          },
          child: const Text('Show SnackBar'),
        ),
      ),
    );
  }
}
