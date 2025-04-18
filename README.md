# 🧠 Cards - Advanced Flashcards App

![Cards Logo](https://via.placeholder.com/150x150.png?text=Cards)

## 📋 Table of Contents
- [Overview](#-overview)
- [Key Features](#-key-features)
- [Application Architecture](#-application-architecture)
- [Internal Architecture & Code Explanation](#-internal-architecture--code-explanation)
- [Technical Stack](#-technical-stack)
- [Code Structure](#-code-structure)
- [Data Flow](#-data-flow)
- [File-by-File Project Structure & Roles](#-file-by-file-project-structure--roles)
- [Installation](#-installation)
- [Usage Guide](#-usage-guide)
- [Contributing](#-contributing)
- [Testing](#-testing)
- [License](#-license)
- [API & Data Model Documentation](#-api--data-model-documentation)
- [Configuration & Environment](#-configuration--environment)
- [Troubleshooting & FAQ](#-troubleshooting--faq)
- [Accessibility](#-accessibility)
- [Performance](#-performance)
- [Internationalization](#-internationalization)
- [Release Notes](#-release-notes)
- [Security](#-security)
- [Third-Party Libraries](#-third-party-libraries)
- [Roadmap](#-roadmap)
- [Quick Start](#-quick-start)
- [Demo Video](#-demo-video)
- [Contribution Guidelines](#-contribution-guidelines)
- [Code of Conduct](#-code-of-conduct)
- [Issue & PR Templates](#-issue--pr-templates)
- [Detailed License](#-detailed-license)
- [Contact & Community](#-contact--community)
- [Known Limitations](#-known-limitations)
- [Architecture Diagrams](#-architecture-diagrams)

## 🌟 Overview

Cards is a cutting-edge flashcard application designed to enhance learning and memorization through active recall technique. The application employs cognitive science principles to optimize retention and learning efficiency, making it perfect for students, language learners, and professionals needing to master large volumes of information.

```
"Learning is not a spectator sport." - D. Blocher
```

## 🚀 Key Features

- **📝 Dynamic Flashcards**: Create and edit dual-sided flashcards with rich text formatting
- **🎤 Audio Integration**: Record and playback pronunciation for language learning
- **🗂️ Smart Organization**: Categorize and tag cards for efficient study sessions
- **🎮 Interactive Quiz Mode**: Test your knowledge with various question formats
- **📊 Learning Analytics**: Track your progress with detailed performance metrics
- **🌓 Personalized Themes**: Choose between light/dark modes or customize your own
- **♿ Accessibility Features**: Support for colorblind users, text scaling, and screen readers
- **💾 Data Portability**: Import/export your flashcards in CSV format
- **🔄 Cross-Platform Sync**: Access your cards on multiple devices (requires account)
- **⚡ Offline Mode**: Study anywhere, even without internet connection
- **🎨 Modern UI**: Beautiful and responsive design with engaging animations

## 🏗️ Application Architecture

Cards follows a feature-first architecture pattern with a clear separation of concerns:

```
┌─────────────────────────────────────┐
│            Presentation             │
│  ┌─────────┐  ┌────────┐  ┌──────┐  │
│  │ Screens │  │Widgets │  │ Views│  │
│  └────┬────┘  └───┬────┘  └──┬───┘  │
│       │           │          │      │
│       └───────────┼──────────┘      │
│                   ▼                 │
│         ┌──────────────────┐        │
│         │ Business Logic   │        │
│         │  (Controllers)   │        │
│         └────────┬─────────┘        │
│                  │                  │
│         ┌────────┼─────────┐        │
│         ▼        ▼         ▼        │
│  ┌──────────┐ ┌──────┐ ┌─────────┐  │
│  │ Services │ │Models│ │Providers│  │
│  └────┬─────┘ └──────┘ └────┬────┘  │
│       │                     │       │
└───────┼─────────────────────┼───────┘
        │                     │
        ▼                     ▼
┌───────────────┐     ┌──────────────┐
│  Local Data   │     │  External    │
│  (SQLite/Web) │     │  Services    │
└───────────────┘     └──────────────┘
```

The application uses a provider pattern for state management and dependency injection, ensuring a clean and testable codebase.

## 🛠️ Internal Architecture & Code Explanation

Cards is built with a strong focus on maintainability, modularity, and cross-platform support. Below is a detailed explanation of how the application is structured, how the main files interact, and how the core logic works under the hood.

### Project Structure & File Roles

The project follows a **feature-first** and **layered** architecture. Here is a breakdown of the main folders and their responsibilities:

```
lib/
  main.dart                  # Application entry point, sets up providers and launches the app
  core/                      # Core utilities and managers (theme, accessibility, constants)
  config/                    # App and Firebase configuration files
  features/                  # Main business features, each in its own folder
    flashcards/              # Flashcard domain: models, widgets, screens
    quiz/                    # Quiz logic: widgets, helpers, screens
    statistics/              # Analytics and statistics screens
    sync/                    # Synchronization logic and helpers
  services/                  # Global services (database, Firebase, sync, audio)
    database/                # Database providers (SQLite, WebStorage), interfaces, models
  shared/                    # Shared UI widgets and utilities (buttons, dialogs, backgrounds)
  utils/                     # Utility classes (CSV, logger, helpers)
  views/                     # Main app screens (home, quiz, statistics, import/export, sync)
```

#### Key Files and Their Roles
- **main.dart**: Initializes the app, sets up dependency injection with `Provider`, configures platform-specific settings, and launches the root widget.
- **core/theme/theme_manager.dart**: Manages theme state (light/dark/custom), exposes theme data to the app.
- **core/accessibility/accessibility_manager.dart**: Handles accessibility settings (text scaling, high contrast, etc.).
- **features/flashcards/models/flashcard.dart**: Defines the `Flashcard` data model, including serialization, deserialization, and utility methods.
- **services/database_helper.dart**: Singleton service that abstracts all database operations, choosing the right provider (SQLite or WebStorage) based on the platform.
- **services/database/database_provider.dart**: Interface for database providers, ensuring consistent CRUD operations.
- **services/database/sqlite_provider.dart**: Implements the database provider for mobile/desktop using SQLite.
- **services/database/web_storage_provider.dart**: Implements the provider for web using LocalStorage.
- **services/firebase_manager.dart**: Handles all Firebase/Firestore operations for cloud sync.
- **features/quiz/widgets/**: Contains all quiz-related UI components.
- **views/home_view.dart**: Main dashboard, handles card listing, filtering, and navigation.
- **views/quiz_view.dart**: Quiz mode logic and UI, manages quiz state and user interactions.
- **views/statistics_view.dart**: Displays learning analytics and statistics.
- **views/sync_view.dart**: UI and logic for cloud synchronization.
- **utils/csv_parser.dart**: Parses and generates CSV files for import/export.
- **shared/widgets/**: Reusable UI components (buttons, dialogs, animated backgrounds, etc.).

### How the App Works Internally

#### 1. App Startup
- The app starts in `main.dart`, initializing platform-specific settings (window size, SQLite FFI, Firebase if enabled).
- Providers for theme, accessibility, database, and optionally Firebase are injected at the root using `MultiProvider`.
- The root widget (`MyApp`) sets up the MaterialApp and loads the `HomeView`.

#### 2. State Management
- The app uses the `Provider` package for state management.
- `ThemeManager` and `AccessibilityManager` are `ChangeNotifier` classes, exposing state and methods to update it.
- The database and Firebase managers are injected as singleton services.
- UI widgets listen to these providers and rebuild automatically when state changes.

#### 3. Data Persistence
- All flashcard data is persisted locally using SQLite (mobile/desktop) or LocalStorage (web).
- The `DatabaseHelper` singleton abstracts all CRUD operations, so the rest of the app does not need to know which backend is used.
- Data models (like `Flashcard`) are immutable and provide methods for serialization (to/from Map, CSV, JSON).

#### 4. Business Logic
- **Flashcard CRUD**: Adding, editing, and deleting cards is handled via forms and dialogs in the UI, which call methods on `DatabaseHelper`.
- **Quiz Mode**: The quiz logic loads cards from the database, tracks user answers, manages timers, and updates card status (known/unknown) after each answer.
- **Statistics**: The statistics view queries the database for card status and review history, then displays analytics using custom widgets.
- **Synchronization**: If enabled, the sync service compares local and remote data, resolves conflicts, and updates both sides as needed.
- **Import/Export**: CSV import/export is handled by utility classes, with user dialogs for file selection and column mapping.

#### 5. UI and Navigation
- The UI is built with custom widgets and Material Design principles.
- Navigation between screens is handled with `Navigator` and custom transitions (e.g., fade transitions).
- The desktop version includes a native-like menu bar with keyboard shortcuts.
- Accessibility and theme settings are available from the main UI and are persisted across sessions.

### Example: Adding a New Flashcard
1. User clicks the "+" button in the HomeView.
2. The `AddCardView` screen is shown, with a form for front/back text, category, and optional audio.
3. On save, the form creates a new `Flashcard` object and calls `DatabaseHelper.saveCard()`.
4. The database provider inserts the card into SQLite or LocalStorage.
5. The HomeView reloads the card list and displays the new card.

### Example: Quiz Flow
1. User selects "Quiz" mode from the HomeView.
2. The `QuizView` loads cards (optionally filtered by category) from the database.
3. The quiz logic presents cards one by one, tracks answers, and updates card status.
4. At the end, results and statistics are shown, and the user can restart or return to the dashboard.

### Example: Synchronization
1. User opens the SyncView and clicks "Synchronize".
2. The sync service fetches local changes and remote changes from Firebase.
3. It merges changes, resolves conflicts (using timestamps), and updates both local and remote stores.
4. Sync status and statistics are displayed to the user.

### Code Quality and Best Practices
- The codebase uses immutability for data models, clear separation of concerns, and dependency injection for testability.
- All business logic is separated from UI code, making it easy to test and maintain.
- The project includes unit and widget tests for all critical components.
- The code follows the Dart style guide and uses meaningful naming conventions.

### Extending the App
- To add a new feature, create a new folder in `features/` and follow the same structure (models, widgets, screens).
- To add a new database provider, implement the `DatabaseProvider` interface and register it in `DatabaseHelper`.
- To add new UI components, place them in `shared/widgets/` for reuse across the app.

---

This detailed section should help any developer understand how Cards is built, how the code is organized, and how the main features work internally. For more details, refer to the code comments and the test files in the `test/` directory.

## 💻 Technical Stack

- **Frontend Framework**: Flutter 3.7+
- **Programming Language**: Dart 3.7+
- **State Management**: Provider
- **Local Database**: SQLite (mobile/desktop) & LocalStorage (web)
- **Audio Processing**: just_audio & record packages
- **UI Components**: Custom widgets with Material Design influence
- **Analytics**: Firebase Analytics (optional)
- **Authentication**: Firebase Auth (optional)
- **Testing**: Flutter Test framework & Mockito

## 📁 Code Structure

Cards employs a feature-first architecture that organizes code by domain rather than technical layers:

```
lib/
  ├── main.dart                # Application entry point
  ├── core/                    # Core application functionality
  │   ├── accessibility/       # Accessibility settings & services
  │   ├── theme/               # Theme management
  │   └── constants/           # App-wide constants
  ├── features/                # Feature modules
  │   ├── flashcards/          # Flashcard domain
  │   │   ├── models/          # Data models (Flashcard class etc.)
  │   │   ├── widgets/         # UI components for flashcards
  │   │   └── screens/         # Screens related to flashcards
  │   ├── quiz/                # Quiz functionality
  │   │   ├── widgets/         # Quiz-specific components
  │   │   └── screens/         # Quiz screens
  │   ├── settings/            # App settings
  │   └── statistics/          # Learning statistics & analytics
  ├── services/                # Global services
  │   ├── database/            # Database operations
  │   ├── audio/               # Audio recording & playback
  │   └── firebase/            # Firebase integration
  ├── shared/                  # Shared resources
  │   ├── widgets/             # Reusable UI components
  │   └── utils/               # Utility functions & helpers
  └── config/                  # Configuration files
```

Key principles of the code organization:
- **Separation of Concerns**: Each module has a single responsibility
- **Encapsulation**: Features are isolated and self-contained
- **Reusability**: Common elements are abstracted into shared components
- **Testability**: Code is structured to facilitate unit and widget testing

## 🔄 Data Flow

The application follows a unidirectional data flow pattern:

```
┌─────────────┐         ┌─────────────┐         ┌─────────────┐
│   Action    │──────►  │   State     │──────►  │    UI      │
│  (Events)   │         │  (Providers)│         │  (Widgets)  │
└─────────────┘         └─────────────┘         └─────────────┘
      ▲                                               │
      │                                               │
      └───────────────────────────────────────────────┘
                        User Input
```

1. **User Interaction**: The user interacts with the UI
2. **Action Dispatch**: Actions/events are dispatched to providers
3. **State Update**: Providers update the application state
4. **UI Refresh**: Widgets listen to state changes and rebuild when needed
5. **Cycle Continues**: The user sees the updated UI and can interact again

## 📂 File-by-File Project Structure & Roles

Below is a detailed breakdown of the main files and folders in the Cards project, explaining the purpose and role of each. This section is designed to help new contributors and maintainers quickly understand where to find and place code, and how the application is organized internally.

### Root Directory
- **README.md**: This documentation file. Explains the project, architecture, usage, and contribution guidelines.
- **pubspec.yaml**: Flutter/Dart project manifest. Lists dependencies, assets, and project metadata.
- **pubspec.lock**: Auto-generated lockfile for dependency versions.
- **analysis_options.yaml**: Linting and static analysis rules for Dart code quality.
- **devtools_options.yaml**: Configuration for Flutter DevTools.
- **projet.iml**: IntelliJ/IDEA project file.

### Build & Platform Folders
- **build/**: Generated build artifacts for all platforms (do not edit manually).
- **web/**: Web-specific assets and entry points (e.g., `index.html`, icons, manifest).
- **windows/**, **macos/**: Platform-specific code and build files for desktop targets.

### Main Source Directory: `lib/`
- **main.dart**: The entry point of the app. Initializes providers, configures platform-specific settings, and launches the root widget (`MyApp`).

#### `lib/components/`
- Shared UI components used across multiple screens (e.g., custom menus, buttons, dialogs).

#### `lib/config/`
- **app_config.dart**: Centralizes app-wide configuration (app name, version, feature flags, platform defaults).
- **firebase_config.dart**: Firebase/Firestore configuration for cloud sync (API keys, project IDs, etc.).

#### `lib/core/`
- **theme/theme_manager.dart**: Manages theme state (light/dark/custom), exposes theme data.
- **accessibility/accessibility_manager.dart**: Handles accessibility settings (text scaling, high contrast, etc.).
- **constants/**: App-wide constants (colors, keys, etc.).

#### `lib/features/`
- **flashcards/**: All logic and UI for flashcard management.
  - **models/flashcard.dart**: The main data model for a flashcard, with serialization and utility methods.
  - **widgets/**: UI components for displaying and editing flashcards.
  - **screens/**: Screens for listing, adding, and editing flashcards.
- **quiz/**: Quiz and study mode logic.
  - **widgets/**: Quiz UI components (question cards, results, etc.).
  - **helpers/**: Quiz logic helpers (audio, shortcuts, loaders).
  - **screens/**: Quiz mode screens.
- **statistics/**: Analytics and statistics logic and UI.
- **sync/**: Synchronization logic and helpers for cloud sync.
- **settings/**: User settings screens and logic.

#### `lib/models/`
- (If present) Shared data models used across features.

#### `lib/services/`
- **database_helper.dart**: Singleton service for all database operations. Chooses the correct provider (SQLite or WebStorage) based on platform.
- **firebase_manager.dart**: Handles all Firebase/Firestore operations for cloud sync.
- **sync_service.dart**: Manages bidirectional sync between local and remote data, conflict resolution, and batch operations.
- **database/**: Contains database provider implementations:
  - **database_provider.dart**: Abstract interface for database providers.
  - **sqlite_provider.dart**: SQLite implementation for mobile/desktop.
  - **web_storage_provider.dart**: LocalStorage implementation for web.
  - **models/import_result.dart**: Data model for import/export results.
- **audio/**: Audio recording and playback services.

#### `lib/shared/`
- **widgets/**: Reusable UI widgets (buttons, dialogs, animated backgrounds, etc.).
- **utils/**: Utility classes (CSV parser, logger, helpers, file pickers).

#### `lib/views/`
- **home_view.dart**: Main dashboard, handles card listing, filtering, and navigation.
- **add_card_view.dart**: UI and logic for adding a new flashcard.
- **edit_card_view.dart**: UI and logic for editing an existing flashcard.
- **quiz_view.dart**: Quiz mode logic and UI, manages quiz state and user interactions.
- **statistics_view.dart**: Displays learning analytics and statistics.
- **sync_view.dart**: UI and logic for cloud synchronization.
- **import_export_view.dart**: UI for importing/exporting cards as CSV.

### Test Directory: `test/`
- **database_helper_test.dart**: Unit tests for database operations and provider logic.
- **flashcard_model_test.dart**: Unit tests for the Flashcard data model (serialization, equality, etc.).
- **widget_test.dart**: Widget and integration tests for UI components and flows.

### Other Notable Files/Folders
- **firebase_cpp_sdk_windows_11.10.0.zip**: Firebase C++ SDK for Windows (used for desktop sync, if enabled).
- **CMakeLists.txt**: CMake build configuration for Windows/desktop.
- **.iml, .sln, .vcxproj**: IDE and build system files for various platforms.

---

This section, combined with the rest of the documentation, provides a comprehensive map of the Cards project. Each file and folder has a clear purpose, making it easy for developers to navigate, extend, and maintain the codebase. For more details, refer to the code comments and the technical explanations above.

## 📊 Database Schema

Cards uses a relational database structure with the following key entities:

```
┌─────────────────┐       ┌─────────────────┐
│    Flashcard    │       │    Category     │
├─────────────────┤       ├─────────────────┤
│ id              │       │ id              │
│ uuid            │       │ name            │
│ front           │       │ color           │
│ back            │       │ icon            │
│ category_id     │◄──────┤ created_at      │
│ audio_path      │       └─────────────────┘
│ is_known        │
│ created_at      │       ┌─────────────────┐
│ last_modified   │       │    Statistics   │
│ review_count    │       ├─────────────────┤
│ is_deleted      │◄──────┤ card_id         │
└─────────────────┘       │ review_time     │
                          │ is_correct      │
                          │ timestamp       │
                          └─────────────────┘
```

## ⚙️ Installation

### Prerequisites
- Flutter SDK: ^3.7.0
- Dart SDK: ^3.7.0
- Git

### Setup Steps

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/cards-app.git
   cd cards-app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the application**
   ```bash
   flutter run
   ```

### Platform Support
- ✅ Android
- ✅ iOS
- ✅ Web
- ✅ Windows
- ✅ macOS
- ✅ Linux

## 📱 Usage Guide

### Creating Flashcards
1. Navigate to the Flashcards tab
2. Tap the + button to create a new card
3. Enter front and back content
4. Optionally add audio recording
5. Select or create a category
6. Save the card

### Study Mode
1. Select a category or deck
2. Choose between Browse, Quiz, or Spaced Repetition
3. Review cards and mark them as known/unknown
4. View your performance statistics after completion

### Customizing Experience
1. Go to Settings
2. Adjust theme preferences
3. Configure accessibility options
4. Set study reminders
5. Manage data synchronization

## 🧪 Testing

Cards includes comprehensive test coverage:

```bash
# Run all tests
flutter test

# Run specific test files
flutter test test/database_helper_test.dart
flutter test test/flashcard_model_test.dart
```

### Test Structure
- **Unit Tests**: For testing individual classes and functions
- **Widget Tests**: For testing UI components
- **Integration Tests**: For testing feature workflows

## 🤝 Contributing

Contributions are welcome! Here's how you can help:

1. **Fork the repository**
2. **Create a feature branch**: `git checkout -b feature/amazing-feature`
3. **Make your changes**: Follow the coding style and add tests
4. **Run tests**: Ensure all tests pass
5. **Commit your changes**: `git commit -m 'Add amazing feature'`
6. **Push to the branch**: `git push origin feature/amazing-feature`
7. **Open a Pull Request`

### Code Style Guide
- Follow the [Dart style guide](https://dart.dev/guides/language/effective-dart/style)
- Use meaningful variable and function names
- Add documentation comments to public APIs
- Keep functions small and focused

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

## 📡 API & Data Model Documentation

### Flashcard Data Model
The core data structure is the `Flashcard` model. Below are its fields, types, and validation rules:

| Field           | Type                | Description                                      | Validation/Notes                |
|-----------------|---------------------|--------------------------------------------------|---------------------------------|
| id              | int?                | Local auto-incremented ID                        | Optional, set by database       |
| uuid            | String?             | Global unique identifier (for sync)              | Required for sync/cloud         |
| front           | String              | Front text of the card                           | Required, non-empty             |
| back            | String              | Back text of the card                            | Required, non-empty             |
| isKnown         | bool                | Whether the card is marked as known              | Defaults to false               |
| category        | String?             | Category name                                    | Optional                        |
| audioPath       | String?             | Path to audio file (if any)                      | Optional                        |
| lastModified    | int?                | Last modified timestamp (ms since epoch)         | Set automatically               |
| isDeleted       | bool                | Soft delete flag                                 | Defaults to false               |
| reviewCount     | int                 | Number of times reviewed                         | Defaults to 0                   |
| lastReviewed    | int?                | Last review timestamp                            | Optional                        |
| difficultyScore | int                 | Difficulty score (0-100)                         | Defaults to 50                  |
| customData      | Map<String, dynamic>?| Custom user data (JSON)                          | Optional                        |

#### Example (Dart):
```dart
final card = Flashcard(
  front: 'What is Flutter?',
  back: 'A UI toolkit for building natively compiled apps.',
  isKnown: false,
  category: 'Programming',
);
```

### API Endpoints
Currently, Cards does not expose a public HTTP API. All data access is local (SQLite/LocalStorage) or via Firebase Firestore (if enabled). If you enable sync, the app will use Firestore collections named `flashcards` for cloud storage. See `services/firebase_manager.dart` for details.

---

## ⚙️ Configuration & Environment

### Environment Variables
- **Firebase**: Set your Firebase project credentials in `lib/config/firebase_config.dart`.
- **Analytics**: If using analytics, add your keys in the same config file.
- **Other**: For custom environment variables, you can use Dart's `String.fromEnvironment` or a `.env` loader package.

### Feature Flags
You can enable/disable features in `lib/config/app_config.dart`:
```dart
class AppConfig {
  static const bool useFirebase = false; // Enable cloud sync
  static const bool enableAudioFeatures = true; // Enable audio recording
  static const bool enableStatistics = true; // Enable statistics view
  static const bool enableQuizMode = true; // Enable quiz mode
  // ...
}
```
Change these flags and rebuild the app to enable/disable features.

---

## 🛠️ Troubleshooting & FAQ

### Common Issues
- **Build fails on Windows**: Ensure you have all required build tools (Visual Studio, CMake, etc.).
- **Database errors**: Delete the local database file if schema changes cause issues.
- **Sync not working**: Check your Firebase credentials and network connection.
- **Audio not recording**: Make sure microphone permissions are granted.

### FAQ
- **How do I reset all data?**
  - Delete the app's local storage/database file and restart the app.
- **How do I import/export cards?**
  - Use the Import/Export menu in the app (CSV format supported).
- **Can I use my own Firebase project?**
  - Yes, update `firebase_config.dart` with your project details.
- **How do I add a new feature?**
  - Create a new folder in `features/` and follow the existing structure.

---

## ♿ Accessibility Features
- **Colorblind Mode**: Daltonian-friendly color palettes are available in settings.
- **Keyboard Navigation**: All main actions are accessible via keyboard shortcuts (see tooltips in the UI).
- **Screen Reader Support**: UI widgets use semantic labels for compatibility with screen readers.
- **Text Scaling**: Users can adjust font size in the settings for better readability.

---

## 🚀 Performance Tips
- **Large Decks**: Use category filters and search to limit the number of cards loaded at once.
- **Database Maintenance**: Periodically export and re-import your cards to clean up old/deleted entries.
- **Sync Best Practices**: Sync regularly and resolve conflicts promptly to avoid data loss.
- **Disable Unused Features**: Turn off features you don't use in `app_config.dart` to reduce resource usage.

---

## 🌍 Internationalization (i18n)
- Cards is designed for easy localization. To add a new language:
  1. Add your translation files to the `lib/l10n/` directory (e.g., `intl_en.arb`, `intl_fr.arb`).
  2. Update the `pubspec.yaml` to include your new language.
  3. Use the `Intl` package in your widgets for localized strings.
- To switch languages, change the locale in the app settings (if implemented) or set the device language.

---

## 📝 Release Notes / Changelog

See `CHANGELOG.md` for a full list of changes. Major recent updates:
- **v1.0.0**: Initial public release with flashcards, quiz, statistics, import/export, and sync support.
- **v1.1.0**: Added accessibility features and performance improvements.
- **v1.2.0**: Improved database schema and added advanced filtering.

---

## 🔒 Security Considerations
- **Data Storage**: All user data is stored locally on device or in your private Firebase project.
- **Privacy**: No data is sent to third parties unless you enable cloud sync.
- **Permissions**: The app only requests permissions required for its features (e.g., microphone for audio).
- **Data Deletion**: Users can delete all their data at any time via the app interface.

---

## 📦 Third-Party Libraries
- **provider**: State management (simple, robust, and recommended by Flutter).
- **sqflite / sqflite_common_ffi**: SQLite database for persistent local storage.
- **just_audio**: Audio playback for card pronunciation.
- **file_picker**: File import/export dialogs.
- **uuid**: Unique ID generation for cards and sync.
- **firebase_core / cloud_firestore**: Cloud sync and analytics (optional).
- **intl**: Internationalization and localization support.
- **flutter_test / mockito**: Testing and mocking utilities.

---

## 🗺️ Roadmap
- **Short Term**:
  - Add spaced repetition algorithms (SM-2, Anki-style)
  - Improve mobile and web accessibility
  - Add more statistics and progress charts
- **Medium Term**:
  - REST API for remote access and integrations
  - Real-time collaboration and shared decks
  - In-app marketplace for public decks
- **Long Term**:
  - AI-powered card generation and smart suggestions
  - Native desktop and mobile notifications
  - Plugin system for custom study modes

---

## ⚡ Quick Start

Get Cards up and running in just a few steps:

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/cards-app.git
   cd cards-app
   ```
2. **Install dependencies**
   ```bash
   flutter pub get
   ```
3. **Run the app**
   ```bash
   flutter run
   ```

For more details, see the [Installation](#installation) section.

---

## 🎬 Demo Video

Watch a demo of Cards in action:
- [YouTube Demo](https://www.youtube.com/watch?v=YOUR_DEMO_VIDEO)
- [Loom Demo](https://www.loom.com/share/YOUR_LOOM_VIDEO)

---

## 🤝 Contribution Guidelines

We welcome contributions! Please read our [CONTRIBUTING.md](CONTRIBUTING.md) for detailed instructions on how to:
- Propose new features
- Report bugs
- Submit pull requests
- Review code style and commit message conventions

---

## 🌐 Code of Conduct

We are committed to fostering a welcoming and inclusive community. Please read our [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) before participating.

---

## 📝 Issue & PR Templates

To streamline collaboration, we use GitHub issue and pull request templates. When opening an issue or PR, please follow the provided format to help us address your contribution efficiently.

---

## 📄 Detailed License

Cards is licensed under the MIT License. You are free to use, modify, and distribute the software, provided you include the original copyright and license.

- See the full license in [LICENSE](LICENSE).

---

## 📞 Contact & Community

- **Discord**: [Join our Discord](https://discord.gg/YOUR_DISCORD_INVITE)
- **Slack**: [Join our Slack](https://join.slack.com/t/cards-app/shared_invite/...) 
- **Forum**: [Community Forum](https://community.cards-app.dev)
- **Email**: support@cards-app.dev

Feel free to reach out for support, feature requests, or to connect with other users and contributors!

---

## ⚠️ Known Limitations

- No public REST API (local and Firebase sync only)
- No built-in spaced repetition algorithm (planned)
- No real-time collaboration (planned)
- Some advanced accessibility features may be limited on web
- Desktop builds require additional setup on Windows/macOS/Linux
- Only English and French localizations are currently available

---

## 🏗️ Architecture Diagrams

### High-Level Component Diagram
```
+-------------------+
|    User Interface |
+-------------------+
          |
          v
+-------------------+
|   State Providers |
+-------------------+
          |
          v
+-------------------+
|   Business Logic  |
+-------------------+
          |
          v
+-------------------+
| Persistence Layer |
+-------------------+
   |           |
   v           v
SQLite     Firebase
(Web)      (Cloud)
```

### Sequence Diagram: Add Flashcard
```
User -> UI: Clicks "Add Card"
UI -> AddCardView: Opens form
AddCardView -> DatabaseHelper: saveCard(card)
DatabaseHelper -> Provider: Insert into DB
Provider -> Database: Store card
Database -> Provider: Success
Provider -> UI: Update card list
```

### Data Flow (UML)
```
[User] -> [UI Widgets] -> [Providers] -> [Services] -> [Database/Cloud]
```

For more technical diagrams, see the `/docs` folder (if available) or contact the maintainers.

---
