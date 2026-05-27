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

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
    _checkSession();
  }

  Future<void> _checkSession() async {
    if (!AuthSession.isLoggedIn) return;

    final user = await AuthSession.fetchMe();

    if (user == null) {
      final refreshed = await AuthSession.refreshSession();

      if (refreshed) {
        await AuthSession.fetchMe();
      } else {
        await AuthSession.clearSession();
      }
    }

    final role = AuthSession.currentUser?['role']
        ?.toString()
        .toLowerCase();

    if (role == 'admin') {
      await AuthSession.clearSession();
    }

    if (mounted) setState(() {});
  }

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

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  Widget _startScreen() {
    if (!AuthSession.isLoggedIn) {
      return const LandingpageWidget();
    }

    return const HomeScreen();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
  navigatorKey: navigatorKey,
  debugShowCheckedModeBanner: false,
  home: _startScreen(),
  routes: {
  '/reset-password': (context) {
    final args =
        ModalRoute.of(context)?.settings.arguments;

    final token =
        args is String ? args : '';

    return ResetPasswordScreen(
      token: token,
    );
  },
},
);
  }
}