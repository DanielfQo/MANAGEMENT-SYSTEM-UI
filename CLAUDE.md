# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**management_system_ui** is a Flutter application for an inventory and employee management system with role-based access control. It's designed for businesses to manage stores, inventory (lotes), sales (ventas), and attendance (asistencia).

**Tech Stack:**
- Flutter (Dart) - UI framework
- Riverpod - State management
- GoRouter - Navigation and routing
- Dio - HTTP client
- Shared Preferences - Local persistence
- App Links - Deep linking support

## Development Commands

### Initial Setup
```bash
flutter pub get          # Install dependencies
```

### Running
```bash
flutter run              # Run app (selects connected device)
flutter run -d <device>  # Run on specific device (find with: flutter devices)
```

### Code Quality
```bash
flutter analyze                    # Run Dart analyzer and linter
flutter analyze --no-fatal-infos   # Analyze but don't fail on info-level issues
```

### Testing
```bash
flutter test                       # Run all tests
flutter test test/widget_test.dart # Run specific test file
flutter test -v                    # Verbose output
```

### Building
```bash
flutter build apk    # Build Android APK
flutter build ios    # Build iOS app
flutter build web    # Build web version
```

## Architecture & Patterns

### Folder Structure

```
lib/
├── main.dart                 # App entry point, deep linking setup
├── core/
│   ├── common_libs.dart      # Central re-exports (Riverpod, Dio, GoRouter)
│   ├── router.dart           # GoRouter configuration, navigation logic
│   ├── models/               # Shared models (e.g., StoreModel)
│   ├── network/
│   │   ├── api_client.dart   # Dio provider with interceptors
│   │   ├── auth_interceptor.dart  # Token handling and refresh logic
│   │   └── auth_events.dart   # Auth state change events
│   ├── constants/            # App-wide constants
│   ├── utils/
│   │   └── storage_service.dart   # SharedPreferences wrapper
│   └── widgets/              # Shared UI components
│
├── features/
│   ├── auth/                 # Authentication (login, logout, token refresh)
│   ├── onboarding/           # Profile completion, setup (empresa creation)
│   ├── tienda/               # Store management
│   ├── lote/                 # Inventory/batch management
│   ├── venta/                # Sales operations
│   ├── invitation/           # User invitations and role assignment
│   ├── users/                # User management (usuarios)
│   └── asistencia/           # Attendance tracking
```

### State Management (Riverpod)

The app uses **Riverpod** for all state management. Key patterns:

1. **Providers** - Single source of truth for state
   ```dart
   // Create a provider (immutable data or notifier for mutable)
   final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(...);
   ```

2. **Repositories** - Encapsulate API calls and data transformations
   ```dart
   // Example: features/auth/auth_repository.dart
   // Handles API communication for auth operations
   ```

3. **Notifiers** - Manage state transitions
   ```dart
   // Example: features/auth/auth_provider.dart
   class AuthNotifier extends StateNotifier<AuthState> { ... }
   ```

4. **Watching Providers** - Reactive state consumption
   ```dart
   final authState = ref.watch(authProvider);
   final authNotifier = ref.read(authProvider.notifier);
   ```

### Navigation (GoRouter)

- Single router provider in `core/router.dart`
- Supports deep linking via `app_links` package
- Role-based conditional navigation (owner/admin/regular user)
- Redirect logic handles onboarding flow:
  1. Unauthenticated → /login
  2. Incomplete profile → /profile/complete
  3. Owner with no stores → /setup
  4. Multiple stores → /select-store
  5. All checks pass → /home

### Authentication Flow

- Token stored in SharedPreferences
- `AuthInterceptor` automatically adds token to requests
- Automatic token refresh on 401 response
- `auth_events.dart` broadcasts auth state changes

### API Client

- Single Dio instance via `dioProvider`
- Base URL from `AppConstants.apiBaseUrl`
- Request/response logging enabled
- Auth interceptor handles token injection and refresh

### Models

- Feature-specific models in `features/[feature]/models/`
- Shared models in `core/models/`
- Response models separate from domain models (e.g., `LoteResponseModel` vs `LoteModel`)

## Common Patterns

### 1. Add a New Feature

1. Create folder in `features/[feature_name]/`
2. Add subdirectories: `models/`, repositories, providers, pages
3. Create repository for API calls
4. Create provider/notifier for state
5. Create pages for UI
6. Register routes in `core/router.dart`

### 2. Make an API Call

```dart
// In repository:
Future<T> fetchData() async {
  final dio = ref.read(dioProvider);
  final response = await dio.get('/endpoint');
  return T.fromJson(response.data);
}

// In provider:
final dataProvider = FutureProvider((ref) async {
  return ref.watch(myRepository).fetchData();
});

// In page:
final data = ref.watch(dataProvider);
```

### 3. Handle Auth State

```dart
// Watch auth state
final authState = ref.watch(authProvider);
if (!authState.isAuthenticated) {
  // Handle unauthenticated state
}

// Get current user
final userMe = authState.userMe;
final isDueno = userMe?.isDueno ?? false;
final rol = userMe?.rol;
```

### 4. Add Role-Based UI

The app uses three permission levels:
- **Dueño (Owner)** - Full access, can create stores
- **Administrador (Admin)** - Can manage users and view attendance
- **Regular User** - Can only access their assigned features

Check permissions in `MainShell` (router.dart) for navigation bar visibility.

## Key Files to Understand

- `lib/main.dart` - App initialization and deep link handling
- `lib/core/router.dart` - Complete routing and navigation guard logic
- `lib/core/common_libs.dart` - Central imports (update when adding shared exports)
- `lib/features/auth/auth_provider.dart` - User authentication state
- `pubspec.yaml` - Dependencies and versioning

## Important Notes

- Always use Riverpod providers instead of direct state management
- Import shared utilities from `common_libs.dart`
- API responses are processed in repositories before reaching providers
- Tests use standard `flutter_test` in `test/` directory
- Deep links are handled in `main.dart` and routes in `core/router.dart`
- Avoid null-safety issues by using `.isEmpty` instead of checking `!= null` on collections
