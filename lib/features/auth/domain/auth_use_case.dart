import '../../../shared/models/driver_model.dart';

abstract class AuthUseCase {
  Future<AuthResult> login(String email, String password);
  Future<AuthResult> register(
    String email,
    String password,
    String fullName,
    String phoneNumber,
  );
  Future<AuthResult> verifyOtp(String email, String otp);
  Future<AuthResult> verifyCompanyId(String companyId, String driverId);
  Future<void> logout();
  Future<AuthResult> resendOtp(String email);
  Future<AuthResult> forgotPassword(String email);
  Future<AuthResult> resetPassword(
    String email,
    String otp,
    String newPassword,
  );
}

class AuthResult {
  final bool success;
  final String? message;
  final String? token;
  final DriverModel? driver;
  final Map<String, dynamic>? data;

  AuthResult({
    required this.success,
    this.message,
    this.token,
    this.driver,
    this.data,
  });

  factory AuthResult.success({
    String? message,
    String? token,
    DriverModel? driver,
    Map<String, dynamic>? data,
  }) {
    return AuthResult(
      success: true,
      message: message,
      token: token,
      driver: driver,
      data: data,
    );
  }

  factory AuthResult.failure(String message) {
    return AuthResult(success: false, message: message);
  }
}
