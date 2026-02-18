// // lib/routes/app_router.dart
// import 'package:flutter/cupertino.dart';
// import 'package:go_router/go_router.dart';
// import 'package:provider/provider.dart';
//
// import '../providers/auth_provider.dart';
// import '../screens/auth/login_screen.dart';
// import '../screens/auth/register_screen.dart';
// import '../screens/dashboard/cashier_dashboard.dart';
// import '../screens/dashboard/president_dashboard.dart';
// import '../screens/dashboard/registrar_dashboard.dart';
// import '../screens/dashboard/user_dashboard.dart';
// import '../screens/splash_screen.dart';
// import '../screens/transactions/transaction_form_screen.dart';
// import '../screens/users/user_detail_screen.dart';
// class AppRouter {
//   static final GoRouter router = GoRouter(
//     initialLocation: '/',
//     routes: [
//       GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
//       GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
//       GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
//       GoRoute(
//         path: '/dashboard',
//         builder: (context, state) {
//           final authProvider = authProviderFromContext(context);  // Helper to get provider
//           switch (authProvider.currentUserModel?.role) {
//             case 'President':
//               return const PresidentDashboard();
//             case 'Registrar':
//               return const RegistrarDashboard();
//             case 'Cashier':
//               return const CashierDashboard();
//             default:
//               return const UserDashboard();
//           }
//         },
//       ),
//       GoRoute(
//         path: '/user-detail/:userId',
//         builder: (context, state) => UserDetailScreen(userId: state.pathParameters['userId']!),
//       ),
//       GoRoute(
//         path: '/transaction-form/:transactionId',
//         builder: (context, state) => TransactionFormScreen(transactionId: state.pathParameters['transactionId']!),
//       ),
//       // Add more routes as needed
//     ],
//   );
//
//   static AuthProvider authProviderFromContext(BuildContext context) {
//     return context.read<AuthProvider>();
//   }
// }