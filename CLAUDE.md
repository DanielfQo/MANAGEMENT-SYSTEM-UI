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

1. **Notifier Pattern** - Mutable state management (preferred pattern)
   ```dart
   // Create a notifier provider
   final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

   class AuthNotifier extends Notifier<AuthState> {
     @override
     AuthState build() => const AuthState();

     Future<void> login(String username, String password) async {
       state = state.copyWith(isLoading: true);
       // ... update state via state = ...
     }
   }
   ```

2. **Repositories** - Encapsulate API calls and error handling
   ```dart
   // Example: features/tienda/tienda_repository.dart
   // Repositories catch DioException and throw Exception with user-friendly messages
   Future<StoreModel> getTienda() async {
     try {
       final response = await _dio.get('store/');
       return StoreModel.fromJson(response.data);
     } on DioException catch (e) {
       throw Exception('Error message from response or default');
     }
   }
   ```

3. **FutureProvider** - For async data fetching with built-in AsyncValue
   ```dart
   final dataProvider = FutureProvider((ref) async {
     return ref.watch(myRepository).fetchData();
   });

   // In UI, handle AsyncValue states:
   final asyncData = ref.watch(dataProvider);
   asyncData.when(
     data: (data) => Text(data),
     loading: () => CircularProgressIndicator(),
     error: (error, _) => Text('Error: $error'),
   );
   ```

4. **Watching & Reading Providers** - Reactive state consumption
   ```dart
   final authState = ref.watch(authProvider);
   final authNotifier = ref.read(authProvider.notifier);
   ```

5. **Side Effects with Listeners** - For streams and one-time operations
   ```dart
   // In notifier build():
   final sub = authEventController.stream.listen((event) {
     if (event == AuthEvent.logout) {
       state = const AuthState();
     }
   });
   ref.onDispose(() => sub.cancel());
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

### Models & Error Handling

**Models:**
- Feature-specific models in `features/[feature]/models/`
- Shared models in `core/models/`
- Response models separate from domain models (e.g., `LoteResponseModel` vs `LoteModel`)
- All models use `fromJson()` factory constructors for deserialization

**Error Handling Pattern:**
- Repositories catch `DioException` and extract error messages from API response
- Error messages are wrapped in `Exception()` and thrown
- UI consumes these errors via `AsyncValue.error()` in FutureProvider or error states in StateNotifier
- Example: `throw Exception('Error al crear la tienda')` with fallback for missing data

**Response Error Extraction:**
```dart
on DioException catch (e) {
  final data = e.response?.data;
  String message = 'Default error message';
  if (data is Map) {
    final values = data.values.first;
    message = values is List ? values.first.toString() : values.toString();
  }
  throw Exception(message);
}
```

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
// In repository class:
final myRepositoryProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  return MyRepository(dio);
});

class MyRepository {
  final Dio _dio;
  MyRepository(this._dio);

  Future<MyModel> fetchData() async {
    try {
      final response = await _dio.get('/endpoint');
      return MyModel.fromJson(response.data);
    } on DioException catch (e) {
      final errorMsg = e.response?.data?['detail'] ?? 'Error fetching data';
      throw Exception(errorMsg);
    }
  }
}

// In provider:
final dataProvider = FutureProvider((ref) async {
  final repo = ref.watch(myRepositoryProvider);
  return repo.fetchData();
});

// In page - handle AsyncValue:
final asyncData = ref.watch(dataProvider);
asyncData.when(
  data: (data) => ListView(children: [/* use data */]),
  loading: () => const LoadingWidget(),
  error: (error, stack) => ErrorState(message: error.toString()),
);
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

### Shared Widgets

Available reusable UI components in `core/widgets/`:
- `EmptyState` - Displayed when no data is available
- `ErrorState` - Displayed for error messages with retry capability
- `StatusBadge` - For displaying status labels
- `CustomAppBar` - Standard app bar for feature pages
- `InvitationLinkSheet` - Bottom sheet for sharing invitation links

## Important Notes

### State & Providers
- Always use Riverpod providers instead of direct state management
- Use `Notifier<State>` pattern for mutable state (not deprecated `StateNotifier`)
- Use `FutureProvider` for async operations and handle `.when()` for data/loading/error states
- Import shared utilities and providers from `common_libs.dart`

### API & Data
- All API communication happens in repositories, never in providers
- Repositories catch `DioException`, extract error messages, and throw `Exception()`
- API responses are transformed in repositories before reaching providers
- Use `fromJson()` factory constructors for model deserialization

### Navigation & Deep Linking
- Deep links are parsed in `main.dart` and routed via `core/router.dart`
- Path format: `/{host}{path}?{query}` (e.g., `/invite/accept?token=123`)
- Navigation guards in router redirect based on auth state and onboarding progress

### Null Safety & Collections
- Avoid null-safety issues by using `.isEmpty` instead of `!= null` on collections
- Use the spread operator for conditional list items: `if (condition) item`

### Testing
- Tests use standard `flutter_test` in `test/` directory
- Test features in isolation with mock providers where needed
