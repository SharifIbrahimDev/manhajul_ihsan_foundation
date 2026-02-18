import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../utils/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../models/app_models.dart';
import '../../screens/users/edit_profile_screen.dart';
import '../../screens/settings/settings_screen.dart';
import '../../screens/transactions/monthly_contribution_screen.dart';
import '../../screens/transactions/payment_details_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 280.w,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildNavItem(
                  context,
                  icon: Icons.dashboard_rounded,
                  label: 'Dashboard',
                  onTap: () => Navigator.pop(context),
                ),
                _buildNavItem(
                  context,
                  icon: Icons.person_rounded,
                  label: 'My Profile',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                    );
                  },
                ),
                _buildRoleSpecificItems(context),
                _buildNavItem(
                  context,
                  icon: Icons.settings_rounded,
                  label: 'Settings',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                  },
                ),
                Divider(indent: 20.w, endIndent: 20.w),
                _buildNavItem(
                  context,
                  icon: Icons.help_outline_rounded,
                  label: 'Help & Support',
                  onTap: () {
                    // TODO: Implement help
                    Navigator.pop(context);
                  },
                ),
                _buildNavItem(
                  context,
                  icon: Icons.info_outline_rounded,
                  label: 'About Foundation',
                  onTap: () {
                    // TODO: Implement about
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
          _buildLogoutButton(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.appUser;
        return Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(20.w, 60.h, 20.w, 20.h),
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.only(
              bottomRight: Radius.circular(30.r),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 70.r,
                height: 70.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.w),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10.r,
                      offset: Offset(0, 4.h),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: user?.photoUrl != null
                      ? Image.network(
                          user!.photoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildInitialPlaceholder(user),
                        )
                      : _buildInitialPlaceholder(user),
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                user?.fullName ?? 'User',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                user?.email ?? '',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 14.sp,
                ),
              ),
              SizedBox(height: 8.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  user?.role.value ?? '',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInitialPlaceholder(AppUser? user) {
    return Container(
      color: Colors.white.withValues(alpha: 0.3),
      child: Center(
        child: Text(
          user?.fullName.isNotEmpty == true ? user!.fullName[0].toUpperCase() : '?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 32.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildRoleSpecificItems(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final role = authProvider.appUser?.role;
        
        List<Widget> items = [];

        if (role == UserRole.user) {
          items.addAll([
             _buildNavItem(
              context,
              icon: Icons.payments_rounded,
              label: 'Make Payment',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PaymentDetailsScreen()),
                );
              },
            ),
            _buildNavItem(
              context,
              icon: Icons.history_rounded,
              label: 'My Contributions',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MonthlyContributionScreen()),
                );
              },
            ),
          ]);
        } else if (role == UserRole.president) {
          items.addAll([
            _buildNavItem(
              context,
              icon: Icons.people_rounded,
              label: 'User Management',
              onTap: () {
                Navigator.pop(context);
              },
            ),
            _buildNavItem(
              context,
              icon: Icons.account_balance_rounded,
              label: 'Financial Reports',
              onTap: () => Navigator.pop(context),
            ),
          ]);
        } else if (role == UserRole.registrar) {
          items.addAll([
            _buildNavItem(
              context,
              icon: Icons.person_add_rounded,
              label: 'Register New User',
              onTap: () => Navigator.pop(context),
            ),
          ]);
        } else if (role == UserRole.cashier) {
          items.addAll([
            _buildNavItem(
              context,
              icon: Icons.add_card_rounded,
              label: 'New Transaction',
              onTap: () => Navigator.pop(context),
            ),
            _buildNavItem(
              context,
              icon: Icons.person_off_rounded,
              label: 'Debtors List',
              onTap: () => Navigator.pop(context),
            ),
          ]);
        }

        return items.isEmpty ? const SizedBox.shrink() : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Divider(indent: 20.w, endIndent: 20.w),
            Padding(
              padding: EdgeInsets.only(left: 20.w, top: 10.h, bottom: 5.h),
              child: Text(
                'MANAGEMENT',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade500,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            ...items,
          ],
        );
      },
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor, size: 24.r),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.r),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 4.h),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(20.r),
      child: InkWell(
        onTap: () => _showLogoutDialog(context),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout_rounded, color: Colors.red, size: 20.r),
              SizedBox(width: 8.w),
              Text(
                'Logout',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Logout', style: TextStyle(fontSize: 18.sp)),
        content: Text('Are you sure you want to logout?', style: TextStyle(fontSize: 14.sp)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel', style: TextStyle(fontSize: 14.sp)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<ChatProvider>().clearAllData();
              context.read<AuthProvider>().signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
            ),
            child: Text('Logout', style: TextStyle(fontSize: 14.sp)),
          ),
        ],
      ),
    );
  }
}
