import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../shared/widgets/profile_image_picker.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/models/driver_model.dart';
import '../bloc/profile_bloc.dart';
import 'profile_screen.dart';
import '../../../../shared/widgets/persistent_navigation_wrapper.dart';

class ProfileViewScreen extends StatefulWidget {
  final DriverModel driver;

  const ProfileViewScreen({super.key, required this.driver});

  @override
  State<ProfileViewScreen> createState() => _ProfileViewScreenState();
}

class _ProfileViewScreenState extends State<ProfileViewScreen> {
  late DriverModel _currentDriver;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentDriver = widget.driver;
  }

  void _editProfile() async {
    final updatedDriver = await Navigator.of(context).push<DriverModel>(
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: context.read<ProfileBloc>(),
          child: ProfileScreen(initialDriver: _currentDriver),
        ),
      ),
    );

    if (updatedDriver != null) {
      setState(() {
        _currentDriver = updatedDriver;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.profile),
        actions: [
          IconButton(icon: const Icon(Icons.edit), onPressed: _editProfile),
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
          }
        },
        builder: (context, state) {
          return LoadingOverlay(
            isLoading: _isLoading,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(
                left: AppConstants.defaultPadding,
                right: AppConstants.defaultPadding,
                top: AppConstants.defaultPadding,
                bottom: 100, // Extra padding to ensure content is not hidden by bottom nav
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Profile Header
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor,
                          AppTheme.primaryColor.withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        ProfileImagePicker(
                          imageUrl: _currentDriver.profilePhotoUrl,
                          size: 100,
                          isEditable: false,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _currentDriver.fullName,
                          style: AppTextStyles.heading2.copyWith(
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _currentDriver.email,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.white.withOpacity(0.8),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _currentDriver.isActive
                                ? 'Active Driver'
                                : 'Inactive',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Personal Information Card
                  _buildInfoCard(
                    title: 'Personal Information',
                    icon: Icons.person_outline,
                    children: [
                      _buildInfoRow(
                        'Phone',
                        _currentDriver.phoneNumber,
                        Icons.phone_outlined,
                      ),
                      _buildInfoRow(
                        'Age',
                        '${_currentDriver.age} years',
                        Icons.cake_outlined,
                      ),
                      _buildInfoRow(
                        'Company ID',
                        _currentDriver.companyId,
                        Icons.business_outlined,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Vehicle Information Card
                  _buildInfoCard(
                    title: 'Vehicle Information',
                    icon: Icons.directions_car_outlined,
                    children: [
                      _buildInfoRow(
                        'Model',
                        _currentDriver.vehicleInfo.model,
                        Icons.directions_car,
                      ),
                      if (_currentDriver.vehicleInfo.make != null)
                        _buildInfoRow(
                          'Make',
                          _currentDriver.vehicleInfo.make!,
                          Icons.build_outlined,
                        ),
                      if (_currentDriver.vehicleInfo.year != null)
                        _buildInfoRow(
                          'Year',
                          _currentDriver.vehicleInfo.year!,
                          Icons.calendar_today_outlined,
                        ),
                      _buildInfoRow(
                        'Color',
                        _currentDriver.vehicleInfo.color,
                        Icons.palette_outlined,
                      ),
                      _buildInfoRow(
                        'Plate Number',
                        _currentDriver.vehicleInfo.plateNumber,
                        Icons.confirmation_number_outlined,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Insurance Information Card
                  _buildInfoCard(
                    title: 'Insurance Information',
                    icon: Icons.shield_outlined,
                    children: [
                      _buildInfoRow(
                        'Provider',
                        _currentDriver.insuranceInfo.provider,
                        Icons.business,
                      ),
                      _buildInfoRow(
                        'Policy Number',
                        _currentDriver.insuranceInfo.policyNumber,
                        Icons.assignment_outlined,
                      ),
                      _buildInfoRow(
                        'Expiry Date',
                        _formatDate(_currentDriver.insuranceInfo.expiryDate),
                        Icons.date_range_outlined,
                      ),
                      if (_currentDriver.insuranceInfo.documentUrl != null)
                        _buildInfoRow(
                          'Document',
                          'Uploaded',
                          Icons.check_circle,
                          color: AppTheme.successColor,
                        ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Quick Actions
                  _buildQuickActions(),

                  const SizedBox(height: 24),

                  // Account Information
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.lightGreyColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Account Information',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.greyColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Created: ${_formatDate(_currentDriver.createdAt)}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppTheme.greyColor,
                          ),
                        ),
                        Text(
                          'Last Updated: ${_formatDate(_currentDriver.updatedAt)}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppTheme.greyColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppTheme.primaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(title, style: AppTextStyles.heading3),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: AppTextStyles.heading3.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.car_rental,
                    label: 'Rides',
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PersistentNavigationWrapper(
                            driver: _currentDriver,
                            initialIndex: 0,
                          ),
                        ),
                      );
                    },
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.dashboard,
                    label: 'Dashboard',
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/dashboard',
                        arguments: _currentDriver,
                      );
                    },
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.history,
                    label: 'Activities',
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PersistentNavigationWrapper(
                            driver: _currentDriver,
                            initialIndex: 2,
                          ),
                        ),
                      );
                    },
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.support_agent,
                    label: 'Support',
                    onTap: () {
                      // TODO: Navigate to support
                    },
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2), width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color ?? AppTheme.greyColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppTheme.greyColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: color ?? AppTheme.onSurfaceColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
