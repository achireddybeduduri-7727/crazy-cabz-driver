/// Test credentials for development and demo purposes
class TestCredentials {
  // Primary test account
  static const String testEmail = 'test@driver.com';
  static const String testPassword = 'password123';

  // Alternative test accounts
  static const String driverEmail = 'driver@test.com';
  static const String driverPassword = 'test123';

  static const String adminEmail = 'admin@driver.com';
  static const String adminPassword = 'admin123';

  // All available test credentials
  static const List<Map<String, String>> allTestCredentials = [
    {
      'email': testEmail,
      'password': testPassword,
      'name': 'Test Driver',
      'description': 'Primary test account',
    },
    {
      'email': driverEmail,
      'password': driverPassword,
      'name': 'Demo Driver',
      'description': 'Alternative test account',
    },
    {
      'email': adminEmail,
      'password': adminPassword,
      'name': 'Admin Driver',
      'description': 'Admin test account',
    },
  ];

  /// Get formatted credentials for display/logging
  static String getCredentialsInfo() {
    final buffer = StringBuffer();
    buffer.writeln('📋 Available Test Credentials:');
    buffer.writeln('==============================');

    for (int i = 0; i < allTestCredentials.length; i++) {
      final cred = allTestCredentials[i];
      buffer.writeln('${i + 1}. ${cred['description']}');
      buffer.writeln('   Email: ${cred['email']}');
      buffer.writeln('   Password: ${cred['password']}');
      buffer.writeln('   Name: ${cred['name']}');
      if (i < allTestCredentials.length - 1) buffer.writeln();
    }

    return buffer.toString();
  }

  /// Print credentials to console for easy reference
  static void printCredentials() {
    print(getCredentialsInfo());
  }
}
