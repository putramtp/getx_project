import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Central place all uncaught errors flow through.
///
/// Today it logs to the Dart DevTools console (and stderr in profile/release).
/// It is intentionally the *single* integration point for a hosted crash
/// reporter: to add Sentry or Firebase Crashlytics later, initialize the SDK in
/// [init] and forward [recordError] / [recordFlutterError] to it — nothing else
/// in the app needs to change.
///
/// Wire-up lives in `main.dart`:
///  - [runGuarded] wraps `runApp` in a zone that catches async errors.
///  - [recordFlutterError] is set as `FlutterError.onError`.
///  - [recordError] is set as `PlatformDispatcher.instance.onError`.
class CrashReporter {
  CrashReporter._();

  /// Initialize the reporter. Call once, early, inside the guarded zone.
  ///
  /// Drop-in example for a hosted reporter:
  /// ```dart
  /// await SentryFlutter.init((o) => o.dsn = AppConfig.sentryDsn);
  /// ```
  static Future<void> init() async {
    // No-op for the console reporter. Reserved for SDK initialization.
  }

  /// Report a caught/uncaught error with its stack trace.
  /// [fatal] marks crashes that took down a zone (vs. handled errors).
  static void recordError(
    Object error,
    StackTrace? stack, {
    bool fatal = false,
    String? context,
  }) {
    developer.log(
      'Uncaught ${fatal ? "fatal " : ""}error${context != null ? " ($context)" : ""}',
      name: 'CrashReporter',
      error: error,
      stackTrace: stack ?? StackTrace.current,
      level: 1000, // SEVERE
    );
    // TODO(reporter): forward to Sentry/Crashlytics here.
    // e.g. Sentry.captureException(error, stackTrace: stack);
  }

  /// Report an error surfaced by the Flutter framework.
  static void recordFlutterError(FlutterErrorDetails details) {
    // Keep Flutter's own pretty console dump in debug.
    FlutterError.presentError(details);
    recordError(
      details.exception,
      details.stack,
      fatal: true,
      context: details.library,
    );
  }

  /// Runs [body] (which must call `runApp`) inside a guarded zone so that
  /// asynchronous errors escaping the widget tree are captured too.
  static Future<void> runGuarded(FutureOr<void> Function() body) async {
    await runZonedGuarded<Future<void>>(
      () async => await body(),
      (error, stack) => recordError(error, stack, fatal: true, context: 'zone'),
    );
  }

  /// A friendly fallback widget shown instead of the default red error screen
  /// when a widget throws during build. In debug it still shows the details.
  static Widget errorWidgetBuilder(FlutterErrorDetails details) {
    if (kDebugMode) {
      return ErrorWidget(details.exception);
    }
    return const _FriendlyErrorScreen();
  }
}

class _FriendlyErrorScreen extends StatelessWidget {
  const _FriendlyErrorScreen();

  @override
  Widget build(BuildContext context) {
    return const Material(
      color: Colors.white,
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 48, color: Colors.redAccent),
              SizedBox(height: 12),
              Text(
                'Something went wrong',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 6),
              Text(
                'Please go back and try again.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
