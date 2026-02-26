import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:geocoding/geocoding.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../../../../shared/models/driver_model.dart';
import '../../../../shared/models/route_model.dart';
import '../../../../shared/models/passenger_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/route_bloc.dart';
import '../bloc/route_event.dart';
import '../bloc/route_state.dart';

// Helper class for managing passenger information in forms
class PassengerInfo {
  final TextEditingController nameController;
  final TextEditingController phoneController;

  // Individual pickup location controllers for each passenger
  final TextEditingController pickupStreetController;
  final TextEditingController pickupAptController;
  final TextEditingController pickupCityController;
  final TextEditingController pickupStateController;
  final TextEditingController pickupZipController;

  // Individual drop-off location controllers for each passenger
  final TextEditingController dropStreetController;
  final TextEditingController dropAptController;
  final TextEditingController dropCityController;
  final TextEditingController dropStateController;
  final TextEditingController dropZipController;

  // Flags to indicate if passenger uses shared locations
  bool useSharedPickup;
  bool useSharedDropoff;

  PassengerInfo({
    String? name,
    String? phone,
    String? pickupStreet,
    String? pickupApt,
    String? pickupCity,
    String? pickupState,
    String? pickupZip,
    String? dropStreet,
    String? dropApt,
    String? dropCity,
    String? dropState,
    String? dropZip,
    this.useSharedPickup = true,
    this.useSharedDropoff = true,
  }) : nameController = TextEditingController(text: name),
       phoneController = TextEditingController(text: phone),
       pickupStreetController = TextEditingController(text: pickupStreet),
       pickupAptController = TextEditingController(text: pickupApt),
       pickupCityController = TextEditingController(text: pickupCity),
       pickupStateController = TextEditingController(text: pickupState),
       pickupZipController = TextEditingController(text: pickupZip),
       dropStreetController = TextEditingController(text: dropStreet),
       dropAptController = TextEditingController(text: dropApt),
       dropCityController = TextEditingController(text: dropCity),
       dropStateController = TextEditingController(text: dropState),
       dropZipController = TextEditingController(text: dropZip);

  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    pickupStreetController.dispose();
    pickupAptController.dispose();
    pickupCityController.dispose();
    pickupStateController.dispose();
    pickupZipController.dispose();
    dropStreetController.dispose();
    dropAptController.dispose();
    dropCityController.dispose();
    dropStateController.dispose();
    dropZipController.dispose();
  }

  bool get isValid =>
      nameController.text.trim().isNotEmpty &&
      phoneController.text.trim().isNotEmpty;

  bool get hasValidPickup =>
      useSharedPickup ||
      (pickupStreetController.text.trim().isNotEmpty &&
          pickupCityController.text.trim().isNotEmpty &&
          pickupStateController.text.trim().isNotEmpty &&
          pickupZipController.text.trim().isNotEmpty);

  bool get hasValidDropoff =>
      useSharedDropoff ||
      (dropStreetController.text.trim().isNotEmpty &&
          dropCityController.text.trim().isNotEmpty &&
          dropStateController.text.trim().isNotEmpty &&
          dropZipController.text.trim().isNotEmpty);

  String get pickupAddress {
    if (useSharedPickup) return '';
    final parts = [
      pickupStreetController.text.trim(),
      pickupAptController.text.trim().isNotEmpty
          ? pickupAptController.text.trim()
          : '',
      pickupCityController.text.trim(),
      pickupStateController.text.trim(),
      pickupZipController.text.trim(),
    ].where((part) => part.isNotEmpty);
    return parts.join(', ');
  }

  String get dropoffAddress {
    if (useSharedDropoff) return '';
    final parts = [
      dropStreetController.text.trim(),
      dropAptController.text.trim().isNotEmpty
          ? dropAptController.text.trim()
          : '',
      dropCityController.text.trim(),
      dropStateController.text.trim(),
      dropZipController.text.trim(),
    ].where((part) => part.isNotEmpty);
    return parts.join(', ');
  }

  PassengerModel toPassengerModel() {
    return PassengerModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      fullName: nameController.text.trim(),
      phoneNumber: phoneController.text.trim(),
      department: 'Manual Booking',
      employeeId: 'MB${DateTime.now().millisecondsSinceEpoch}',
      homeAddress: 'Manual Ride - No Home Address',
      homeLatitude: 0.0,
      homeLongitude: 0.0,
      createdAt: DateTime.now(),
    );
  }
}

class AddManualRideScreen extends StatefulWidget {
  final DriverModel driver;

  const AddManualRideScreen({super.key, required this.driver});

  @override
  State<AddManualRideScreen> createState() => _AddManualRideScreenState();
}

