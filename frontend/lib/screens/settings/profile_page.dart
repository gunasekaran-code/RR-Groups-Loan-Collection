import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../theme/app_theme.dart';
import '../../theme/glass_toast.dart';
import '../../widgets/page_header.dart';

class ProfilePage extends StatefulWidget {
  final bool showScaffold;

  const ProfilePage({super.key, this.showScaffold = true});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _nameCtrl = TextEditingController(text: 'Priya Sharma');
  final _mobileCtrl = TextEditingController(text: '9876543211');
  final _occupationCtrl = TextEditingController(text: 'Manager');
  final _aadhaarCtrl = TextEditingController();
  final _panCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _imagePicker = ImagePicker();

  bool _saving = false;
  Uint8List? _avatarImageBytes;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _mobileCtrl.dispose();
    _occupationCtrl.dispose();
    _aadhaarCtrl.dispose();
    _panCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    setState(() => _saving = true);

    // TODO: wire this up to your actual profile update API / repository.
    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;
    setState(() => _saving = false);

    // Smooth custom iOS-style toast replace
    ToastService.show(
      title: 'Success',
      message: 'Profile updated',
      type: ToastType.success,
    );
  }

  Future<void> _onPickAvatar() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final pickedFile = await _imagePicker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1024,
    );
    if (pickedFile == null || !mounted) return;

    final imageBytes = await pickedFile.readAsBytes();
    if (!mounted) return;

    setState(() => _avatarImageBytes = imageBytes);
  }

  @override
  Widget build(BuildContext context) {
    final content = SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PageHeader(
              title: 'My Profile',
              subtitle: 'Manage your account details and security',
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ProfileHeaderCard(
                    name: _nameCtrl.text,
                    email: 'admin@fincollect.in',
                    role: 'ADMINISTRATOR',
                    avatarImageBytes: _avatarImageBytes,
                    onPickAvatar: _onPickAvatar,
                  ),
                  const SizedBox(height: 20),
                  _ProfileDetailsCard(
                    nameCtrl: _nameCtrl,
                    mobileCtrl: _mobileCtrl,
                    occupationCtrl: _occupationCtrl,
                    aadhaarCtrl: _aadhaarCtrl,
                    panCtrl: _panCtrl,
                    addressCtrl: _addressCtrl,
                    saving: _saving,
                    onSave: _onSave,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (!widget.showScaffold) {
      return content;
    }

    return Scaffold(
      backgroundColor: AppColors.kBackground,
      appBar: AppBar(title: const Text('My Profile')),
      body: content,
    );
  }
}

/// Top card: avatar + name + email + role badge + "member since".
class _ProfileHeaderCard extends StatelessWidget {
  final String name;
  final String email;
  final String role;
  final Uint8List? avatarImageBytes;
  final VoidCallback onPickAvatar;

  const _ProfileHeaderCard({
    required this.name,
    required this.email,
    required this.role,
    required this.avatarImageBytes,
    required this.onPickAvatar,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 500;

        final avatar = Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.kGold, width: 2),
              ),
              child: ClipOval(
                child: avatarImageBytes == null
                    ? const ColoredBox(
                        color: AppColors.kBorder,
                        child: Icon(Icons.person,
                            size: 40, color: AppColors.kTextMuted),
                      )
                    : Image.memory(
                        avatarImageBytes!,
                        fit: BoxFit.cover,
                        width: 84,
                        height: 84,
                      ),
              ),
            ),
            Positioned(
              right: -2,
              bottom: -2,
              child: GestureDetector(
                onTap: onPickAvatar,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: AppColors.kGoldDark,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt,
                      size: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        );

        final info = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.kTextDark,
              ),
            ),
            const SizedBox(height: 2),
            Text(email,
                style:
                    const TextStyle(fontSize: 14, color: AppColors.kTextMuted)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.kGoldLight.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified_user,
                          size: 14, color: AppColors.kGoldDark),
                      const SizedBox(width: 6),
                      Text(
                        role,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.kGoldDark,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        );

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.kSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.kBorder),
          ),
          child: isNarrow
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    avatar,
                    const SizedBox(height: 16),
                    Center(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(name,
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.kTextDark)),
                          const SizedBox(height: 2),
                          Text(email,
                              style: const TextStyle(
                                  fontSize: 14, color: AppColors.kTextMuted)),
                          const SizedBox(height: 10),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 10,
                            runSpacing: 8,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.kGoldLight
                                      .withValues(alpha: 0.35),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.verified_user,
                                        size: 14, color: AppColors.kGoldDark),
                                    const SizedBox(width: 6),
                                    Text(role,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.kGoldDark,
                                            letterSpacing: 0.5)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    avatar,
                    const SizedBox(width: 20),
                    Expanded(child: info),
                  ],
                ),
        );
      },
    );
  }
}

