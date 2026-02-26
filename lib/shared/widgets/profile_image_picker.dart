import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';

class ProfileImagePicker extends StatelessWidget {
  final String? imageUrl;
  final String? localImagePath;
  final VoidCallback? onTap;
  final double size;
  final bool isEditable;

  const ProfileImagePicker({
    super.key,
    this.imageUrl,
    this.localImagePath,
    this.onTap,
    this.size = 120,
    this.isEditable = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isEditable ? onTap : null,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.primaryColor, width: 3),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipOval(
          child: Stack(
            children: [
              // Image display
              Container(
                width: size,
                height: size,
                color: AppTheme.lightGreyColor,
                child: _buildImage(),
              ),

              // Edit overlay
              if (isEditable)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    // Priority: local image > network image > placeholder
    if (localImagePath != null && localImagePath!.isNotEmpty) {
      return Image.file(
        File(localImagePath!),
        fit: BoxFit.cover,
        width: size,
        height: size,
      );
    } else if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imageUrl!,
        fit: BoxFit.cover,
        width: size,
        height: size,
        placeholder: (context, url) => _buildPlaceholder(),
        errorWidget: (context, url, error) => _buildPlaceholder(),
      );
    } else {
      return _buildPlaceholder();
    }
  }

  Widget _buildPlaceholder() {
    return Container(
      width: size,
      height: size,
      color: AppTheme.lightGreyColor,
      child: Icon(Icons.person, size: size * 0.5, color: AppTheme.greyColor),
    );
  }
}

class ImagePickerBottomSheet extends StatelessWidget {
  final VoidCallback onCameraPressed;
  final VoidCallback onGalleryPressed;

  const ImagePickerBottomSheet({
    super.key,
    required this.onCameraPressed,
    required this.onGalleryPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.greyColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(height: 20),

          Text(
            'Select Profile Photo',
            style: AppTextStyles.heading3,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 20),

          // Camera option
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.camera_alt, color: AppTheme.primaryColor),
            ),
            title: const Text('Camera'),
            subtitle: const Text('Take a new photo'),
            onTap: () {
              Navigator.of(context).pop();
              onCameraPressed();
            },
          ),

          // Gallery option
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.photo_library,
                color: AppTheme.accentColor,
              ),
            ),
            title: const Text('Gallery'),
            subtitle: const Text('Choose from gallery'),
            onTap: () {
              Navigator.of(context).pop();
              onGalleryPressed();
            },
          ),

          const SizedBox(height: 10),
        ],
      ),
    );
  }

  static void show(
    BuildContext context, {
    required VoidCallback onCameraPressed,
    required VoidCallback onGalleryPressed,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ImagePickerBottomSheet(
        onCameraPressed: onCameraPressed,
        onGalleryPressed: onGalleryPressed,
      ),
    );
  }
}
