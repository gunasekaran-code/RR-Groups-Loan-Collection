import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_theme.dart';
import '../../theme/glass_toast.dart';

class AppUpload {
  static final ImagePicker _picker = ImagePicker();

  /// Opens the modal sheet and returns the selected [XFile] (or null if canceled).
  static Future<XFile?> showImagePickerModal(
    BuildContext context, {
    String title = 'Update Profile Picture',
  }) async {
    final XFile? selectedFile = await showModalBottomSheet<XFile?>(
      context: context,
      backgroundColor: AppColors.kSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.kBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.kTextDark,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.kGold,
                    child: Icon(Icons.camera_alt_outlined, color: AppColors.kGold),
                  ),
                  title: const Text(
                    'Open Camera',
                    style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.kTextDark),
                  ),
                  onTap: () async {
                    try {
                      final XFile? image = await _picker.pickImage(
                        source: ImageSource.camera,
                        imageQuality: 85,
                      );
                      if (context.mounted) {
                        Navigator.pop(context, image);
                      }
                    } catch (e) {
                      if (context.mounted) Navigator.pop(context);
                      ToastService.show(
                        title: 'Camera Error',
                        message: 'Could not access the camera.',
                        type: ToastType.error,
                      );
                    }
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.kGold,
                    child: Icon(Icons.photo_library_outlined, color: AppColors.kGold),
                  ),
                  title: const Text(
                    'Upload Image',
                    style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.kTextDark),
                  ),
                  onTap: () async {
                    try {
                      final XFile? image = await _picker.pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 85,
                      );
                      if (context.mounted) {
                        Navigator.pop(context, image);
                      }
                    } catch (e) {
                      if (context.mounted) Navigator.pop(context);
                      ToastService.show(
                        title: 'Gallery Error',
                        message: 'Could not access the gallery.',
                        type: ToastType.error,
                      );
                    }
                  },
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.kTextMuted,
                      side: const BorderSide(color: AppColors.kBorder),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => Navigator.pop(context, null),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selectedFile != null) {
      ToastService.show(
        title: 'Image Selected',
        message: 'Profile picture updated successfully.',
        type: ToastType.success,
      );
    }

    return selectedFile;
  }
}