/// Details form card — responsive 2-column grid (1 column on narrow screens),
/// with Address added as a full-width multiline field.
class _ProfileDetailsCard extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController mobileCtrl;
  final TextEditingController occupationCtrl;
  final TextEditingController aadhaarCtrl;
  final TextEditingController panCtrl;
  final TextEditingController addressCtrl;
  final bool saving;
  final VoidCallback onSave;

  const _ProfileDetailsCard({
    required this.nameCtrl,
    required this.mobileCtrl,
    required this.occupationCtrl,
    required this.aadhaarCtrl,
    required this.panCtrl,
    required this.addressCtrl,
    required this.saving,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.kBorder),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 560;
          final fieldWidth =
              isNarrow ? constraints.maxWidth : (constraints.maxWidth - 20) / 2;

          Widget field({
            required String label,
            required IconData icon,
            required TextEditingController controller,
            String? hint,
            TextInputType? keyboardType,
            int maxLines = 1,
            bool fullWidth = false,
          }) {
            return SizedBox(
              width: fullWidth ? constraints.maxWidth : fieldWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.kTextMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: controller,
                    keyboardType: keyboardType,
                    maxLines: maxLines,
                    decoration: InputDecoration(
                      prefixIcon: maxLines > 1
                          ? Padding(
                              padding: const EdgeInsets.only(bottom: 40),
                              child: Icon(icon,
                                  size: 20, color: AppColors.kTextMuted),
                            )
                          : Icon(icon, size: 20, color: AppColors.kTextMuted),
                      hintText: hint,
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.kGoldLight.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.person_outline,
                        size: 18, color: AppColors.kGoldDark),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Profile Details',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.kTextDark),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 20,
                runSpacing: 20,
                children: [
                  field(
                    label: 'FULL NAME',
                    icon: Icons.person_outline,
                    controller: nameCtrl,
                  ),
                  field(
                    label: 'MOBILE NUMBER',
                    icon: Icons.phone_outlined,
                    controller: mobileCtrl,
                    keyboardType: TextInputType.phone,
                  ),
                  field(
                    label: 'OCCUPATION',
                    icon: Icons.work_outline,
                    controller: occupationCtrl,
                  ),
                  field(
                    label: 'AADHAAR',
                    icon: Icons.fingerprint,
                    controller: aadhaarCtrl,
                    hint: 'Aadhaar number',
                    keyboardType: TextInputType.number,
                  ),
                  field(
                    label: 'PAN',
                    icon: Icons.credit_card_outlined,
                    controller: panCtrl,
                    hint: 'PAN number',
                  ),
                  // New: Address — full width, multiline.
                  field(
                    label: 'ADDRESS',
                    icon: Icons.location_on_outlined,
                    controller: addressCtrl,
                    hint: 'House no, street, city, state, PIN code',
                    maxLines: 3,
                    fullWidth: true,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  width: isNarrow ? double.infinity : null,
                  child: ElevatedButton.icon(
                    onPressed: saving ? null : onSave,
                    icon: saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.save_outlined, size: 18),
                    label: Text(saving ? 'Saving...' : 'Save Changes'),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
