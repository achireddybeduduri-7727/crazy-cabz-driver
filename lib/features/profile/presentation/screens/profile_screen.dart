import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../../../../shared/widgets/profile_image_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/models/driver_model.dart';
import '../bloc/profile_bloc.dart';

class ProfileScreen extends StatefulWidget {
  final DriverModel? initialDriver;

  const ProfileScreen({super.key, this.initialDriver});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // Personal Info Controllers
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ageController = TextEditingController();

  // Vehicle Info Controllers
  final _vehicleModelController = TextEditingController();
  final _vehicleColorController = TextEditingController();
  final _plateNumberController = TextEditingController();
  final _vehicleYearController = TextEditingController();
  final _vehicleMakeController = TextEditingController();

  // Insurance Info Controllers
  final _insuranceProviderController = TextEditingController();
  final _policyNumberController = TextEditingController();
  final _expiryDateController = TextEditingController();

  DateTime? _selectedExpiryDate;
  String? _localImagePath;
  String? _localDocumentPath;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() {
    if (widget.initialDriver != null) {
      final driver = widget.initialDriver!;

      // Personal Info
      _fullNameController.text = driver.fullName;
      _emailController.text = driver.email;
      _phoneController.text = driver.phoneNumber;
      _ageController.text = driver.age.toString();

      // Vehicle Info
      _vehicleModelController.text = driver.vehicleInfo.model;
      _vehicleColorController.text = driver.vehicleInfo.color;
      _plateNumberController.text = driver.vehicleInfo.plateNumber;
      _vehicleYearController.text = driver.vehicleInfo.year ?? '';
      _vehicleMakeController.text = driver.vehicleInfo.make ?? '';

      // Insurance Info
      _insuranceProviderController.text = driver.insuranceInfo.provider;
      _policyNumberController.text = driver.insuranceInfo.policyNumber;
      _selectedExpiryDate = driver.insuranceInfo.expiryDate;
      _expiryDateController.text = _formatDate(_selectedExpiryDate!);
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    _vehicleModelController.dispose();
    _vehicleColorController.dispose();
    _plateNumberController.dispose();
    _vehicleYearController.dispose();
    _vehicleMakeController.dispose();
    _insuranceProviderController.dispose();
    _policyNumberController.dispose();
    _expiryDateController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showImagePicker() {
    ImagePickerBottomSheet.show(
      context,
      onCameraPressed: () {
        context.read<ProfileBloc>().add(
          const ProfileImagePickRequested(source: ImagePickerSource.camera),
        );
      },
      onGalleryPressed: () {
        context.read<ProfileBloc>().add(
          const ProfileImagePickRequested(source: ImagePickerSource.gallery),
        );
      },
    );
  }

  void _selectExpiryDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate:
          _selectedExpiryDate ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );

    if (date != null) {
      setState(() {
        _selectedExpiryDate = date;
        _expiryDateController.text = _formatDate(date);
      });
    }
  }

