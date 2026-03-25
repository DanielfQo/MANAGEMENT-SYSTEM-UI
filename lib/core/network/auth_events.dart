// core/network/auth_events.dart
import 'dart:async';

final authEventController = StreamController<AuthEvent>.broadcast();

enum AuthEvent { logout }