class _AddManualRideScreenState extends State<AddManualRideScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  // Pickup address controllers
  final _pickupStreetController = TextEditingController();
  final _pickupAptController = TextEditingController();
  final _pickupCityController = TextEditingController();
  final _pickupStateController = TextEditingController();
  final _pickupZipController = TextEditingController();

  // Drop address controllers
  final _dropStreetController = TextEditingController();
  final _dropAptController = TextEditingController();
  final _dropCityController = TextEditingController();
  final _dropStateController = TextEditingController();
  final _dropZipController = TextEditingController();

  final _fareController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isLoading = false;

  // Ride type selection
  bool _isGroupRide = false;
  final List<PassengerInfo> _passengers = [
    PassengerInfo(),
  ]; // Start with one passenger

  // Address suggestions
  List<String> _pickupSuggestions = [];
  List<String> _dropSuggestions = [];

  // Debounce timers for address suggestions
  Timer? _pickupDebounceTimer;
  Timer? _dropDebounceTimer;

  // Enhanced validation methods
  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (value.trim().length > 50) {
      return 'Name cannot exceed 50 characters';
    }
    // Allow letters, spaces, hyphens, apostrophes, and periods
    final namePattern = RegExp(r"^[a-zA-Z\s\-'.]+$");
    if (!namePattern.hasMatch(value.trim())) {
      return 'Name can only contain letters, spaces, hyphens, apostrophes, and periods';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }

    // Remove all non-digit characters for validation
    final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');

    if (digitsOnly.length < 10) {
      return 'Phone number must be at least 10 digits';
    }
    if (digitsOnly.length > 15) {
      return 'Phone number cannot exceed 15 digits';
    }

    // Basic phone format validation - allow various formats
    final phonePattern = RegExp(r'^[\+]?[\d\s\-\(\)\.]{10,}$');
    if (!phonePattern.hasMatch(value.trim())) {
      return 'Please enter a valid phone number format';
    }

    return null;
  }

  String? _validateStreetAddress(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    if (value.trim().length < 5) {
      return '$fieldName must be at least 5 characters';
    }
    if (value.trim().length > 100) {
      return '$fieldName cannot exceed 100 characters';
    }
    return null;
  }

  String? _validateCity(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    if (value.trim().length < 2) {
      return '$fieldName must be at least 2 characters';
    }
    if (value.trim().length > 50) {
      return '$fieldName cannot exceed 50 characters';
    }
    // Allow letters, spaces, hyphens, apostrophes, and periods for city names
    final cityPattern = RegExp(r"^[a-zA-Z\s\-'.]+$");
    if (!cityPattern.hasMatch(value.trim())) {
      return '$fieldName can only contain letters, spaces, hyphens, apostrophes, and periods';
    }
    return null;
  }

  String? _validateState(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    if (value.trim().length < 2) {
      return '$fieldName must be at least 2 characters';
    }
    if (value.trim().length > 30) {
      return '$fieldName cannot exceed 30 characters';
    }
    return null;
  }

  String? _validateZipCode(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }

    // US ZIP code format (5 digits or 5+4 format)
    final zipPattern = RegExp(r'^\d{5}(-\d{4})?$');
    if (!zipPattern.hasMatch(value.trim())) {
      return 'Please enter a valid ZIP code (e.g., 12345 or 12345-6789)';
    }

    return null;
  }

  String? _validateApartment(String? value) {
    if (value != null && value.trim().isNotEmpty && value.trim().length > 20) {
      return 'Apartment/Unit cannot exceed 20 characters';
    }
    return null;
  }

  String? _validateFare(String? value) {
    if (value != null && value.trim().isNotEmpty) {
      final fareValue = double.tryParse(value.trim());
      if (fareValue == null) {
        return 'Please enter a valid fare amount';
      }
      if (fareValue < 0) {
        return 'Fare cannot be negative';
      }
      if (fareValue > 1000) {
        return 'Fare cannot exceed \$1000';
      }
    }
    return null;
  }

  String? _validateNotes(String? value) {
    if (value != null && value.trim().length > 500) {
      return 'Notes cannot exceed 500 characters';
    }
    return null;
  }

  bool _isFormValid() {
    // Check basic form validation
    if (!_formKey.currentState!.validate()) {
      return false;
    }

    // Check date and time selection
    if (_selectedDate == null) {
      _showValidationError('Please select a pickup date');
      return false;
    }

    if (_selectedTime == null) {
      _showValidationError('Please select a pickup time');
      return false;
    }

    // Check if selected time is not in the past (with 5-minute grace period)
    final scheduledDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    if (scheduledDateTime.isBefore(
      DateTime.now().subtract(const Duration(minutes: 5)),
    )) {
      _showValidationError('Pickup time cannot be in the past');
      return false;
    }

    // Validate ride type specific requirements
    if (!_isGroupRide) {
      // Individual ride validation
      if (_nameController.text.trim().isEmpty) {
        _showValidationError('Please enter passenger name');
        return false;
      }
      if (_phoneController.text.trim().isEmpty) {
        _showValidationError('Please enter phone number');
        return false;
      }
    } else {
      // Group ride validation
      if (_passengers.isEmpty) {
        _showValidationError(
          'Please add at least one passenger for group ride',
        );
        return false;
      }

      for (int i = 0; i < _passengers.length; i++) {
        final passenger = _passengers[i];
        if (!passenger.isValid) {
          _showValidationError(
            'Please complete information for passenger ${i + 1}',
          );
          return false;
        }
        if (!passenger.hasValidPickup) {
          _showValidationError(
            'Please enter pickup address for passenger ${i + 1}',
          );
          return false;
        }
        if (!passenger.hasValidDropoff) {
          _showValidationError(
            'Please enter drop-off address for passenger ${i + 1}',
          );
          return false;
        }
      }
    }

    return true;
  }

  List<String> _getDetailedValidationErrors() {
    List<String> errors = [];

    // Validate individual ride fields if not group ride
    if (!_isGroupRide) {
      final nameError = _validateName(_nameController.text);
      if (nameError != null) errors.add(nameError);

      final phoneError = _validatePhone(_phoneController.text);
      if (phoneError != null) errors.add(phoneError);
    }

    // Validate address fields
    final pickupStreetError = _validateStreetAddress(
      _pickupStreetController.text,
      'Pickup street',
    );
    if (pickupStreetError != null) errors.add(pickupStreetError);

    final pickupCityError = _validateCity(
      _pickupCityController.text,
      'Pickup city',
    );
    if (pickupCityError != null) errors.add(pickupCityError);

    final pickupStateError = _validateState(
      _pickupStateController.text,
      'Pickup state',
    );
    if (pickupStateError != null) errors.add(pickupStateError);

    final pickupZipError = _validateZipCode(
      _pickupZipController.text,
      'Pickup ZIP code',
    );
    if (pickupZipError != null) errors.add(pickupZipError);

    final dropStreetError = _validateStreetAddress(
      _dropStreetController.text,
      'Drop-off street',
    );
    if (dropStreetError != null) errors.add(dropStreetError);

    final dropCityError = _validateCity(
      _dropCityController.text,
      'Drop-off city',
    );
    if (dropCityError != null) errors.add(dropCityError);

    final dropStateError = _validateState(
      _dropStateController.text,
      'Drop-off state',
    );
    if (dropStateError != null) errors.add(dropStateError);

    final dropZipError = _validateZipCode(
      _dropZipController.text,
      'Drop-off ZIP code',
    );
    if (dropZipError != null) errors.add(dropZipError);

    // Validate optional fields
    final apartmentError = _validateApartment(_pickupAptController.text);
    if (apartmentError != null) errors.add(apartmentError);

    final fareError = _validateFare(_fareController.text);
    if (fareError != null) errors.add(fareError);

    final notesError = _validateNotes(_notesController.text);
    if (notesError != null) errors.add(notesError);

    // Validate group ride passengers if applicable
    if (_isGroupRide) {
      for (int i = 0; i < _passengers.length; i++) {
        final passenger = _passengers[i];

        final passengerNameError = _validateName(passenger.nameController.text);
        if (passengerNameError != null) {
          errors.add('Passenger ${i + 1}: $passengerNameError');
        }

        final passengerPhoneError = _validatePhone(
          passenger.phoneController.text,
        );
        if (passengerPhoneError != null) {
          errors.add('Passenger ${i + 1}: $passengerPhoneError');
        }
      }
    }

    return errors;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();

    // Pickup address controllers
    _pickupStreetController.dispose();
    _pickupAptController.dispose();
    _pickupCityController.dispose();
    _pickupStateController.dispose();
    _pickupZipController.dispose();

    // Drop address controllers
    _dropStreetController.dispose();
    _dropAptController.dispose();
    _dropCityController.dispose();
    _dropStateController.dispose();
    _dropZipController.dispose();

    _fareController.dispose();
    _notesController.dispose();

    // Dispose passenger controllers
    for (final passenger in _passengers) {
      passenger.dispose();
    }

    // Cancel debounce timers
    _pickupDebounceTimer?.cancel();
    _dropDebounceTimer?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Manual Ride'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: BlocConsumer<RouteBloc, RouteState>(
        listener: (context, state) {
          print('🔄 DEBUG: BlocConsumer received state: ${state.runtimeType}');

          // Update loading state with enhanced feedback
          setState(() {
            _isLoading = state is RouteLoading || state is RouteUpdating;
          });

          if (state is RouteLoading) {
            print('⏳ DEBUG: Route loading state received');
            // Show loading feedback to user
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    SizedBox(width: 12),
                    Text('Creating your ride...'),
                  ],
                ),
                backgroundColor: Colors.blue,
                duration: Duration(seconds: 2),
              ),
            );
          } else if (state is RouteUpdating) {
            print('🔄 DEBUG: Route updating state received - ${state.action}');
            // Show progressive update feedback
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(state.action)),
                  ],
                ),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 1),
              ),
            );
          } else if (state is RouteSuccess) {
            print('✅ DEBUG: RouteSuccess received - ${state.message}');

            // Clear any existing snackbars first
            ScaffoldMessenger.of(context).clearSnackBars();

            // Show enhanced success feedback
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ride Created Successfully!',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${state.route.rides.length} passenger(s) scheduled',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 4),
                action: SnackBarAction(
                  label: 'VIEW',
                  textColor: Colors.white,
                  onPressed: () {
                    _showNavigationDialog(context, state.route);
                  },
                ),
              ),
            );

            // Show navigation dialog with enhanced delay for better UX
            Future.delayed(const Duration(milliseconds: 800), () {
              if (mounted) {
                _showNavigationDialog(context, state.route);
              }
            });
          } else if (state is NavigationLaunched) {
            print('🧭 DEBUG: NavigationLaunched received - ${state.message}');

            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.navigation, color: Colors.white, size: 20),
                    const SizedBox(width: 12),
                    Expanded(child: Text(state.message)),
                  ],
                ),
                backgroundColor: Colors.blue,
                duration: const Duration(seconds: 3),
              ),
            );

            // Close the screen after launching navigation with enhanced delay
            Future.delayed(const Duration(milliseconds: 1500), () {
              if (mounted && Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            });
          } else if (state is RouteError) {
            print('❌ DEBUG: RouteError received - ${state.message}');
            print('🔍 DEBUG: Error code: ${state.errorCode ?? 'UNKNOWN'}');

            ScaffoldMessenger.of(context).clearSnackBars();

            // Enhanced error feedback with specific icons and colors
            Color errorColor = Colors.red;
            IconData errorIcon = Icons.error;
            String actionLabel = 'RETRY';

            // Customize based on error type
            if (state.errorCode == 'VALIDATION_ERROR') {
              errorColor = Colors.orange;
              errorIcon = Icons.warning;
              actionLabel = 'FIX';
            } else if (state.errorCode == 'NETWORK_ERROR') {
              errorColor = Colors.red.shade700;
              errorIcon = Icons.wifi_off;
              actionLabel = 'RETRY';
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(errorIcon, color: Colors.white, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Failed to Create Ride',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            state.message,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                backgroundColor: errorColor,
                duration: const Duration(seconds: 6),
                action: SnackBarAction(
                  label: actionLabel,
                  textColor: Colors.white,
                  onPressed: () {
                    // Enhanced retry logic based on error type
                    if (state.errorCode == 'VALIDATION_ERROR') {
                      // Scroll to top to show validation issues
                      print('🔍 DEBUG: User requested validation fix');
                    } else {
                      // Retry the submission
                      print('🔄 DEBUG: User requested retry');
                      _submitForm();
                    }
                  },
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          return LoadingOverlay(
            isLoading: _isLoading,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.person_add,
                            size: 48,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Create Manual Ride',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Add a custom ride for employee transportation',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Ride Type Selection
                    _buildRideTypeSelector(),
                    const SizedBox(height: 24),

                    // Passenger Information
                    _buildPassengerSection(),
                    const SizedBox(height: 24),

                    // Pickup Location Information
                    _buildSectionHeader('Pickup Location'),
                    const SizedBox(height: 12),
                    _buildAddressSection(
                      streetController: _pickupStreetController,
                      aptController: _pickupAptController,
                      cityController: _pickupCityController,
                      stateController: _pickupStateController,
                      zipController: _pickupZipController,
                      suggestions: _pickupSuggestions,
                      onStreetChanged: _onPickupStreetChanged,
                    ),
                    const SizedBox(height: 24),

                    // Drop-off Location Information
                    _buildSectionHeader('Drop-off Location'),
                    const SizedBox(height: 12),
                    _buildAddressSection(
                      streetController: _dropStreetController,
                      aptController: _dropAptController,
                      cityController: _dropCityController,
                      stateController: _dropStateController,
                      zipController: _dropZipController,
                      suggestions: _dropSuggestions,
                      onStreetChanged: _onDropStreetChanged,
                    ),
                    const SizedBox(height: 24),

                    // Timing Information
                    _buildSectionHeader('Timing Information'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildDateSelector()),
                        const SizedBox(width: 12),
                        Expanded(child: _buildTimeSelector()),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Fare Information
                    _buildSectionHeader('Fare Information'),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: _fareController,
                      label: 'Ride Fare (\$)',
                      hintText: 'Enter fare amount',
                      prefixIcon: Icons.money,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Fare amount is required';
                        }
                        final fare = double.tryParse(value.trim());
                        if (fare == null || fare <= 0) {
                          return 'Enter a valid fare amount';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Additional Notes
                    _buildSectionHeader('Additional Notes (Optional)'),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: _notesController,
                      label: 'Notes',
                      hintText: 'Any special instructions or notes',
                      prefixIcon: Icons.note,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 32),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        text: 'Create Manual Ride',
                        onPressed: _isLoading ? null : _submitForm,
                        isLoading: _isLoading,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Cancel Button
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildRideTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Ride Type'),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isGroupRide = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 20,
                    ),
                    decoration: BoxDecoration(
                      color: !_isGroupRide
                          ? AppTheme.primaryColor
                          : Colors.transparent,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person,
                          color: !_isGroupRide
                              ? Colors.white
                              : Colors.grey.shade600,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Individual',
                          style: TextStyle(
                            color: !_isGroupRide
                                ? Colors.white
                                : Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isGroupRide = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 20,
                    ),
                    decoration: BoxDecoration(
                      color: _isGroupRide
                          ? AppTheme.primaryColor
                          : Colors.transparent,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.group,
                          color: _isGroupRide
                              ? Colors.white
                              : Colors.grey.shade600,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Group',
                          style: TextStyle(
                            color: _isGroupRide
                                ? Colors.white
                                : Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (_isGroupRide) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade600, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Group rides support flexible pickup/drop-off locations. Each passenger can use shared locations or have individual addresses.',
                    style: TextStyle(fontSize: 13, color: Colors.blue.shade700),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPassengerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _buildSectionHeader('Passenger Information')),
            if (_isGroupRide) ...[
              Text(
                '${_passengers.length} passenger${_passengers.length == 1 ? '' : 's'}',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _addPassenger,
                icon: const Icon(
                  Icons.add_circle,
                  color: AppTheme.primaryColor,
                ),
                tooltip: 'Add Passenger',
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),

        if (!_isGroupRide) ...[
          // Individual ride - single passenger
          _buildPassengerForm(
            nameController: _nameController,
            phoneController: _phoneController,
            showRemoveButton: false,
            onRemove: () {},
          ),
        ] else ...[
          // Group ride - multiple passengers
          if (_passengers.isEmpty) ...[
            _buildEmptyPassengerState(),
          ] else ...[
            for (int i = 0; i < _passengers.length; i++) ...[
              _buildPassengerForm(
                nameController: _passengers[i].nameController,
                phoneController: _passengers[i].phoneController,
                showRemoveButton: _passengers.length > 1,
                onRemove: () => _removePassenger(i),
                passengerNumber: i + 1,
              ),
              if (i < _passengers.length - 1) const SizedBox(height: 16),
            ],
          ],
        ],
      ],
    );
  }

  Widget _buildPassengerForm({
    required TextEditingController nameController,
    required TextEditingController phoneController,
    required bool showRemoveButton,
    required VoidCallback onRemove,
    int? passengerNumber,
  }) {
    final isGroupRide = passengerNumber != null;
    final passengerInfo = isGroupRide ? _passengers[passengerNumber - 1] : null;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (passengerNumber != null) ...[
            Row(
              children: [
                Text(
                  'Passenger $passengerNumber',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const Spacer(),
                if (showRemoveButton)
                  IconButton(
                    onPressed: onRemove,
                    icon: const Icon(Icons.remove_circle, color: Colors.red),
                    tooltip: 'Remove Passenger',
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          CustomTextField(
            controller: nameController,
            label: 'Passenger Name',
            hintText: 'Enter full name',
            prefixIcon: Icons.person,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Passenger name is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: phoneController,
            label: 'Phone Number',
            hintText: 'Enter phone number',
            prefixIcon: Icons.phone,
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Phone number is required';
              }
              if (value.trim().length < 10) {
                return 'Enter a valid phone number';
              }
              return null;
            },
          ),

          // Location settings for group rides
          if (isGroupRide && passengerInfo != null) ...[
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),

            Text(
              'Location Settings',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 12),

            // Pickup location options
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Pickup Location',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<bool>(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Shared', style: TextStyle(fontSize: 14)),
                    value: true,
                    groupValue: passengerInfo.useSharedPickup,
                    onChanged: (value) {
                      setState(() {
                        passengerInfo.useSharedPickup = value!;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<bool>(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Individual',
                      style: TextStyle(fontSize: 14),
                    ),
                    value: false,
                    groupValue: passengerInfo.useSharedPickup,
                    onChanged: (value) {
                      setState(() {
                        passengerInfo.useSharedPickup = value!;
                      });
                    },
                  ),
                ),
              ],
            ),

            // Individual pickup address fields
            if (!passengerInfo.useSharedPickup) ...[
              const SizedBox(height: 12),
              CustomTextField(
                controller: passengerInfo.pickupStreetController,
                label: 'Individual Pickup Street',
                hintText: 'Enter street address',
                prefixIcon: Icons.location_on,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: passengerInfo.pickupCityController,
                      label: 'City',
                      hintText: 'City',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      controller: passengerInfo.pickupStateController,
                      label: 'State',
                      hintText: 'State',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      controller: passengerInfo.pickupZipController,
                      label: 'ZIP',
                      hintText: 'ZIP',
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 16),

            // Drop-off location options
            Row(
              children: [
                Icon(Icons.flag, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Drop-off Location',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<bool>(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Shared', style: TextStyle(fontSize: 14)),
                    value: true,
                    groupValue: passengerInfo.useSharedDropoff,
                    onChanged: (value) {
                      setState(() {
                        passengerInfo.useSharedDropoff = value!;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<bool>(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Individual',
                      style: TextStyle(fontSize: 14),
                    ),
                    value: false,
                    groupValue: passengerInfo.useSharedDropoff,
                    onChanged: (value) {
                      setState(() {
                        passengerInfo.useSharedDropoff = value!;
                      });
                    },
                  ),
                ),
              ],
            ),

            // Individual drop-off address fields
            if (!passengerInfo.useSharedDropoff) ...[
              const SizedBox(height: 12),
              CustomTextField(
                controller: passengerInfo.dropStreetController,
                label: 'Individual Drop-off Street',
                hintText: 'Enter street address',
                prefixIcon: Icons.flag,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: passengerInfo.dropCityController,
                      label: 'City',
                      hintText: 'City',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      controller: passengerInfo.dropStateController,
                      label: 'State',
                      hintText: 'State',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      controller: passengerInfo.dropZipController,
                      label: 'ZIP',
                      hintText: 'ZIP',
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyPassengerState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey.shade200,
          style: BorderStyle.solid,
        ),
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade50,
      ),
      child: Column(
        children: [
          Icon(Icons.group_add, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            'No passengers added yet',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to add passengers',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade500),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _addPassenger,
            icon: const Icon(Icons.add),
            label: const Text('Add First Passenger'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return GestureDetector(
      onTap: _selectDate,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: AppTheme.primaryColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Date',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    _selectedDate != null
                        ? DateFormat('dd/MM/yyyy').format(_selectedDate!)
                        : 'Select date',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSelector() {
    return GestureDetector(
      onTap: _selectTime,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.access_time, color: AppTheme.primaryColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Time',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    _selectedTime != null
                        ? _selectedTime!.format(context)
                        : 'Select time',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _addPassenger() {
    setState(() {
      _passengers.add(PassengerInfo());
    });
  }

  void _removePassenger(int index) {
    if (index >= 0 && index < _passengers.length) {
      setState(() {
        _passengers[index].dispose();
        _passengers.removeAt(index);
      });
    }
  }

  void _submitForm() {
    print('🚀 DEBUG: Enhanced _submitForm called');
    print('📋 DEBUG: Validation summary: ${_getValidationSummary()}');

    // Prevent multiple submissions with enhanced feedback
    if (_isLoading) {
      print('⏳ DEBUG: Already submitting, ignoring duplicate call');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please wait, processing your request...'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      print('🔍 DEBUG: Starting comprehensive validation');

      // Use enhanced validation method first
      if (!_isFormValid()) {
        print('❌ DEBUG: Enhanced form validation failed');
        return; // _isFormValid already shows error messages
      }
      print('✅ DEBUG: Enhanced form validation passed');

      // Additional detailed validation for better user experience
      final validationErrors = _getDetailedValidationErrors();
      if (validationErrors.isNotEmpty) {
        print('❌ DEBUG: Detailed validation errors found: $validationErrors');
        _showValidationError(validationErrors.first);
        return;
      }
      print('✅ DEBUG: All detailed validations passed');

      // Create scheduled time with validation
      final scheduledTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );
      print('⏰ DEBUG: Scheduled time: $scheduledTime');

      // Build full addresses from individual components
      final pickupAddress = _getFullAddress(
        street: _pickupStreetController.text.trim(),
        apt: _pickupAptController.text.trim(),
        city: _pickupCityController.text.trim(),
        state: _pickupStateController.text.trim(),
        zip: _pickupZipController.text.trim(),
      );

      final dropOffAddress = _getFullAddress(
        street: _dropStreetController.text.trim(),
        apt: _dropAptController.text.trim(),
        city: _dropCityController.text.trim(),
        state: _dropStateController.text.trim(),
        zip: _dropZipController.text.trim(),
      );

      print('📍 DEBUG: Pickup Address: $pickupAddress');
      print('📍 DEBUG: Drop-off Address: $dropOffAddress');

      // Create passenger models based on ride type
      List<IndividualRide> individualRides = [];
      final baseTimestamp = DateTime.now().millisecondsSinceEpoch;

      if (!_isGroupRide) {
        // Individual ride - single passenger with enhanced validation
        print('👤 DEBUG: Creating individual ride');

        final passenger = PassengerModel(
          id: baseTimestamp.toString(),
          employeeId: 'MANUAL_$baseTimestamp',
          fullName: _nameController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          department: 'Manual Entry',
          homeAddress: pickupAddress,
          homeLatitude: 0.0, // Will be updated when driver navigates
          homeLongitude: 0.0,
          profilePhotoUrl: null,
          createdAt: DateTime.now(),
        );

        final individualRide = IndividualRide(
          id: '${baseTimestamp}_ride',
          routeId: 'MANUAL_$baseTimestamp',
          passenger: passenger,
          status: IndividualRideStatus.scheduled,
          pickupAddress: pickupAddress,
          pickupLatitude: 0.0, // Will be updated when driver navigates
          pickupLongitude: 0.0,
          dropOffAddress: dropOffAddress,
          dropOffLatitude: 0.0, // Will be updated when driver navigates
          dropOffLongitude: 0.0,
          scheduledPickupTime: scheduledTime,
          routeOrder: 1,
          passengerNotes: _notesController.text.trim().isNotEmpty
              ? _notesController.text.trim()
              : null,
          isPresent: false,
          createdAt: DateTime.now(),
        );

        individualRides.add(individualRide);
        print('✅ DEBUG: Individual ride created for ${passenger.fullName}');
      } else {
        // Group ride - multiple passengers with comprehensive validation
        print(
          '👥 DEBUG: Creating group ride with ${_passengers.length} passengers',
        );

        for (int i = 0; i < _passengers.length; i++) {
          final passengerInfo = _passengers[i];
          print(
            '👤 DEBUG: Processing passenger ${i + 1}: ${passengerInfo.nameController.text.trim()}',
          );

          // Determine pickup address for this passenger
          final passengerPickupAddress = passengerInfo.useSharedPickup
              ? pickupAddress
              : passengerInfo.pickupAddress;

          // Determine drop-off address for this passenger
          final passengerDropOffAddress = passengerInfo.useSharedDropoff
              ? dropOffAddress
              : passengerInfo.dropoffAddress;

          final passenger = PassengerModel(
            id: '${baseTimestamp}_passenger_$i',
            employeeId: 'MANUAL_GROUP_${baseTimestamp}_$i',
            fullName: passengerInfo.nameController.text.trim(),
            phoneNumber: passengerInfo.phoneController.text.trim(),
            department: 'Manual Entry - Group',
            homeAddress: passengerPickupAddress,
            homeLatitude: 0.0,
            homeLongitude: 0.0,
            profilePhotoUrl: null,
            createdAt: DateTime.now(),
          );

          final individualRide = IndividualRide(
            id: '${baseTimestamp}_ride_$i',
            routeId: 'MANUAL_GROUP_$baseTimestamp',
            passenger: passenger,
            status: IndividualRideStatus.scheduled,
            pickupAddress: passengerPickupAddress,
            pickupLatitude: 0.0,
            pickupLongitude: 0.0,
            dropOffAddress: passengerDropOffAddress,
            dropOffLatitude: 0.0,
            dropOffLongitude: 0.0,
            scheduledPickupTime: scheduledTime,
            routeOrder: i + 1,
            passengerNotes: _notesController.text.trim().isNotEmpty
                ? '${_notesController.text.trim()} | Pickup: ${passengerInfo.useSharedPickup ? "Shared" : "Individual"} | Drop-off: ${passengerInfo.useSharedDropoff ? "Shared" : "Individual"}'
                : 'Pickup: ${passengerInfo.useSharedPickup ? "Shared" : "Individual"} | Drop-off: ${passengerInfo.useSharedDropoff ? "Shared" : "Individual"}',
            isPresent: false,
            createdAt: DateTime.now(),
          );

          individualRides.add(individualRide);
          print('✅ DEBUG: Added passenger ${i + 1} to group ride');
        }
      }

      // Create manual route with enhanced metadata
      final routeId = _isGroupRide
          ? 'MANUAL_GROUP_$baseTimestamp'
          : 'MANUAL_$baseTimestamp';

      final rideDescription = _isGroupRide
          ? 'Enhanced manual group ride created for ${individualRides.length} passengers on ${DateFormat('MMM dd, yyyy \'at\' hh:mm a').format(scheduledTime)}'
          : 'Enhanced manual ride created for ${individualRides.first.passenger.fullName} on ${DateFormat('MMM dd, yyyy \'at\' hh:mm a').format(scheduledTime)}';

      final manualRoute = RouteModel(
        id: routeId,
        driverId: widget.driver.id,
        type: RouteType.morning, // Default type - could be made configurable
        status: RouteStatus.scheduled,
        scheduledTime: scheduledTime,
        officeAddress: 'Office Location', // Default office address
        officeLatitude: 0.0, // Will be updated during navigation
        officeLongitude: 0.0, // Will be updated during navigation
        rides: individualRides,
        notes: rideDescription,
        createdAt: DateTime.now(),
      );

      // Final validation before dispatch
      if (manualRoute.rides.isEmpty) {
        throw Exception('No rides were created - validation error');
      }

      if (manualRoute.id.isEmpty || manualRoute.driverId.isEmpty) {
        throw Exception('Route metadata is invalid');
      }

      // Dispatch to RouteBloc with comprehensive logging
      print('🚀 DEBUG: About to dispatch CreateManualRoute event');
      print('🆔 DEBUG: Route ID: ${manualRoute.id}');
      print('👨‍✈️ DEBUG: Driver ID: ${manualRoute.driverId}');
      print('🎯 DEBUG: Route Type: ${manualRoute.type}');
      print('⏰ DEBUG: Scheduled Time: ${manualRoute.scheduledTime}');
      print('🚗 DEBUG: Number of rides: ${manualRoute.rides.length}');

      for (int i = 0; i < manualRoute.rides.length; i++) {
        final ride = manualRoute.rides[i];
        print(
          '🎯 DEBUG: Ride ${i + 1}: ${ride.passenger.fullName} (${ride.passenger.phoneNumber})',
        );
        print('📍 DEBUG: From: ${ride.pickupAddress}');
        print('🏁 DEBUG: To: ${ride.dropOffAddress}');
      }

      context.read<RouteBloc>().add(CreateManualRoute(manualRoute));
      print('✅ DEBUG: CreateManualRoute event dispatched successfully');
    } catch (e, stackTrace) {
      print('💥 DEBUG: Critical error in _submitForm: $e');
      print('📋 DEBUG: Stack trace: $stackTrace');

      // Provide user-friendly error message based on error type
      String userMessage = 'Failed to create ride. Please try again.';
      if (e.toString().contains('validation')) {
        userMessage = 'Please check your input and try again.';
      } else if (e.toString().contains('network') ||
          e.toString().contains('connection')) {
        userMessage =
            'Network error. Please check your connection and try again.';
      } else if (e.toString().contains('passenger')) {
        userMessage =
            'Error with passenger information. Please review and try again.';
      }

      _showValidationError(userMessage);
    }
  }

  void _showNavigationDialog(BuildContext context, RouteModel route) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Ride Created Successfully!',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ride Type Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: route.rides.length > 1
                        ? Colors.blue.shade100
                        : Colors.green.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: route.rides.length > 1
                          ? Colors.blue.shade300
                          : Colors.green.shade300,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        route.rides.length > 1 ? Icons.group : Icons.person,
                        size: 16,
                        color: route.rides.length > 1
                            ? Colors.blue.shade700
                            : Colors.green.shade700,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        route.rides.length > 1
                            ? 'Group Ride'
                            : 'Individual Ride',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: route.rides.length > 1
                              ? Colors.blue.shade700
                              : Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Ride Details
                _buildDetailRow('Route ID', route.id),
                _buildDetailRow('Passengers', '${route.rides.length}'),
                _buildDetailRow(
                  'Status',
                  route.status.toString().split('.').last.toUpperCase(),
                ),
                _buildDetailRow(
                  'Scheduled Time',
                  DateFormat(
                    'MMM dd, yyyy - hh:mm a',
                  ).format(route.scheduledTime),
                ),

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),

                // Passenger Information
                Text(
                  'Passenger Details:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 8),

                ...route.rides.asMap().entries.map((entry) {
                  final index = entry.key;
                  final ride = entry.value;
                  final isGroupRide = route.rides.length > 1;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isGroupRide) ...[
                          Text(
                            'Passenger ${index + 1}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                        Text(
                          ride.passenger.fullName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          ride.passenger.phoneNumber,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 14,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                ride.pickupAddress,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.flag, size: 14, color: Colors.red),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                ride.dropOffAddress,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),

                // Navigation prompt
                Text(
                  'Would you like to navigate to the first pickup location?',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Close the add manual ride screen
              },
              child: const Text('Later'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();

                // Get the pickup address from the first ride
                if (route.rides.isNotEmpty) {
                  final pickupAddress = route.rides.first.pickupAddress;

                  // Trigger navigation to pickup
                  context.read<RouteBloc>().add(
                    NavigateToPickup(pickupAddress: pickupAddress),
                  );
                }
              },
              icon: const Icon(Icons.navigation, size: 18),
              label: const Text('Navigate Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showValidationError(String message) {
    print('DEBUG: Validation error: $message');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  String _getValidationSummary() {
    List<String> issues = [];

    if (!_isGroupRide) {
      if (_nameController.text.trim().isEmpty) issues.add('Name');
      if (_phoneController.text.trim().isEmpty) issues.add('Phone');
    }

    if (_pickupStreetController.text.trim().isEmpty) {
      issues.add('Pickup street');
    }
    if (_pickupCityController.text.trim().isEmpty) issues.add('Pickup city');
    if (_dropStreetController.text.trim().isEmpty) {
      issues.add('Drop-off street');
    }
    if (_dropCityController.text.trim().isEmpty) issues.add('Drop-off city');
    if (_selectedDate == null) issues.add('Date');
    if (_selectedTime == null) issues.add('Time');

    return issues.isEmpty
        ? 'All fields valid'
        : 'Missing: ${issues.join(', ')}';
  }

  // Helper method to build address section with separate fields
  Widget _buildAddressSection({
    required TextEditingController streetController,
    required TextEditingController aptController,
    required TextEditingController cityController,
    required TextEditingController stateController,
    required TextEditingController zipController,
    required List<String> suggestions,
    required Function(String) onStreetChanged,
  }) {
    return Column(
      children: [
        // Street Address with suggestions
        Column(
          children: [
            CustomTextField(
              controller: streetController,
              label: 'Street Address',
              hintText: 'Enter street address',
              prefixIcon: Icons.location_on,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Street address is required';
                }
                return null;
              },
              onChanged: onStreetChanged,
            ),
            if (suggestions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: suggestions.length > 5 ? 5 : suggestions.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.location_on, size: 16),
                      title: Text(
                        suggestions[index],
                        style: const TextStyle(fontSize: 14),
                      ),
                      onTap: () => _selectAddressFromSuggestion(
                        suggestions[index],
                        streetController,
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),

        // Apartment/Block
        CustomTextField(
          controller: aptController,
          label: 'Apt/Block (Optional)',
          hintText: 'Apartment, suite, unit, building',
          prefixIcon: Icons.home,
        ),
        const SizedBox(height: 16),

        // City, State, Zip in a row
        Row(
          children: [
            Expanded(
              flex: 2,
              child: CustomTextField(
                controller: cityController,
                label: 'City',
                hintText: 'City',
                prefixIcon: Icons.location_city,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'City is required';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomTextField(
                controller: stateController,
                label: 'State',
                hintText: 'State',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'State is required';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomTextField(
                controller: zipController,
                label: 'Zip Code',
                hintText: 'Zip',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Zip code is required';
                  }
                  if (value.trim().length < 5) {
                    return 'Invalid zip code';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Address suggestion methods with debounce
  void _onPickupStreetChanged(String value) {
    // Cancel previous timer
    _pickupDebounceTimer?.cancel();

    if (value.length > 2) {
      // Start new timer with 500ms delay
      _pickupDebounceTimer = Timer(const Duration(milliseconds: 500), () {
        _getAddressSuggestions(value, isPickup: true);
      });
    } else {
      setState(() {
        _pickupSuggestions.clear();
      });
    }
  }

  void _onDropStreetChanged(String value) {
    // Cancel previous timer
    _dropDebounceTimer?.cancel();

    if (value.length > 2) {
      // Start new timer with 500ms delay
      _dropDebounceTimer = Timer(const Duration(milliseconds: 500), () {
        _getAddressSuggestions(value, isPickup: false);
      });
    } else {
      setState(() {
        _dropSuggestions.clear();
      });
    }
  }

  Future<void> _getAddressSuggestions(
    String query, {
    required bool isPickup,
  }) async {
    if (query.length < 3) {
      setState(() {
        if (isPickup) {
          _pickupSuggestions.clear();
        } else {
          _dropSuggestions.clear();
        }
      });
      return;
    }

    try {
      // Use real geocoding for address suggestions
      List<String> suggestions = await _getRealAddressSuggestions(query);

      // Only update state if the query is still relevant
      if (mounted) {
        setState(() {
          if (isPickup) {
            _pickupSuggestions = suggestions;
          } else {
            _dropSuggestions = suggestions;
          }
        });
      }
    } catch (e) {
      print('Error getting address suggestions: $e');
      // Fallback to basic suggestions on error
      setState(() {
        if (isPickup) {
          _pickupSuggestions = _generateBasicSuggestions(query);
        } else {
          _dropSuggestions = _generateBasicSuggestions(query);
        }
      });
    }
  }

  Future<List<String>> _getRealAddressSuggestions(String query) async {
    List<String> suggestions = [];

    try {
      // Use geocoding to get real address suggestions
      List<Location> locations = await locationFromAddress(query);

      // Get place names for each location
      for (Location location in locations.take(5)) {
        try {
          List<Placemark> placemarks = await placemarkFromCoordinates(
            location.latitude,
            location.longitude,
          );

          if (placemarks.isNotEmpty) {
            final placemark = placemarks.first;
            String fullAddress = _formatPlacemarkAddress(placemark);
            if (fullAddress.isNotEmpty && !suggestions.contains(fullAddress)) {
              suggestions.add(fullAddress);
            }
          }
        } catch (e) {
          // Continue with next location if one fails
          continue;
        }
      }

      // If no results from geocoding, try a different approach
      if (suggestions.isEmpty) {
        suggestions = await _getPlaceSearchSuggestions(query);
      }
    } catch (e) {
      print('Geocoding failed: $e');
      // Return empty list to fallback to basic suggestions
    }

    return suggestions.take(5).toList();
  }

  Future<List<String>> _getPlaceSearchSuggestions(String query) async {
    List<String> suggestions = [];

    try {
      // Try to find places that match the query
      // This is a simplified version - you could integrate with Google Places API here
      List<String> commonPlaces = [
        '$query, New York, NY',
        '$query, Los Angeles, CA',
        '$query, Chicago, IL',
        '$query, Houston, TX',
        '$query, Phoenix, AZ',
      ];

      for (String place in commonPlaces) {
        try {
          List<Location> locations = await locationFromAddress(place);
          if (locations.isNotEmpty) {
            suggestions.add(place);
          }
        } catch (e) {
          // Skip invalid addresses
          continue;
        }
      }
    } catch (e) {
      print('Place search failed: $e');
    }

    return suggestions;
  }

  String _formatPlacemarkAddress(Placemark placemark) {
    List<String> addressParts = [];

    if (placemark.street != null && placemark.street!.isNotEmpty) {
      addressParts.add(placemark.street!);
    }

    if (placemark.locality != null && placemark.locality!.isNotEmpty) {
      addressParts.add(placemark.locality!);
    }

    if (placemark.administrativeArea != null &&
        placemark.administrativeArea!.isNotEmpty) {
      addressParts.add(placemark.administrativeArea!);
    }

    if (placemark.postalCode != null && placemark.postalCode!.isNotEmpty) {
      addressParts.add(placemark.postalCode!);
    }

    return addressParts.join(', ');
  }

  List<String> _generateBasicSuggestions(String query) {
    List<String> suggestions = [];

    // Only show basic suggestions if query looks like an address
    if (query.isNotEmpty && query.length > 3) {
      // Add common street type variations only if they make sense
      if (query.toLowerCase().contains('main')) {
        suggestions.add('Main Street, $query');
      }
      if (query.toLowerCase().contains('first') ||
          query.toLowerCase().contains('1st')) {
        suggestions.add('1st Street, $query');
      }
      if (RegExp(r'\d').hasMatch(query)) {
        // If query contains numbers, it might be an address
        suggestions.add('$query Street');
        suggestions.add('$query Avenue');
      }
    }

    return suggestions.take(3).toList();
  }

  void _selectAddressFromSuggestion(
    String suggestion,
    TextEditingController streetController,
  ) {
    // Parse the suggestion and fill in the appropriate fields
    List<String> parts = suggestion.split(', ');
    if (parts.isNotEmpty) {
      streetController.text = parts[0];

      // Try to parse city, state, zip from the suggestion
      if (parts.length >= 2) {
        // Determine if this is pickup or drop based on the controller
        bool isPickup = streetController == _pickupStreetController;

        if (parts.length >= 4) {
          // Full address: street, city, state, zip
          if (isPickup) {
            _pickupCityController.text = parts[1];
            _pickupStateController.text = parts[2];
            _pickupZipController.text = parts[3];
          } else {
            _dropCityController.text = parts[1];
            _dropStateController.text = parts[2];
            _dropZipController.text = parts[3];
          }
        } else if (parts.length >= 3) {
          // Partial address: street, city, state
          if (isPickup) {
            _pickupCityController.text = parts[1];
            _pickupStateController.text = parts[2];
          } else {
            _dropCityController.text = parts[1];
            _dropStateController.text = parts[2];
          }
        }
      }
    }

    // Clear suggestions after selection
    setState(() {
      if (streetController == _pickupStreetController) {
        _pickupSuggestions.clear();
      } else {
        _dropSuggestions.clear();
      }
    });
  }

  // Helper method to combine address fields into full address string
  String _getFullAddress({
    required String street,
    required String apt,
    required String city,
    required String state,
    required String zip,
  }) {
    List<String> parts = [];
    if (street.trim().isNotEmpty) parts.add(street.trim());
    if (apt.trim().isNotEmpty) parts.add(apt.trim());
    if (city.trim().isNotEmpty) parts.add(city.trim());
    if (state.trim().isNotEmpty) parts.add(state.trim());
    if (zip.trim().isNotEmpty) parts.add(zip.trim());
    return parts.join(', ');
  }
}
