part of 'auth_bloc.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final DriverModel driver;
  final String token;

  const AuthAuthenticated({required this.driver, required this.token});

  @override
  List<Object> get props => [driver, token];
}

class AuthUnauthenticated extends AuthState {}

class AuthRegistrationPending extends AuthState {
  final String email;
  final String message;

  const AuthRegistrationPending({required this.email, required this.message});

  @override
  List<Object> get props => [email, message];
}

class AuthOtpVerificationPending extends AuthState {
  final String email;
  final String message;

  const AuthOtpVerificationPending({
    required this.email,
    required this.message,
  });

  @override
  List<Object> get props => [email, message];
}

class AuthCompanyIdVerificationPending extends AuthState {
  final String driverId;
  final String message;

  const AuthCompanyIdVerificationPending({
    required this.driverId,
    required this.message,
  });

  @override
  List<Object> get props => [driverId, message];
}

class AuthPasswordResetPending extends AuthState {
  final String email;
  final String message;

  const AuthPasswordResetPending({required this.email, required this.message});

  @override
  List<Object> get props => [email, message];
}

class AuthSuccess extends AuthState {
  final String message;

  const AuthSuccess({required this.message});

  @override
  List<Object> get props => [message];
}

class AuthError extends AuthState {
  final String message;

  const AuthError({required this.message});

  @override
  List<Object> get props => [message];
}