  void _uploadInsuranceDocument() {
    context.read<ProfileBloc>().add(ProfileDocumentPickRequested());
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      if (_selectedExpiryDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select insurance expiry date'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        return;
      }

      final vehicleInfo = VehicleInfo(
        model: _vehicleModelController.text.trim(),
        color: _vehicleColorController.text.trim(),
        plateNumber: _plateNumberController.text.trim(),
        year: _vehicleYearController.text.trim().isEmpty
            ? null
            : _vehicleYearController.text.trim(),
        make: _vehicleMakeController.text.trim().isEmpty
            ? null
            : _vehicleMakeController.text.trim(),
      );

      final insuranceInfo = InsuranceInfo(
        provider: _insuranceProviderController.text.trim(),
        policyNumber: _policyNumberController.text.trim(),
        expiryDate: _selectedExpiryDate!,
        documentUrl: widget.initialDriver?.insuranceInfo.documentUrl,
      );

      final updatedDriver =
          (widget.initialDriver ??
                  DriverModel(
                    id: '',
                    fullName: '',
                    email: '',
                    phoneNumber: '',
                    age: 0,
                    vehicleInfo: vehicleInfo,
                    insuranceInfo: insuranceInfo,
                    companyId: '',
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  ))
              .copyWith(
                fullName: _fullNameController.text.trim(),
                email: _emailController.text.trim(),
                phoneNumber: _phoneController.text.trim(),
                age: int.tryParse(_ageController.text) ?? 0,
                vehicleInfo: vehicleInfo,
                insuranceInfo: insuranceInfo,
              );

      context.read<ProfileBloc>().add(
        ProfileUpdateRequested(
          driverId: updatedDriver.id,
          driver: updatedDriver,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.profile),
        actions: [
          TextButton(
            onPressed: _saveProfile,
            child: Text(
              AppStrings.save,
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          setState(() {
            _isLoading = state is ProfileLoading;
          });

          if (state is ProfileError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppTheme.errorColor,
              ),
            );
          } else if (state is ProfileUpdateSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppTheme.successColor,
              ),
            );
            Navigator.of(context).pop(state.driver);
          } else if (state is ProfileImagePicked) {
            setState(() {
              _localImagePath = state.imagePath;
            });
            // Upload the image
            context.read<ProfileBloc>().add(
              ProfileImageUploadRequested(
                driverId: widget.initialDriver?.id ?? '',
                imagePath: state.imagePath,
              ),
            );
          } else if (state is ProfileDocumentPicked) {
            setState(() {
              _localDocumentPath = state.documentPath;
            });
            // Upload the document
            context.read<ProfileBloc>().add(
              ProfileInsuranceDocumentUploadRequested(
                driverId: widget.initialDriver?.id ?? '',
                documentPath: state.documentPath,
              ),
            );
          } else if (state is ProfileImageUploadSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppTheme.successColor,
              ),
            );
          }
        },
        builder: (context, state) {
          return LoadingOverlay(
            isLoading: _isLoading,
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Profile Image Section
                    Center(
                      child: ProfileImagePicker(
                        imageUrl: widget.initialDriver?.profilePhotoUrl,
                        localImagePath: _localImagePath,
                        onTap: _showImagePicker,
                        size: 120,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Personal Information Section
                    _buildSectionHeader('Personal Information'),
                    const SizedBox(height: 16),

                    CustomTextField(
                      controller: _fullNameController,
                      label: AppStrings.fullName,
                      hintText: 'Enter your full name',
                      prefixIcon: Icons.person_outline,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your full name';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    CustomTextField(
                      controller: _emailController,
                      label: AppStrings.email,
                      hintText: 'Enter your email',
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: Icons.email_outlined,
                      enabled: false, // Email should not be editable
                    ),

                    const SizedBox(height: 16),

                    CustomTextField(
                      controller: _phoneController,
                      label: AppStrings.phoneNumber,
                      hintText: 'Enter your phone number',
                      keyboardType: TextInputType.phone,
                      prefixIcon: Icons.phone_outlined,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your phone number';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    CustomTextField(
                      controller: _ageController,
                      label: AppStrings.age,
                      hintText: 'Enter your age',
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.cake_outlined,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your age';
                        }
                        final age = int.tryParse(value);
                        if (age == null || age < 18 || age > 100) {
                          return 'Please enter a valid age (18-100)';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 32),

                    // Vehicle Information Section
                    _buildSectionHeader('Vehicle Information'),
                    const SizedBox(height: 16),

                    CustomTextField(
                      controller: _vehicleModelController,
                      label: AppStrings.vehicleModel,
                      hintText: 'e.g., Toyota Camry',
                      prefixIcon: Icons.directions_car_outlined,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter vehicle model';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: _vehicleMakeController,
                            label: 'Make',
                            hintText: 'e.g., Toyota',
                            prefixIcon: Icons.build_outlined,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: CustomTextField(
                            controller: _vehicleYearController,
                            label: 'Year',
                            hintText: 'e.g., 2020',
                            keyboardType: TextInputType.number,
                            prefixIcon: Icons.calendar_today_outlined,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    CustomTextField(
                      controller: _vehicleColorController,
                      label: AppStrings.vehicleColor,
                      hintText: 'e.g., White',
                      prefixIcon: Icons.palette_outlined,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter vehicle color';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    CustomTextField(
                      controller: _plateNumberController,
                      label: AppStrings.plateNumber,
                      hintText: 'e.g., ABC-1234',
                      prefixIcon: Icons.confirmation_number_outlined,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter plate number';
                        }
                        if (value.length > AppConstants.maxPlateNumberLength) {
                          return 'Plate number is too long';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 32),

                    // Insurance Information Section
                    _buildSectionHeader('Insurance Information'),
                    const SizedBox(height: 16),

                    CustomTextField(
                      controller: _insuranceProviderController,
                      label: 'Insurance Provider',
                      hintText: 'e.g., State Farm',
                      prefixIcon: Icons.shield_outlined,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter insurance provider';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    CustomTextField(
                      controller: _policyNumberController,
                      label: 'Policy Number',
                      hintText: 'Enter policy number',
                      prefixIcon: Icons.assignment_outlined,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter policy number';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    GestureDetector(
                      onTap: _selectExpiryDate,
                      child: AbsorbPointer(
                        child: CustomTextField(
                          controller: _expiryDateController,
                          label: 'Expiry Date',
                          hintText: 'Select expiry date',
                          prefixIcon: Icons.date_range_outlined,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select expiry date';
                            }
                            return null;
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Insurance Document Upload
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.lightGreyColor),
                        borderRadius: BorderRadius.circular(
                          AppConstants.borderRadius,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Insurance Document',
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_localDocumentPath != null ||
                              widget.initialDriver?.insuranceInfo.documentUrl !=
                                  null)
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.successColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    color: AppTheme.successColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Document uploaded successfully',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppTheme.successColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            TextButton.icon(
                              onPressed: _uploadInsuranceDocument,
                              icon: const Icon(Icons.upload_file),
                              label: const Text('Upload Insurance Document'),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Save Button
                    CustomButton(
                      text: AppStrings.save,
                      onPressed: _saveProfile,
                      isLoading: _isLoading,
                    ),

                    const SizedBox(height: 20),
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
      style: AppTextStyles.heading3.copyWith(color: AppTheme.primaryColor),
    );
  }
}
