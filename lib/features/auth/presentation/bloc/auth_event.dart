part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginRequested({required this.email, required this.password});

  @override
  List<Object> get props => [email, password];
}

class AuthRegisterRequested extends AuthEvent {
  final String email;
  final String password;
  final String fullName;
  final String phoneNumber;

  const AuthRegisterRequested({
    required this.email,
    required this.password,
    required this.fullName,
    required this.phoneNumber,
  });

  @override
  List<Object> get props => [email, password, fullName, phoneNumber];
}

class AuthOtpVerificationRequested extends AuthEvent {
  final String email;
  final String otp;

  const AuthOtpVerificationRequested({required this.email, required this.otp});

  @override
  List<Object> get props => [email, otp];
}

class AuthCompanyIdVerificationRequested extends AuthEvent {
  final String companyId;
  final String driverId;

  const AuthCompanyIdVerificationRequested({
    required this.companyId,
    required this.driverId,
  });

  @override
  List<Object> get props => [companyId, driverId];
}

class AuthLogoutRequested extends AuthEvent {}

class AuthResendOtpRequested extends AuthEvent {
  final String email;

  const AuthResendOtpRequested({required this.email});

  @override
  List<Object> get props => [email];
}

class AuthForgotPasswordRequested extends AuthEvent {
  final String email;

  const AuthForgotPasswordRequested({required this.email});

  @override
  List<Object> get props => [email];
}

class AuthResetPasswordRequested extends AuthEvent {
  final String email;
  final String otp;
  final String newPassword;

  const AuthResetPasswordRequested({
    required this.email,
    required this.otp,
    required this.newPassword,
  });

  @override
  List<Object> get props => [email, otp, newPassword];
}

class AuthCheckStatusRequested extends AuthEvent {}

class AuthClearMessage extends AuthEvent {}
