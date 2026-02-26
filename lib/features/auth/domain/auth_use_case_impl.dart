import '../../../shared/models/driver_model.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/constants/app_constants.dart';
import '../data/auth_repository.dart';
import 'auth_use_case.dart';

class AuthUseCaseImpl implements AuthUseCase {
  final AuthRepository _authRepository;

  AuthUseCaseImpl(this._authRepository);

  @override
  Future<AuthResult> login(String email, String password) async {
    try {
      final response = await _authRepository.login(
        email: email,
        password: password,
      );

      if (response['success'] == true) {
        final token = response['token'];
        final driverData =
            response['data']; // Fixed: changed from 'driver' to 'data'

        if (token != null) {
          await StorageService.storeSecureData(
            AppConstants.authTokenKey,
            token,
          );
        }

        if (driverData != null) {
          final driver = DriverModel.fromJson(driverData);
          await StorageService.storeJson(
            AppConstants.userDataKey,
            driver.toJson(),
          );
          await StorageService.storeBool(AppConstants.isLoggedInKey, true);

          return AuthResult.success(
            message: response['message'] ?? 'Login successful',
            token: token,
            driver: driver,
          );
        }
      }

      return AuthResult.failure(response['message'] ?? 'Login failed');
    } catch (e) {
      return AuthResult.failure(e.toString());
    }
  }

  @override
  Future<AuthResult> register(
    String email,
    String password,
    String fullName,
    String phoneNumber,
  ) async {
    try {
      final response = await _authRepository.register(
        email: email,
        password: password,
        fullName: fullName,
        phoneNumber: phoneNumber,
      );

      if (response['success'] == true) {
        return AuthResult.success(
          message:
              response['message'] ??
              'Registration successful. Please verify your email.',
          data: response,
        );
      }

      return AuthResult.failure(response['message'] ?? 'Registration failed');
    } catch (e) {
      return AuthResult.failure(e.toString());
    }
  }

  @override
  Future<AuthResult> verifyOtp(String email, String otp) async {
    try {
      final response = await _authRepository.verifyOtp(email: email, otp: otp);

      if (response['success'] == true) {
        return AuthResult.success(
          message: response['message'] ?? 'OTP verified successfully',
          data: response,
        );
      }

      return AuthResult.failure(
        response['message'] ?? 'OTP verification failed',
      );
    } catch (e) {
      return AuthResult.failure(e.toString());
    }
  }

  @override
  Future<AuthResult> verifyCompanyId(String companyId, String driverId) async {
    try {
      final response = await _authRepository.verifyCompanyId(
        companyId: companyId,
        driverId: driverId,
      );

      if (response['success'] == true) {
        await StorageService.storeString(AppConstants.companyIdKey, companyId);
        await StorageService.storeString(AppConstants.driverIdKey, driverId);

        return AuthResult.success(
          message: response['message'] ?? 'Company ID verified successfully',
          data: response,
        );
      }

      return AuthResult.failure(
        response['message'] ?? 'Company ID verification failed',
      );
    } catch (e) {
      return AuthResult.failure(e.toString());
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _authRepository.logout();
    } catch (e) {
      // Continue with local logout even if server logout fails
    } finally {
      // Clear all stored data
      await StorageService.clear();
    }
  }

  @override
  Future<AuthResult> resendOtp(String email) async {
    try {
      final response = await _authRepository.resendOtp(email: email);

      if (response['success'] == true) {
        return AuthResult.success(
          message: response['message'] ?? 'OTP sent successfully',
        );
      }

      return AuthResult.failure(response['message'] ?? 'Failed to send OTP');
    } catch (e) {
      return AuthResult.failure(e.toString());
    }
  }

  @override
  Future<AuthResult> forgotPassword(String email) async {
    try {
      final response = await _authRepository.forgotPassword(email: email);

      if (response['success'] == true) {
        return AuthResult.success(
          message: response['message'] ?? 'Password reset OTP sent',
        );
      }

      return AuthResult.failure(
        response['message'] ?? 'Failed to send password reset OTP',
      );
    } catch (e) {
      return AuthResult.failure(e.toString());
    }
  }

  @override
  Future<AuthResult> resetPassword(
    String email,
    String otp,
    String newPassword,
  ) async {
    try {
      final response = await _authRepository.resetPassword(
        email: email,
        otp: otp,
        newPassword: newPassword,
      );

      if (response['success'] == true) {
        return AuthResult.success(
          message: response['message'] ?? 'Password reset successfully',
        );
      }

      return AuthResult.failure(response['message'] ?? 'Password reset failed');
    } catch (e) {
      return AuthResult.failure(e.toString());
    }
  }
}
