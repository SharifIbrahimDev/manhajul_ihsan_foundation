# Contributing to Manhajul Ihsan Foundation Mobile App

First off, thank you for considering contributing to the Manhajul Ihsan Foundation Mobile App! It's people like you that make this community-driven project a reality. Every contribution, whether it's a bug fix, feature, or documentation update, is highly valued.

## 🤝 How Can I Contribute?

### Reporting Bugs
If you find a bug, please create a new issue in our GitHub repository. Include:
- A clear descriptive title
- The version of the app you are running
- Steps to reproduce the behavior
- Expected behavior vs actual behavior
- Any relevant logs or screenshots

### Suggesting Enhancements
Have an idea to make the app better? Great! Check the [ROADMAP.md](./ROADMAP.md) and open issues first to make sure someone isn't already working on it. If not, open a new issue describing your enhancement, why it's needed, and how it aligns with the foundation's goals.

### Code Contributions
1. **Fork the repository** to your own GitHub account.
2. **Clone the project** to your local machine.
3. **Create a branch** for your feature or bug fix:
   ```bash
   git checkout -b feature/your-feature-name
   ```
4. **Make your changes**. Ensure your code follows our style guidelines and includes appropriate tests.
5. **Commit your changes**:
   ```bash
   git commit -m "feat: Add your feature description"
   ```
6. **Push to your fork**:
   ```bash
   git push origin feature/your-feature-name
   ```
7. **Submit a Pull Request** against our `main` branch.

## 💻 Development Setup

Please refer to the [README.md](./README.md) for full setup instructions, including Firebase configuration and Flutter SDK requirements.

### Coding Standards
- We use standard Flutter/Dart formatting. Run `flutter format .` before committing.
- Ensure there are no warnings from `flutter analyze`.
- Write unit tests or widget tests for any new features or logic changes.
- Follow the existing project structure (e.g., keep state management in `providers/`, models in `models/`).

### Firebase Security Rules
If your feature requires changes to the database structure, you **must** also update the `firestore.rules` and `storage.rules` files to ensure role-based security is maintained.

## 📄 Code of Conduct
By participating in this project, you agree to abide by our Code of Conduct. Please treat all contributors with respect.

Thank you for helping us support the mission: *Every Life Matters*.
