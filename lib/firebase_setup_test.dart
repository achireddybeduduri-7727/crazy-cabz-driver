import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:driver_app/firebase_options.dart';
import 'package:driver_app/core/services/firebase_setup_helper.dart';

/// Test page to setup Firebase data structure
/// Run this to create sample organized data in Firebase
class FirebaseSetupTestPage extends StatefulWidget {
  const FirebaseSetupTestPage({Key? key}) : super(key: key);

  @override
  State<FirebaseSetupTestPage> createState() => _FirebaseSetupTestPageState();
}

class _FirebaseSetupTestPageState extends State<FirebaseSetupTestPage> {
  final FirebaseSetupHelper _setupHelper = FirebaseSetupHelper();
  bool _isLoading = false;
  String _status = 'Ready to create sample data';

  Future<void> _runSetup() async {
    setState(() {
      _isLoading = true;
      _status = 'Creating sample data...';
    });

    try {
      await _setupHelper.runCompleteSetup();
      setState(() {
        _status = 'Setup complete! Check Firebase Console';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Setup Test'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.cloud_upload,
              size: 80,
              color: Colors.blue,
            ),
            const SizedBox(height: 24),
            const Text(
              'Firebase Data Organization Setup',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              _status,
              style: TextStyle(
                fontSize: 16,
                color: _isLoading ? Colors.orange : Colors.green,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (!_isLoading)
              ElevatedButton.icon(
                onPressed: _runSetup,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Create Sample Data'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(),
              ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              'This will create:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text('✅ Sample driver profile'),
            const Text('✅ Sample rider profile'),
            const Text('✅ Sample ride with GPS tracking'),
            const Text('✅ Sample notifications'),
            const Text('✅ Sample support ticket'),
            const Text('✅ Sample earnings record'),
            const Text('✅ Sample settings'),
            const Text('✅ Sample manual ride'),
            const SizedBox(height: 24),
            const Text(
              'All data will be organized in separate collections and folders as per the structure in FIREBASE_DATA_ORGANIZATION.md',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40), // Extra padding at bottom
          ],
        ),
      ),
    );
  }
}

/// Main function to run the test page
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Setup Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const FirebaseSetupTestPage(),
    );
  }
}
