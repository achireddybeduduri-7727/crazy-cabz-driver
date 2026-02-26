import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/services/storage_service.dart';
import 'core/services/notification_service.dart';
import 'core/network/network_service.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/app_logger.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/domain/auth_use_case_impl.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/profile/data/profile_repository.dart';
import 'features/profile/domain/profile_use_case_impl.dart';
import 'features/profile/presentation/bloc/profile_bloc.dart';
import 'features/profile/presentation/screens/profile_view_screen.dart';
import 'features/rides/presentation/bloc/ride_bloc.dart';
import 'features/rides/presentation/bloc/ride_event.dart';
import 'features/rides/presentation/bloc/route_bloc.dart';
import 'features/rides/presentation/screens/ride_screen.dart';
import 'features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'features/dashboard/presentation/screens/dashboard_screen.dart';
import 'features/earnings/presentation/screens/earnings_screen.dart';
import 'features/notifications/presentation/screens/notification_screen.dart';
import 'features/communication/presentation/screens/communication_screen.dart';
import 'features/rides/presentation/screens/add_manual_ride_screen.dart';
import 'features/rides/presentation/screens/ride_history_screen.dart';
import 'shared/models/driver_model.dart';
import 'shared/models/ride_model.dart';
import 'shared/widgets/app_notification_listener.dart';
import 'shared/widgets/persistent_navigation_wrapper.dart';
import 'firebase_options.dart';
import 'core/constants/test_credentials.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with platform-specific options
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Hive
  await Hive.initFlutter();

  // Register Hive adapters
  Hive.registerAdapter(DriverModelAdapter());
  Hive.registerAdapter(VehicleInfoAdapter());
  Hive.registerAdapter(InsuranceInfoAdapter());
  Hive.registerAdapter(RideModelAdapter());
  Hive.registerAdapter(LocationInfoAdapter());
  Hive.registerAdapter(LocationPointAdapter());

  // Initialize services
  await StorageService.init();
  await NotificationService().initialize();
  NetworkService().init();

  // Setup test environment only in debug mode
  if (kDebugMode) {
    await _setupTestEnvironment();
  }

  runApp(const DriverApp());
}

Future<void> _setupTestEnvironment() async {
  try {
    final authRepo = AuthRepository();
    AppLogger.info('Testing Firebase Auth connection...');

    final testResult = await authRepo.testFirebaseConnection();
    AppLogger.info('Firebase Auth connection: $testResult');

    if (testResult) {
      await authRepo.createTestUsers();
      AppLogger.info('Test users setup completed');
      TestCredentials.printCredentials();
    } else {
      AppLogger.error(
        'Firebase Auth connection failed - check console configuration',
      );
    }
  } catch (e) {
    AppLogger.error('Firebase initialization failed: $e');
    AppLogger.warning('Please check:');
    AppLogger.warning('1. Firebase project configuration');
    AppLogger.warning(
      '2. Email/Password authentication enabled in Firebase Console',
    );
    AppLogger.warning('3. Internet connection');
  }
}

class DriverApp extends StatelessWidget {
  const DriverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) =>
              AuthBloc(AuthUseCaseImpl(AuthRepository()))
                ..add(AuthCheckStatusRequested()),
        ),
        BlocProvider<ProfileBloc>(
          create: (context) =>
              ProfileBloc(ProfileUseCaseImpl(ProfileRepository())),
        ),
        BlocProvider<RideBloc>(create: (context) => RideBloc()),
        BlocProvider<RouteBloc>(create: (context) => RouteBloc()),
        BlocProvider<DashboardBloc>(create: (context) => DashboardBloc()),
      ],
      child: MaterialApp(
        title: 'Driver App',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: AppNotificationListener(
          child: BlocListener<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is AuthAuthenticated) {
                context.read<RideBloc>().add(LoadActiveRide(state.driver.id));
              }
            },
            child: BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                if (state is AuthAuthenticated) {
                  // Navigate to rides screen with persistent navigation
                  return PersistentNavigationWrapper(
                    driver: state.driver,
                    initialIndex: 0,
                  );
                }
                return const LoginScreen();
              },
            ),
          ),
        ),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/profile': (context) {
            final args = ModalRoute.of(context)!.settings.arguments;
            if (args is DriverModel) {
              return ProfileViewScreen(driver: args);
            }
            return _buildErrorScreen();
          },
          '/rides': (context) {
            final args = ModalRoute.of(context)!.settings.arguments;
            if (args is String) {
              return RideScreen(driverId: args);
            }
            return _buildErrorScreen();
          },
          '/dashboard': (context) {
            final args = ModalRoute.of(context)!.settings.arguments;
            if (args is DriverModel) {
              return DashboardScreen(driver: args);
            }
            return _buildErrorScreen();
          },
          '/earnings': (context) => const EarningsScreen(),
          '/notifications': (context) => const NotificationScreen(),
          '/history': (context) => const RideHistoryScreen(),
          '/communication': (context) {
            final args = ModalRoute.of(context)!.settings.arguments;
            if (args is DriverModel) {
              return CommunicationScreen(driver: args);
            }
            return _buildErrorScreen();
          },
          '/add-manual-ride': (context) {
            final args = ModalRoute.of(context)!.settings.arguments;
            if (args is DriverModel) {
              return AddManualRideScreen(driver: args);
            }
            return _buildErrorScreen();
          },
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: const Center(child: Text('Invalid route arguments.')),
    );
  }
}
