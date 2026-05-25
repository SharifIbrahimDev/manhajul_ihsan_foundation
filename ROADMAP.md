# Project Roadmap: Manhajul Ihsan Foundation Mobile App

This document outlines the planned future features and improvements for the Manhajul Ihsan Foundation app. Our goal is to continuously improve the platform to better serve the foundation's operations, user management, and financial transparency.

## 📅 Short-Term Goals (Next 1-3 Months)

### UI & Aesthetics Improvements
- [ ] Migrate all loading indicators to `flutter_spinkit` for consistent branding.
- [ ] Implement skeleton loading screens while fetching data from Firestore.
- [ ] Create detailed empty state illustrations for the Dashboard and Transaction History.
- [ ] Add an animated Splash Screen (Rive/Lottie) featuring the foundation logo.
- [ ] Add haptic feedback for critical actions (deleting users, saving transactions).
- [ ] Improve Dark Mode contrast and accessibility.

### Core Features & Quality of Life
- [ ] Add Search functionality to the Transaction History screen.
- [ ] Add Advanced Date Range filtering for transactions.
- [ ] Enable User Sorting (by Role, by Join Date) in the User Management screen.
- [ ] Support Profile Picture uploads via Firebase Storage.
- [ ] Allow users to reset their passwords via Firebase Auth email links.

## 🚀 Mid-Term Goals (3-6 Months)

### Advanced Roles & Admin Tools
- [ ] Allow the President to bulk-assign user roles.
- [ ] Add a secure Audit Log collection tracking all role changes made by admins.
- [ ] Allow suspending/disabling user accounts instead of permanent deletion.
- [ ] Support custom, dynamic transaction categories created by the President.
- [ ] Export functionality: Enable Registrars and Cashiers to export User Lists and Financial Reports to CSV or PDF.

### Notifications & Automation
- [ ] Integrate Firebase Cloud Messaging (FCM) for push notifications on new transactions.
- [ ] Implement automated weekly summary emails for the President using Firebase Extensions.

## 🌟 Long-Term Vision (6+ Months)

### Platform Expansion & Resilience
- [ ] **Offline Mode:** Enable full Firestore offline persistence so users can view cached dashboards and queue transactions when without internet.
- [ ] **Web Dashboard:** Compile the project to Flutter Web, providing a desktop-optimized dashboard for the President and Cashiers.
- [ ] **Automated Backups:** Set up Firebase Cloud Functions to automatically backup the Firestore database to Cloud Storage every week.
- [ ] **Biometric Security:** Integrate FaceID/TouchID for app locking and secure login.
- [ ] **Multilingual Support:** Localize the application into Hausa and Arabic to serve a wider demographic.

---
*Note: This roadmap is a living document. Priorities may shift based on the immediate needs of the Manhajul Ihsan Foundation. Check our GitHub Issues for the current, day-to-day tasks.*
