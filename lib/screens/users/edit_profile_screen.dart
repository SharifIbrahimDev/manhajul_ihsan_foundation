import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/utils/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/app_models.dart';
import '../../providers/chat_provider.dart';
import '../../core/widgets/toast_notification.dart';
import '../auth/change_password_screen.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  
  bool _isLoading = false;
  File? _imageFile;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.appUser;
    
    if (user != null) {
      _fullNameController.text = user.fullName;
      _phoneController.text = user.phone;
      _addressController.text = user.address;
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }



  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 500,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ToastNotification.showError(context, 'Error picking image: $e');
      }
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(24.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Profile Photo',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 24.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPickerOption(
                  icon: Icons.camera_alt_rounded,
                  label: 'Camera',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                _buildPickerOption(
                  icon: Icons.photo_library_rounded,
                  label: 'Gallery',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTheme.primaryColor, size: 32.r),
          ),
          SizedBox(height: 8.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final userProvider = context.read<UserProvider>();
      final currentUser = authProvider.appUser;

      if (currentUser == null) {
        throw Exception('User not found');
      }

      String? photoUrl = currentUser.photoUrl;

      // Upload new image if selected
      if (_imageFile != null && mounted) {
        // Use ChatProvider which already has uploadFile logic
        final uploadUrl = await context.read<ChatProvider>().uploadFile(_imageFile!, 'profiles');
        if (uploadUrl != null) {
          photoUrl = uploadUrl;
        }
      }

      // Create updated user
      final updatedUser = currentUser.copyWith(
        fullName: _fullNameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        photoUrl: photoUrl,
        updatedAt: DateTime.now(),
      );

      // Update user in Firestore
      await userProvider.updateUser(updatedUser);

      // Update local auth provider
      authProvider.updateAppUser(updatedUser);

      if (!mounted) return;
      ToastNotification.showSuccess(context, 'Profile updated successfully!');
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ToastNotification.showError(context, 'Error updating profile: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.appUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile', style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.primaryColor.withValues(alpha: 0.1),
                    AppTheme.backgroundColor,
                  ],
                ),
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(24.r),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Profile Picture
                        Stack(
                          children: [
                            Center(
                              child: Container(
                                width: 120.r,
                                height: 120.r,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: AppTheme.primaryGradient,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 4.r,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 10.r,
                                      offset: Offset(0, 5.h),
                                    ),
                                  ],
                                ),
                                child: _imageFile != null
                                    ? ClipOval(
                                        child: Image.file(
                                          _imageFile!,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : (user.photoUrl != null
                                        ? ClipOval(
                                            child: Image.network(
                                              user.photoUrl!,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) =>
                                                  _buildInitialCircle(user),
                                            ),
                                          )
                                        : _buildInitialCircle(user)),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: MediaQuery.of(context).size.width / 2 - 60.r,
                              child: GestureDetector(
                                onTap: _showImagePickerOptions,
                                child: Container(
                                  padding: EdgeInsets.all(8.r),
                                  decoration: const BoxDecoration(
                                    color: AppTheme.primaryColor,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.edit,
                                    color: Colors.white,
                                    size: 20.r,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 32.h),

                        // Full Name
                        TextFormField(
                          controller: _fullNameController,
                          style: TextStyle(fontSize: 16.sp),
                          decoration: InputDecoration(
                            labelText: 'Full Name',
                            labelStyle: TextStyle(fontSize: 14.sp),
                            prefixIcon: Icon(Icons.person, size: 24.r),
                            hintText: 'Enter your full name',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your full name';
                            }
                            if (value.trim().length < 3) {
                              return 'Name must be at least 3 characters';
                            }
                            return null;
                          },
                        ),

                        SizedBox(height: 16.h),

                        // Email (Read-only)
                        TextFormField(
                          initialValue: user.email,
                          enabled: false,
                          style: TextStyle(fontSize: 16.sp, color: Colors.grey),
                          decoration: InputDecoration(
                            labelText: 'Email',
                            labelStyle: TextStyle(fontSize: 14.sp),
                            prefixIcon: Icon(Icons.email, size: 24.r),
                            suffixIcon: Icon(Icons.lock, size: 16.r),
                          ),
                        ),

                        SizedBox(height: 16.h),

                        // Phone
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          style: TextStyle(fontSize: 16.sp),
                          decoration: InputDecoration(
                            labelText: 'Phone Number',
                            labelStyle: TextStyle(fontSize: 14.sp),
                            prefixIcon: Icon(Icons.phone, size: 24.r),
                            hintText: 'Enter your phone number',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your phone number';
                            }
                            if (value.trim().length < 10) {
                              return 'Please enter a valid phone number';
                            }
                            return null;
                          },
                        ),

                        SizedBox(height: 16.h),

                        // Address
                        TextFormField(
                          controller: _addressController,
                          maxLines: 3,
                          style: TextStyle(fontSize: 16.sp),
                          decoration: InputDecoration(
                            labelText: 'Address',
                            labelStyle: TextStyle(fontSize: 14.sp),
                            prefixIcon: Icon(Icons.location_on, size: 24.r),
                            hintText: 'Enter your address',
                            alignLabelWithHint: true,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your address';
                            }
                            return null;
                          },
                        ),

                        SizedBox(height: 16.h),

                        // Role (Read-only)
                        TextFormField(
                          initialValue: user.role.value,
                          enabled: false,
                          style: TextStyle(fontSize: 16.sp, color: Colors.grey),
                          decoration: InputDecoration(
                            labelText: 'Role',
                            labelStyle: TextStyle(fontSize: 14.sp),
                            prefixIcon: Icon(Icons.badge, size: 24.r),
                            suffixIcon: Icon(Icons.lock, size: 16.r),
                          ),
                        ),

                        SizedBox(height: 32.h),

                        // Save Button
                        ElevatedButton(
                          onPressed: _isLoading ? null : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          child: _isLoading
                              ? SizedBox(
                                  height: 20.r,
                                  width: 20.r,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Text(
                                  'Save Changes',
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),

                        SizedBox(height: 12.h),

                        // Cancel Button
                        OutlinedButton(
                          onPressed: _isLoading
                              ? null
                              : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            side: const BorderSide(color: AppTheme.primaryColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 16.sp,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),

                        SizedBox(height: 24.h),

                        // Divider
                        const Divider(),

                        SizedBox(height: 16.h),

                        // Change Password Button
                        TextButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ChangePasswordScreen(),
                              ),
                            );
                          },
                          icon: Icon(Icons.lock_reset, size: 24.r),
                          label: Text('Change Password', style: TextStyle(fontSize: 16.sp)),
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.primaryColor,
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildInitialCircle(AppUser user) {
    return Center(
      child: Text(
        user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
        style: TextStyle(
          fontSize: 40.sp,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}
