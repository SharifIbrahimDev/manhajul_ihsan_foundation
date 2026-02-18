import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/app_models.dart';
import 'president_dashboard.dart';
import 'registrar_dashboard.dart';
import 'cashier_dashboard.dart';
import 'user_dashboard.dart';

class DashboardRouter extends StatelessWidget {
  const DashboardRouter({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.appUser == null) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        switch (authProvider.appUser!.role) {
          case UserRole.president:
            return const PresidentDashboard();
          case UserRole.registrar:
            return const RegistrarDashboard();
          case UserRole.cashier:
            return const CashierDashboard();
          case UserRole.user:
            return const UserDashboard();
        }
      },
    );
  }
}