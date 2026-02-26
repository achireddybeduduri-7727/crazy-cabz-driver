import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../bloc/auth_bloc.dart';

class CompanyIdScreen extends StatefulWidget {
  final String driverId;

  const CompanyIdScreen({super.key, required this.driverId});

  @override
  State<CompanyIdScreen> createState() => _CompanyIdScreenState();
}

class _CompanyIdScreenState extends State<CompanyIdScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyIdController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _companyIdController.dispose();
    super.dispose();
  }

  void _verifyCompanyId() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
        AuthCompanyIdVerificationRequested(
          companyId: _companyIdController.text.trim(),
          driverId: widget.driverId,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Company Verification'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          setState(() {
            _isLoading = state is AuthLoading;
          });

          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppTheme.errorColor,
              ),
            );
          } else if (state is AuthAuthenticated) {
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/dashboard', (route) => false);
          } else if (state is AuthSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppTheme.successColor,
              ),
            );
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/dashboard', (route) => false);
          }
        },
        builder: (context, state) {
          return LoadingOverlay(
            isLoading: _isLoading,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 40),

                      // Header Icon
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: AppTheme.accentColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.business,
                          size: 50,
                          color: AppTheme.accentColor,
                        ),
                      ),

                      const SizedBox(height: 24),

                      Text(
                        'Company Verification',
                        style: AppTextStyles.heading2,
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'Please enter the unique company ID provided by your employer to complete your registration.',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppTheme.greyColor,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 40),

                      // Company ID Field
                      CustomTextField(
                        controller: _companyIdController,
                        label: AppStrings.companyId,
                        hintText: AppStrings.enterCompanyId,
                        prefixIcon: Icons.badge_outlined,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your company ID';
                          }
                          if (value.length < 3) {
                            return 'Company ID must be at least 3 characters';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 32),

                      // Verify Button
                      CustomButton(
                        text: 'Verify Company ID',
                        onPressed: _verifyCompanyId,
                        isLoading: _isLoading,
                      ),

                      const Spacer(),

                      // Help Section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.warningColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                            AppConstants.borderRadius,
                          ),
                          border: Border.all(
                            color: AppTheme.warningColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.help_outline,
                                  color: AppTheme.warningColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Need Help?',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.warningColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '• Company ID is provided by your employer\n'
                              '• Contact your HR department if you don\'t have it\n'
                              '• Make sure to enter the exact ID without spaces',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppTheme.warningColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
