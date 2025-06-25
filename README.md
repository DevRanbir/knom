# Knom - Know Your Money

Knom is a smart and intuitive expense tracker Flutter application that simplifies financial management by automatically analyzing your SMS messages to categorize and track your transactions. Gain insights into your spending habits with visual analytics and a user-friendly interface.

---

## 🌟 Features

- **Automatic SMS Parsing:** Intelligently reads and processes financial transaction SMS messages.
- **Transaction Categorization:** Automatically categorizes income and expenses based on message content, including source (bank, merchant) and description (e.g., "Mobile Recharge," "UPI Payment").
- **Visual Analytics (Charts):** Interactive pie and bar charts to help you understand income vs. expenses and daily transaction volumes.
- **Multiple Time Period Views:** Filter your financial dashboard by Today, This Week, This Month, and This Year.
- **Dynamic Theming:** Light/Dark mode support with customizable accent colors.
- **Persistent Data Storage:** Offline storage with SQLite using `sqflite` for quick retrieval.

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (version 3.x.x or higher)
- Android Studio / VS Code with Flutter and Dart plugins
- Android device/emulator with SMS capabilities

### Installation

#### 1. Clone or Set Up Project

```bash
flutter create knom
cd knom
# Replace contents of lib/main.dart with the provided code
```

#### 2. Add Dependencies

Add to `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.2
  permission_handler: ^11.1.0
  sqflite: ^2.3.0
  path_provider: ^2.1.1
  fl_chart: ^0.65.0
  shared_preferences: ^2.2.2
  path: ^1.8.3
```

Then run:

```bash
flutter pub get
```

#### 3. Android-Specific Setup

In `android/app/src/main/AndroidManifest.xml`, add:

```xml
<uses-permission android:name="android.permission.READ_SMS" />
<uses-permission android:name="android.permission.RECEIVE_SMS" />
```

In `android/app/build.gradle`, ensure:

```gradle
android {
    defaultConfig {
        minSdkVersion 23
        // ...
    }
    // ...
}
```

#### 4. Run the App

```bash
flutter run
```

---

## 💡 How It Works

- Uses `MethodChannel` to access native Android SMS reading.
- `SMSReader` reads SMS data.
- `TransactionParser` uses Regex to parse message types, extract amount, source, and description.
- Ignores OTPs/promotions to focus on valid transactions.
- Saves parsed data in local SQLite DB.
- Home screen fetches and shows categorized data and charts.

---

## 📁 Project Structure (Key Files)

- `main.dart`: Main app logic and UI, Defines the Transaction model, Manages SQLite database, Handles Android SMS reading, Parses SMS content using Regex.

---

## 🛠️ Built With

- Flutter
- sqflite
- permission\_handler
- fl\_chart
- shared\_preferences

---

## 🤝 Contributing

Contributions are welcome! Feel free to submit issues or pull requests for improvements or bug fixes.

---

## 📜 License

This project is open-source.

---

## 🙏 Acknowledgements

- Special thanks to **Yours DevRanbir** for initial development.
- Huge appreciation to the Flutter community and plugin maintainers.

Made with ❤️ by Yours DevRanbir

