import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../shared/models/driver_model.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/auth_use_case.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthUseCase _authUseCase;

  AuthBloc(this._authUseCase) : super(AuthInitial()) {
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthOtpVerificationRequested>(_onOtpVerificationRequested);
    on<AuthCompanyIdVerificationRequested>(_onCompanyIdVerificationRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthResendOtpRequested>(_onResendOtpRequested);
    on<AuthForgotPasswordRequested>(_onForgotPasswordRequested);
    on<AuthResetPasswordRequested>(_onResetPasswordRequested);
    on<AuthCheckStatusRequested>(_onCheckStatusRequested);
    on<AuthClearMessage>(_onClearMessage);
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await _authUseCase.login(event.email, event.password);

    if (result.success) {
      if (result.driver != null && result.token != null) {
        emit(AuthAuthenticated(driver: result.driver!, token: result.token!));
      } else {
        emit(AuthSuccess(message: result.message ?? 'Login successful'));
      }
    } else {
      emit(AuthError(message: result.message ?? 'Login failed'));
    }
  }

  Future<void> _onRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await _authUseCase.register(
      event.email,
      event.password,
      event.fullName,
      event.phoneNumber,
    );

    if (result.success) {
      emit(
        AuthRegistrationPending(
          email: event.email,
          message:
              result.message ??
              'Registration successful. Please verify your email.',
        ),
      );
    } else {
      emit(AuthError(message: result.message ?? 'Registration failed'));
    }
  }

  Future<void> _onOtpVerificationRequested(
    AuthOtpVerificationRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await _authUseCase.verifyOtp(event.email, event.otp);

    if (result.success) {
      // After OTP verification, user needs to enter company ID
      emit(
        AuthCompanyIdVerificationPending(
          driverId: result.data?['driverId'] ?? '',
          message:
              result.message ?? 'OTP verified. Please enter your company ID.',
        ),
      );
    } else {
      emit(AuthError(message: result.message ?? 'OTP verification failed'));
    }
  }

  Future<void> _onCompanyIdVerificationRequested(
    AuthCompanyIdVerificationRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await _authUseCase.verifyCompanyId(
      event.companyId,
      event.driverId,
    );

    if (result.success) {
      // Get driver data from storage after successful verification
      final driverData = StorageService.getJson(AppConstants.userDataKey);
      final token = await StorageService.getSecureData(
        AppConstants.authTokenKey,
      );

      if (driverData != null && token != null) {
        final driver = DriverModel.fromJson(driverData);
        emit(AuthAuthenticated(driver: driver, token: token));
      } else {
        emit(
          AuthSuccess(
            message: result.message ?? 'Company ID verified successfully',
          ),
        );
      }
    } else {
      emit(
        AuthError(message: result.message ?? 'Company ID verification failed'),
      );
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    await _authUseCase.logout();
    emit(AuthUnauthenticated());
  }

  Future<void> _onResendOtpRequested(
    AuthResendOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await _authUseCase.resendOtp(event.email);

    if (result.success) {
      emit(
        AuthOtpVerificationPending(
          email: event.email,
          message: result.message ?? 'OTP sent successfully',
        ),
      );
    } else {
      emit(AuthError(message: result.message ?? 'Failed to send OTP'));
    }
  }

  Future<void> _onForgotPasswordRequested(
    AuthForgotPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await _authUseCase.forgotPassword(event.email);

    if (result.success) {
      emit(
        AuthPasswordResetPending(
          email: event.email,
          message: result.message ?? 'Password reset OTP sent',
        ),
      );
    } else {
      emit(
        AuthError(
          message: result.message ?? 'Failed to send password reset OTP',
        ),
      );
    }
  }

  Future<void> _onResetPasswordRequested(
    AuthResetPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await _authUseCase.resetPassword(
      event.email,
      event.otp,
      event.newPassword,
    );

    if (result.success) {
      emit(
        AuthSuccess(message: result.message ?? 'Password reset successfully'),
      );
    } else {
      emit(AuthError(message: result.message ?? 'Password reset failed'));
    }
  }

  Future<void> _onCheckStatusRequested(
    AuthCheckStatusRequested event,
    Emitter<AuthState> emit,
  ) async {
    final isLoggedIn =
        StorageService.getBool(AppConstants.isLoggedInKey) ?? false;

    if (isLoggedIn) {
      final driverData = StorageService.getJson(AppConstants.userDataKey);
      final token = await StorageService.getSecureData(
        AppConstants.authTokenKey,
      );

      if (driverData != null && token != null) {
        final driver = DriverModel.fromJson(driverData);
        emit(AuthAuthenticated(driver: driver, token: token));
      } else {
        emit(AuthUnauthenticated());
      }
    } else {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onClearMessage(
    AuthClearMessage event,
    Emitter<AuthState> emit,
  ) async {
    if (state is AuthError || state is AuthSuccess) {
      emit(AuthUnauthenticated());
    }
  }
}
