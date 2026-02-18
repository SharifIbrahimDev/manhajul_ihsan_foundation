# 📄 Manhajul Ihsan Foundation App: Instructions & Overview

## 🌟 Introduction
The **Manhajul Ihsan Foundation Mobile App** is a professional, role-based platform designed to manage foundation members and track financial contributions and humanitarian aid. Built with **Flutter** and **Firebase**, it provides a secure, real-time environment for the foundation's operations, living up to its motto: *"Every Life Matters"*.

---

## 🛠️ Core Functionalities

### 1. 🔐 Authentication & Account Security
- **Secure Login**: Email and password authentication via Firebase.
- **Registration**: New users can register; the first user automatically becomes the **President**.
- **Password Management**: Includes "Forgot Password" (email reset) and "Change Password" (within profile) for enhanced security.
- **Role-Based Access**: The app dynamically adjusts its features based on the user's assigned role.

### 2. 🏛️ Role-Based Dashboards
The app features four distinct roles, each with a tailored experience:
- **President**: The administrator. Can manage all users, assign roles, view all financial data, and oversee foundation statistics.
- **Registrar**: Focuses on user management. Can create, edit, and view user profiles but cannot access financial records or assign roles.
- **Cashier**: The financial manager. Can record credit/debit transactions, view financial history, and monitor fund balances.
- **User (Member)**: A standard member. Can view their own profile, track their personal contribution history, and receive notifications.

### 3. 💰 Financial Management
Tracks two types of transactions:
- **Credit (Income)**: Monthly contributions and general donations.
- **Debit (Expense)**: Support for orphans (**Marayu**), general assistance (**Taimako**), and medical aid (**Maralafiya**).
- **Features**: Real-time balance calculation, visual charts (Overview), and detailed transaction history with pull-to-refresh.

### 4. 👥 User Management
- **Directory**: Full list of members with search and filtering capabilities (for President/Registrar).
- **Profile Editing**: Users can update their name, phone, address, and profile picture.
- **Statistics**: Real-time counts of members and roles.

### 5. 💬 Communication & Notifications
- **Smart Chat**: In-app messaging system for communication between members and admins.
- **Role-Based Notifications**: Push notifications sent specifically to roles (e.g., all Cashiers) or individual users.
- **Real-time Updates**: Data syncs instantly across all devices using Firestore.

---

## 🏗️ How It Works (Technical Architecture)

### **The Stack**
- **Frontend**: Flutter (Dart) using the **Provider** pattern for state management.
- **Backend/Database**: **Cloud Firestore** for real-time NoSQL data storage.
- **Auth**: **Firebase Authentication**.
- **Messaging**: **Firebase Cloud Messaging (FCM)** for push notifications.
- **Styling**: Custom theme with primary foundation colors (Warm Yellows/Oranges) and modern widgets (Skeleton Loaders, Custom Empty States).

### **Data Models**
- **User**: Stores UID, fullName, email, phone, role, and profile metadata.
- **Transaction**: Records type, category, amount, date, description, and the user involved.
- **Chat**: Manages message content, sender info, and timestamps for real-time conversations.

---

## 🚦 Application State & Flow
1. **Splash Screen**: Checks authentication status.
2. **Auth Wrapper**: Redirects to Login or Main App based on the session.
3. **Main Navigator**: A three-tab interface providing quick access to:
    - **Dashboard**: Home of role-specific tasks.
    - **Messages**: The hub for foundation communications.
    - **Notifications**: Updates on transactions and foundation news.
4. **Data Sync**: Uses Firestore streams to ensure that when a Cashier adds a transaction, the President sees the updated balance immediately.

---

## 💡 Room for Improvement

### **1. UI/UX Enhancements**
- **Dark Mode**: While a theme provider exists, full optimization for a sleek dark mode would improve accessibility.
- **Advanced Visualizations**: Add more detailed financial reports with drill-down charts (e.g., monthly comparison bars).
- **Success Animations**: Integrate Lottie animations for successful transactions or registration to enhance the "premium" feel.

### **2. Feature Expansion**
- **Export Capabilities**: Allow Presidents and Cashiers to export financial reports to **PDF** or **Excel** for external auditing.
- **Biometric Login**: Speed up access with Fingerprint/FaceID integration.
- **Document Management**: Allow members to upload IDs or relevant documents (especially for aid recipients) to their profiles.
- **Offline Support**: Cache data locally so users can view their history without an internet connection.

### **3. Technical Robustness**
- **Automated Testing**: Implement Unit and Widget tests to ensure reliability as more features are added.
- **Analytics Integration**: Add Firebase Analytics to track user engagement and identify which features are most used.
- **Error Logging**: Integrate Sentry or Firebase Crashlytics to monitor performance and bugs in production.

---

**Manhajul Ihsan Foundation**  
*Every Life Matters*
