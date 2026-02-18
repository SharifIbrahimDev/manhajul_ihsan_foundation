# Manhajul Ihsan Foundation Mobile App

A role-based user management and financial tracking mobile application built with Flutter and Firebase for the Manhajul Ihsan Foundation.

## Project Overview

The Manhajul Ihsan Foundation Mobile App supports the foundation's operations with secure, role-based access control and comprehensive financial tracking. The app features the foundation's branding with warm yellows, oranges, and rainbow accents, displaying the "Every Life Matters" motto throughout the interface.

## Features

### 🔐 Authentication & Authorization
- Email/password authentication via Firebase Auth
- Role-based access control with four user levels:
    - **President**: Full system access, user management, role assignment
    - **Registrar**: User profile management (CRUD operations)
    - **Cashier**: Financial transaction management
    - **User**: Personal profile and transaction viewing

### 👥 User Management
- User registration with automatic President assignment for first user
- Complete user profiles with contact information
- Role assignment and modification (President only)
- User search and filtering capabilities
- Real-time user statistics dashboard

### 💰 Financial Management
- **Credit Transactions**: Monthly contributions, donations
- **Debit Transactions**: Marayu (orphans), Taimako (support), Maralafiya (medical aid)
- Real-time financial overview with charts and statistics
- Transaction history with filtering and search
- Automatic balance calculations

### 📊 Dashboards
- Role-specific dashboards with tailored functionality
- Financial overview with pie charts and trends
- User statistics and management tools
- Real-time data updates via Firestore streams

### 🎨 Branding
- Custom theme with foundation colors (warm yellows, oranges, rainbow accents)
- "Every Life Matters" motto integration
- Consistent visual identity throughout the app
- Responsive design for mobile devices

## Technical Stack

### Frontend
- **Flutter 3.0+** - Cross-platform mobile development
- **Dart** - Programming language
- **Provider** - State management
- **Material Design** - UI components

### Backend
- **Firebase Authentication** - User authentication
- **Cloud Firestore** - NoSQL database
- **Firebase Security Rules** - Data access control

### Additional Packages
- `firebase_core` - Firebase SDK integration
- `firebase_auth` - Authentication services
- `cloud_firestore` - Firestore database
- `provider` - State management
- `intl` - Internationalization and formatting
- `fl_chart` - Charts and data visualization
- `email_validator` - Email validation
- `flutter_spinkit` - Loading animations

## Project Structure

```
lib/
├── main.dart                          # App entry point
├── models/
│   └── app_models.dart               # Data models
├── providers/
│   ├── auth_provider.dart            # Authentication state
│   ├── user_provider.dart            # User management
│   └── transaction_provider.dart     # Financial transactions
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart         # Login interface
│   │   └── register_screen.dart      # Registration interface
│   ├── dashboard/
│   │   ├── dashboard_router.dart     # Role-based routing
│   │   ├── president_dashboard.dart  # President interface
│   │   ├── registrar_dashboard.dart  # Registrar interface
│   │   ├── cashier_dashboard.dart    # Cashier interface
│   │   └── user_dashboard.dart       # User interface
│   └── splash_screen.dart            # Loading screen
├── widgets/
│   ├── financial_overview_widget.dart # Financial charts
│   ├── user_management_widget.dart    # User management UI
│   └── transaction_management_widget.dart # Transaction UI
└── utils/
    └── app_theme.dart                # Theme and styling
```

## Database Structure

### Users Collection
```json
{
  "uid": "string",
  "fullName": "string",
  "email": "string",
  "phone": "string",
  "address": "string",
  "role": "President|Registrar|Cashier|User",
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

### Transactions Collection
```json
{
  "type": "credit|debit",
  "category": "Monthly|Donation|Marayu|Taimako|Maralafiya",
  "amount": "number",
  "date": "timestamp",
  "description": "string (optional)",
  "linkedUser": "string (user uid)",
  "createdBy": "string (creator uid)"
}
```

## Setup Instructions

### Prerequisites
- Flutter SDK 3.0 or higher
- Firebase account
- Android Studio / Xcode for device testing

### Firebase Configuration

1. Create a new Firebase project
2. Enable Authentication with Email/Password
3. Create a Firestore database
4. Add Android/iOS apps to your Firebase project
5. Download configuration files:
    - `google-services.json` for Android
    - `GoogleService-Info.plist` for iOS

### Installation Steps

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd manhajul_ihsan_foundation
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
    - Place `google-services.json` in `android/app/`
    - Place `GoogleService-Info.plist` in `ios/Runner/`

4. **Set up Firestore Security Rules**
   ```bash
   firebase deploy --only firestore:rules
   ```

5. **Run the app**
   ```bash
   flutter run
   ```

## Security Rules

The app implements comprehensive Firestore security rules:

- **Authentication required** for all operations
- **Role-based access control** for data operations
- **Data validation** for all write operations
- **User isolation** for personal data access

## User Roles & Permissions

| Feature | President | Registrar | Cashier | User |
|---------|-----------|-----------|---------|------|
| View all users | ✅ | ✅ | ✅ | ❌ |
| Create users | ✅ | ✅ | ❌ | ❌ |
| Edit users | ✅ | ✅ | ❌ | Own profile |
| Delete users | ✅ | ✅ | ❌ | ❌ |
| Assign roles | ✅ | ❌ | ❌ | ❌ |
| View all transactions | ✅ | ❌ | ✅ | Own only |
| Create transactions | ✅ | ❌ | ✅ | ❌ |
| Edit transactions | ✅ | ❌ | ✅ | ❌ |
| Delete transactions | ✅ | ❌ | ✅ | ❌ |
| Financial overview | ✅ | ❌ | ✅ | ❌ |

## Testing

### Manual Testing Checklist

- [ ] User registration and first user becomes President
- [ ] Email/password authentication
- [ ] Role-based dashboard routing
- [ ] User CRUD operations (Registrar)
- [ ] Transaction CRUD operations (Cashier)
- [ ] Role assignment (President)
- [ ] Real-time data updates
- [ ] Security rule enforcement

### Test Accounts Setup

1. Register first user (becomes President automatically)
2. President creates additional users with different roles
3. Test role-specific functionality

## Deployment

### Android
```bash
flutter build apk --release
# or
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

## Maintenance

### Database Backups
- Configure automatic Firestore backups
- Export user data regularly
- Monitor transaction data integrity

### Performance Monitoring
- Use Firebase Performance Monitoring
- Monitor app crashes with Crashlytics
- Track user engagement with Analytics

## Troubleshooting

### Common Issues

1. **Firebase configuration errors**
    - Verify configuration files are properly placed
    - Check bundle IDs match Firebase project

2. **Permission denied errors**
    - Verify Firestore security rules are deployed
    - Check user authentication status

3. **Build failures**
    - Run `flutter clean` and `flutter pub get`
    - Update Flutter SDK if needed

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make changes with proper testing
4. Submit a pull request

## License

This project is developed for the Manhajul Ihsan Foundation. All rights reserved.

## Support

For technical support or questions about the application, please contact the development team.

---

**Manhajul Ihsan Foundation**  
*Every Life Matters*