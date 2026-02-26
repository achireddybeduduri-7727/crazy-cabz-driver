# Driver App Testing Documentation

This document provides comprehensive information about the testing suite implemented for the Driver App.

## Testing Structure

The testing suite consists of three main types of tests:

### 1. Unit Tests (`test/unit/`)
Located in the `test/unit/` directory, these tests focus on testing individual components in isolation:

- **Service Tests**: Test business logic and service layer functionality
  - `storage_service_test.dart` - Tests local storage operations
  - `communication_service_test.dart` - Tests communication service functionality

### 2. Widget Tests (`test/widget/`)
Located in the `test/widget/` directory, these tests focus on testing UI components:

- Tests individual widgets and their interactions
- Verifies UI behavior and state changes
- Tests form inputs, navigation, and user interactions

### 3. Integration Tests (`integration_test/`)
Located in the `integration_test/` directory, these tests focus on end-to-end workflows:

- Tests complete user journeys
- Verifies navigation flows
- Tests form submissions and data persistence
- Tests interactions between multiple components

## Dependencies

The following testing dependencies have been added to `pubspec.yaml`:

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  mockito: ^5.4.4              # Mock object generation
  bloc_test: ^9.1.7            # BLoC pattern testing utilities
  network_image_mock: ^2.1.1   # Mock network images in tests
  integration_test:
    sdk: flutter
  flutter_driver:
    sdk: flutter
```

## Running Tests

### Run All Tests
```bash
flutter test
```

### Run Unit Tests Only
```bash
flutter test test/unit/
```

### Run Widget Tests Only
```bash
flutter test test/widget/
```

### Run Integration Tests
```bash
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/app_test.dart
```

### Run Tests with Coverage
```bash
flutter test --coverage
```

## Test Structure Guidelines

### Unit Tests
- Follow the **Arrange-Act-Assert** pattern
- Mock external dependencies using Mockito
- Test both success and error scenarios
- Aim for high code coverage (>80%)

Example:
```dart
test('should save and retrieve string value', () async {
  // Arrange
  const key = 'test_key';
  const value = 'test_value';

  // Act
  await storageService.saveString(key, value);
  final result = await storageService.getString(key);

  // Assert
  expect(result, equals(value));
});
```

### Widget Tests
- Use `testWidgets` for widget testing
- Pump widgets with `tester.pumpWidget()`
- Find elements using `find` methods
- Simulate user interactions with `tester.tap()`, `tester.enterText()`

Example:
```dart
testWidgets('should display counter and increment on button tap', (WidgetTester tester) async {
  await tester.pumpWidget(MyCounterWidget());
  
  expect(find.text('0'), findsOneWidget);
  
  await tester.tap(find.byIcon(Icons.add));
  await tester.pump();
  
  expect(find.text('1'), findsOneWidget);
});
```

### Integration Tests
- Use `IntegrationTestWidgetsFlutterBinding.ensureInitialized()`
- Test complete user workflows
- Use `pumpAndSettle()` for animations and async operations
- Test navigation, forms, and data persistence

## Mock Objects

### Storage Service Mock
```dart
class MockSharedPreferences extends Mock implements SharedPreferences {}
```

### Communication Service Mock
```dart
class MockCommunicationService extends Mock implements CommunicationService {}
```

## Best Practices

1. **Test Naming**: Use descriptive test names that explain what is being tested
2. **Test Organization**: Group related tests using `group()` blocks
3. **Setup/Teardown**: Use `setUp()` and `tearDown()` for common test setup
4. **Async Testing**: Use `async/await` for asynchronous operations
5. **Mock Verification**: Verify mock interactions using `verify()`
6. **Edge Cases**: Test error conditions and edge cases
7. **Maintainability**: Keep tests simple and focused on single functionality

## Continuous Integration

For CI/CD integration, use the following commands:

```yaml
# In your CI pipeline
- run: flutter test --coverage
- run: flutter drive --driver=test_driver/integration_test.dart --target=integration_test/app_test.dart
```

## Coverage Reports

Generate and view coverage reports:

```bash
# Generate coverage
flutter test --coverage

# Install lcov (Linux/Mac)
sudo apt-get install lcov  # Ubuntu
brew install lcov          # macOS

# Generate HTML report
genhtml coverage/lcov.info -o coverage/html

# Open report
open coverage/html/index.html
```

## Troubleshooting

### Common Issues

1. **Test Timeout**: Increase timeout for long-running tests
2. **Widget Not Found**: Ensure widgets are properly pumped and settled
3. **Mock Setup**: Verify mocks are properly configured before use
4. **Async Issues**: Use `pumpAndSettle()` for async operations

### Debugging Tests

```dart
// Print widget tree for debugging
debugDumpApp();

// Print render tree
debugDumpRenderTree();

// Add delays for debugging
await tester.pump(Duration(seconds: 1));
```

## Test Examples

### Service Testing Example
```dart
group('StorageService Tests', () {
  late MockSharedPreferences mockPrefs;
  late StorageService storageService;

  setUp(() {
    mockPrefs = MockSharedPreferences();
    storageService = StorageService(prefs: mockPrefs);
  });

  test('should save string value', () async {
    when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);
    
    await storageService.saveString('key', 'value');
    
    verify(mockPrefs.setString('key', 'value')).called(1);
  });
});
```

### Widget Testing Example
```dart
testWidgets('should show loading indicator', (WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(home: MyLoadingWidget()),
  );

  expect(find.byType(CircularProgressIndicator), findsOneWidget);
});
```

### Integration Testing Example
```dart
testWidgets('complete login flow', (WidgetTester tester) async {
  await tester.pumpWidget(MyApp());
  
  await tester.enterText(find.byKey(Key('email')), 'test@example.com');
  await tester.enterText(find.byKey(Key('password')), 'password123');
  await tester.tap(find.byKey(Key('login_button')));
  await tester.pumpAndSettle();
  
  expect(find.text('Dashboard'), findsOneWidget);
});
```

## Contributing

When adding new features:

1. Write unit tests for business logic
2. Write widget tests for UI components
3. Add integration tests for complete workflows
4. Ensure all tests pass before submitting PR
5. Maintain test coverage above 80%

## Resources

- [Flutter Testing Documentation](https://flutter.dev/docs/testing)
- [Mockito Documentation](https://pub.dev/packages/mockito)
- [BLoC Testing](https://pub.dev/packages/bloc_test)
- [Integration Testing](https://flutter.dev/docs/testing/integration-tests)