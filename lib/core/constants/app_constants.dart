class AppConstants {
  // App Info
  static const String appName = 'Driver App';
  static const String appVersion = '1.0.0';

  // API Endpoints
  static const String baseUrl = 'https://your-api-domain.com/api/v1';
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String verifyOtpEndpoint = '/auth/verify-otp';
  static const String profileEndpoint = '/driver/profile';
  static const String ridesEndpoint = '/rides';
  static const String trackingEndpoint = '/tracking';

  // Firebase Collections
  static const String driversCollection = 'drivers';
  static const String ridesCollection = 'rides';
  static const String trackingCollection = 'tracking';
  static const String emergencyCollection = 'emergency_alerts';

  // Storage Keys
  static const String authTokenKey = 'auth_token';
  static const String userDataKey = 'user_data';
  static const String driverIdKey = 'driver_id';
  static const String companyIdKey = 'company_id';
  static const String isLoggedInKey = 'is_logged_in';
  static const String biometricEnabledKey = 'biometric_enabled';

  // Ride Status
  static const String rideStatusPending = 'pending';
  static const String rideStatusStarted = 'started';
  static const String rideStatusArrived = 'arrived';
  static const String rideStatusPickedUp = 'picked_up';
  static const String rideStatusInProgress = 'in_progress';
  static const String rideStatusCompleted = 'completed';
  static const String rideStatusCancelled = 'cancelled';

  // Permissions
  static const List<String> requiredPermissions = [
    'location',
    'camera',
    'storage',
    'phone',
  ];

  // Animation Durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 300);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 500);
  static const Duration longAnimationDuration = Duration(milliseconds: 800);

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double borderRadius = 12.0;
  static const double cardElevation = 2.0;

  // Location Constants
  static const double locationUpdateInterval = 5.0; // seconds
  static const double minDistanceFilter = 10.0; // meters
  static const double mapZoomLevel = 15.0;

  // Emergency
  static const String emergencyNumber = '911';
  static const String supportNumber = '+1-800-SUPPORT';

  // Validation
  static const int minPasswordLength = 8;
  static const int otpLength = 6;
  static const int maxNameLength = 50;
  static const int maxPlateNumberLength = 10;

  // File Upload
  static const int maxImageSizeInMB = 5;
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png'];
}

class AppStrings {
  // General
  static const String appName = 'Driver App';
  static const String loading = 'Loading...';
  static const String error = 'Error';
  static const String success = 'Success';
  static const String cancel = 'Cancel';
  static const String ok = 'OK';
  static const String save = 'Save';
  static const String edit = 'Edit';
  static const String delete = 'Delete';
  static const String confirm = 'Confirm';
  static const String retry = 'Retry';

  // Auth
  static const String login = 'Login';
  static const String register = 'Register';
  static const String logout = 'Logout';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String confirmPassword = 'Confirm Password';
  static const String forgotPassword = 'Forgot Password?';
  static const String verifyOtp = 'Verify OTP';
  static const String enterOtp = 'Enter OTP';
  static const String companyId = 'Company ID';
  static const String enterCompanyId = 'Enter Company-provided ID';

  // Profile
  static const String profile = 'Profile';
  static const String fullName = 'Full Name';
  static const String phoneNumber = 'Phone Number';
  static const String age = 'Age';
  static const String vehicleModel = 'Vehicle Model';
  static const String vehicleColor = 'Vehicle Color';
  static const String plateNumber = 'Plate Number';
  static const String insuranceDetails = 'Insurance Details';
  static const String profilePhoto = 'Profile Photo';

  // Rides
  static const String rides = 'Rides';
  static const String startRide = 'Start Ride';
  static const String newRide = 'New Ride';
  static const String pickupLocation = 'Pickup Location';
  static const String dropLocation = 'Drop Location';
  static const String fare = 'Fare';
  static const String employee = 'Employee';
  static const String startPickup = 'Start Pickup';
  static const String arrived = 'Arrived';
  static const String pickedUp = 'Picked Up';
  static const String endRide = 'End Ride';
  static const String rideHistory = 'Ride History';

  // Dashboard
  static const String dashboard = 'Dashboard';
  static const String todayRides = 'Today\'s Rides';
  static const String totalEarnings = 'Total Earnings';
  static const String activeRide = 'Active Ride';
  static const String quickActions = 'Quick Actions';

  // Support
  static const String support = 'Support';
  static const String help = 'Help';
  static const String emergency = 'Emergency';
  static const String sos = 'SOS';
  static const String contactSupport = 'Contact Support';
  static const String callSupport = 'Call Support';
  static const String chatSupport = 'Chat Support';

  // Error Messages
  static const String invalidEmail = 'Please enter a valid email address';
  static const String passwordTooShort =
      'Password must be at least 8 characters';
  static const String passwordMismatch = 'Passwords do not match';
  static const String invalidOtp = 'Invalid OTP';
  static const String networkError =
      'Network error. Please check your connection.';
  static const String unknownError = 'An unknown error occurred';
  static const String permissionDenied = 'Permission denied';
  static const String locationServiceDisabled =
      'Location services are disabled';

  // Success Messages
  static const String loginSuccess = 'Login successful';
  static const String registrationSuccess = 'Registration successful';
  static const String profileUpdated = 'Profile updated successfully';
  static const String rideStarted = 'Ride started successfully';
  static const String rideCompleted = 'Ride completed successfully';
}
