import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

import 'package:ramhis_app/core/session_manager.dart';
import 'package:ramhis_app/features/auth/screens/landing_page.dart';
import 'package:ramhis_app/features/auth/screens/reset_password_screen.dart';
import 'package:ramhis_app/features/user/screens/home_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Only restore local session — no network calls at startup
  await AuthSession.restoreSession();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription<Uri>? _linkSubscription;
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
    _checkSession();
  }

  // ── Session ────────────────────────────────────────────────

  Future<void> _checkSession() async {
  print('🔑 token on launch: ${AuthSession.accessToken}');
  print('👤 user on launch: ${AuthSession.currentUser}');

  if (!AuthSession.isLoggedIn) {
    if (mounted) setState(() => _isChecking = false);
    return;
  }

  try {
    await AuthSession.fetchMe();
  } catch (error) {
    final message = error.toString().toLowerCase();

    final isAuthFailure =
        message.contains('401') ||
        message.contains('403') ||
        message.contains('unauthorized') ||
        message.contains('forbidden') ||
        message.contains('jwt') ||
        message.contains('token');

    if (isAuthFailure) {
      await AuthSession.clearSession();

      final context = navigatorKey.currentContext;
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your session expired, please log in again.'),
          ),
        );
      }

      if (mounted) setState(() => _isChecking = false);
      return;
    }

    debugPrint(
      '⚠️ Network issue detected. Keeping local session.',
    );
  }

  final role =
      AuthSession.currentUser?['role']?.toString().toLowerCase();

  if (role == 'admin') {
    await AuthSession.clearSession();
    if (mounted) setState(() => _isChecking = false);
    return;
  }

  if (mounted) setState(() => _isChecking = false);
}

  // ── Deep links ─────────────────────────────────────────────

  Future<void> _initDeepLinks() async {
    final appLinks = AppLinks();

    final initialUri = await appLinks.getInitialLink();
    if (initialUri != null) {
      _handleDeepLink(initialUri);
    }

    _linkSubscription = appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    });
  }

  void _handleDeepLink(Uri uri) {
    final isResetPasswordLink =
        uri.host == 'reset-password' ||
        uri.path.contains('reset-password');

    if (!isResetPasswordLink) return;

    final token = uri.queryParameters['token'];
    if (token == null || token.isEmpty) return;

    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => ResetPasswordScreen(token: token),
      ),
    );
  }

  // ── Lifecycle ──────────────────────────────────────────────

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  // ── Routing ────────────────────────────────────────────────

  Widget _startScreen() {
    if (_isChecking) {
      return const Scaffold(
        backgroundColor: Color(0xFF5B76F7),
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (!AuthSession.isLoggedIn) {
      return const LandingpageWidget();
    }

    return const HomeScreen();
  }

  // ── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      home: _startScreen(),
      routes: {
        '/reset-password': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          final token = args is String ? args : '';
          return ResetPasswordScreen(token: token);
        },
      },
    );
  }
}