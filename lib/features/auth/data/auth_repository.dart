import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/services/storage_service.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Test Firebase Auth connection
  Future<bool> testFirebaseConnection() async {
    try {
      // Try to get current user (this will test Firebase Auth connection)
      final currentUser = _auth.currentUser;
      AppLogger.info('Current Firebase user: ${currentUser?.email ?? 'None'}');

      // Test Firestore connection
      await _firestore.collection('test').limit(1).get();
      AppLogger.info('Firebase Auth and Firestore connection successful');

      return true;
    } catch (e) {
      AppLogger.error('Firebase connection test failed: $e');
      return false;
    }
  }

  // Create test users for demonstration
  Future<void> createTestUsers() async {
    final testUsers = [
      {
        'email': 'test@driver.com',
        'password': 'password123',
        'fullName': 'Test Driver',
        'phoneNumber': '+1234567890',
      },
      {
        'email': 'driver@test.com',
        'password': 'test123',
        'fullName': 'Demo Driver',
        'phoneNumber': '+0987654321',
      },
      {
        'email': 'admin@driver.com',
        'password': 'admin123',
        'fullName': 'Admin Driver',
        'phoneNumber': '+1122334455',
      },
    ];

    for (var userData in testUsers) {
      try {
        // Try to create user directly, Firebase will handle if user already exists
        final credential = await _auth.createUserWithEmailAndPassword(
          email: userData['email']!,
          password: userData['password']!,
        );

        if (credential.user != null) {
          // Update display name
          await credential.user!.updateDisplayName(userData['fullName']!);

          // Create driver profile in Firestore
          final driverData = {
            'id': credential.user!.uid,
            'email': userData['email']!,
            'fullName': userData['fullName']!,
            'phoneNumber': userData['phoneNumber']!,
            'companyId': 'DEMO123',
            'isActive': true,
            'createdAt': DateTime.now().toIso8601String(),
            'role': 'driver',
          };

          await _firestore
              .collection(AppConstants.driversCollection)
              .doc(credential.user!.uid)
              .set(driverData);

          AppLogger.info('Created test user: ${userData['email']}');
        }
      } catch (e) {
        // User might already exist or there was another error
        if (e.toString().contains('email-already-in-use')) {
          AppLogger.info('Test user already exists: ${userData['email']}');
        } else {
          AppLogger.error(
            'Failed to create test user ${userData['email']}: $e',
          );
        }
      }
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential? credential;

      try {
        // Try to sign in first
        credential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
          // User doesn't exist, create it (for demo purposes)
          try {
            AppLogger.info('Creating new user for: $email');
            credential = await _auth.createUserWithEmailAndPassword(
              email: email,
              password: password,
            );

            // Update display name for new user
            await credential.user?.updateDisplayName('Test Driver');
            AppLogger.info('Successfully created user: $email');
          } catch (createError) {
            AppLogger.error(
              'Failed to create user: ${_getFirebaseErrorMessage(createError)}',
            );
            return {
              'success': false,
              'message':
                  'Failed to create user: ${_getFirebaseErrorMessage(createError)}',
            };
          }
        } else {
          // Log the specific error for debugging
          AppLogger.error('Firebase Auth Error: ${e.code} - ${e.message}');
          rethrow; // Re-throw other authentication errors
        }
      }

      if (credential.user != null) {
        // Get or create driver profile
        final driverDoc = await _firestore
            .collection(AppConstants.driversCollection)
            .doc(credential.user!.uid)
            .get();

        Map<String, dynamic> driverData;
        if (driverDoc.exists) {
          driverData = driverDoc.data()!;
        } else {
          // Create basic driver profile
          driverData = {
            'id': credential.user!.uid,
            'email': email,
            'fullName': credential.user!.displayName ?? 'Driver',
            'phoneNumber': credential.user!.phoneNumber ?? '',
            'companyId': 'DEMO123', // Default company ID
            'isActive': true,
            'createdAt': DateTime.now().toIso8601String(),
          };

          await _firestore
              .collection(AppConstants.driversCollection)
              .doc(credential.user!.uid)
              .set(driverData);
        }

        // Store token and user data
        final token = await credential.user!.getIdToken();
        if (token != null) {
          await StorageService.storeSecureData(
            AppConstants.authTokenKey,
            token,
          );
        }
        await StorageService.storeJson(AppConstants.userDataKey, driverData);
        await StorageService.storeBool(AppConstants.isLoggedInKey, true);

        return {
          'success': true,
          'message': 'Login successful',
          'data': driverData,
          'token': token,
        };
      }

      return {'success': false, 'message': 'Login failed'};
    } catch (e) {
      AppLogger.error('Login error: $e'); // Debug logging
      return {'success': false, 'message': _getFirebaseErrorMessage(e)};
    }
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Update user profile
        await credential.user!.updateDisplayName(fullName);

        // Create driver profile in Firestore
        final driverData = {
          'id': credential.user!.uid,
          'email': email,
          'fullName': fullName,
          'phoneNumber': phoneNumber,
          'companyId': 'DEMO123', // Default company ID
          'isActive': true,
          'createdAt': DateTime.now().toIso8601String(),
        };

        await _firestore
            .collection(AppConstants.driversCollection)
            .doc(credential.user!.uid)
            .set(driverData);

        return {
          'success': true,
          'message': 'Registration successful',
          'data': driverData,
        };
      }

      return {'success': false, 'message': 'Registration failed'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String otp,
  }) async {
    try {
      // For demo purposes, accept any 6-digit OTP
      if (otp.length == 6) {
        return {
          'success': true,
          'message': 'OTP verified successfully',
          'data': {'driverId': _auth.currentUser?.uid ?? ''},
        };
      }

      return {'success': false, 'message': 'Invalid OTP'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> verifyCompanyId({
    required String companyId,
    required String driverId,
  }) async {
    try {
      // For demo purposes, accept any company ID
      if (companyId.isNotEmpty) {
        // Update driver document with company ID
        await _firestore
            .collection(AppConstants.driversCollection)
            .doc(driverId)
            .update({'companyId': companyId});

        return {'success': true, 'message': 'Company ID verified successfully'};
      }

      return {'success': false, 'message': 'Invalid Company ID'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> logout() async {
    try {
      await _auth.signOut();
      await StorageService.deleteSecureData(AppConstants.authTokenKey);
      await StorageService.remove(AppConstants.userDataKey);
      await StorageService.storeBool(AppConstants.isLoggedInKey, false);

      return {'success': true, 'message': 'Logout successful'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> resendOtp({required String email}) async {
    try {
      // For demo purposes, always return success
      return {'success': true, 'message': 'OTP resent successfully'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> forgotPassword({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return {'success': true, 'message': 'Password reset email sent'};
    } catch (e) {
      return {'success': false, 'message': _getFirebaseErrorMessage(e)};
    }
  }

  Future<Map<String, dynamic>> resendForgotPassword({
    required String email,
  }) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return {'success': true, 'message': 'Password reset email sent'};
    } catch (e) {
      return {'success': false, 'message': _getFirebaseErrorMessage(e)};
    }
  }

  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      // For demo purposes, we'll send a password reset email
      // In a real app, you'd validate the OTP first
      await _auth.sendPasswordResetEmail(email: email);
      return {
        'success': true,
        'message':
            'Password reset email sent. Please check your email to complete the reset.',
      };
    } catch (e) {
      return {'success': false, 'message': _getFirebaseErrorMessage(e)};
    }
  }

  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.updatePassword(newPassword);
        return {'success': true, 'message': 'Password changed successfully'};
      }

      return {'success': false, 'message': 'User not authenticated'};
    } catch (e) {
      return {'success': false, 'message': _getFirebaseErrorMessage(e)};
    }
  }

  String _getFirebaseErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No user found with this email address.';
        case 'wrong-password':
          return 'Incorrect password.';
        case 'invalid-email':
          return 'Invalid email address.';
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'too-many-requests':
          return 'Too many failed attempts. Please try again later.';
        case 'email-already-in-use':
          return 'This email is already registered.';
        case 'weak-password':
          return 'Password is too weak.';
        default:
          return error.message ?? 'Authentication failed.';
      }
    }
    return error.toString();
  }
}
