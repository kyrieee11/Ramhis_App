import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';

import 'core/auth_token_session_flow.dart';
import 'auth/landingpage.dart';
import 'auth/reset_password.dart';
import 'user/home.dart';
import 'admin/admin_shell.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await AuthSession.restoreSession();
  } catch (_) {}

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  AppLinks? _appLinks;
  StreamSubscription<Uri>? _sub;
  String? _lastHandledToken;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    try {
      _appLinks = AppLinks();

      final initialUri = await _appLinks!.getInitialLink();
      if (initialUri != null) {
        _handleUri(initialUri);
      }

      _sub = _appLinks!.uriLinkStream.listen(
        (uri) {
          _handleUri(uri);
        },
        onError: (_) {},
      );
    } catch (e) {
      debugPrint('Deep link init error: $e');
    }
  }

  void _handleUri(Uri uri) {
    try {
      if (uri.scheme == 'myapp' && uri.host == 'reset-password') {
        final token = uri.queryParameters['token'];

        if (token == null || token.isEmpty) return;
        if (_lastHandledToken == token) return;

        _lastHandledToken = token;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          final nav = navigatorKey.currentState;
          if (nav == null) return;

          nav.push(
            MaterialPageRoute(
              builder: (_) => ResetPasswordScreen(token: token),
            ),
          );
        });
      }
    } catch (e) {
      debugPrint('Deep link handle error: $e');
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'RAMHIS',
      theme: ThemeData(
        primaryColor: const Color(0xFF3F5FBE),
        scaffoldBackgroundColor: const Color(0xFFF6F8FC),
        useMaterial3: true,
      ),
      home: _buildHome(),
    );
  }

  Widget _buildHome() {
    if (!AuthSession.isReady) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!AuthSession.isLoggedIn) {
      return const LandingpageWidget();
    }

    final currentUser = AuthSession.user;
    if (currentUser == null) {
      return const LandingpageWidget();
    }

    final role = (currentUser['role'] ?? '').toString();
    final status = (currentUser['status'] ?? 'active').toString();

    if (status == 'pending' || status == 'suspended') {
      return const LandingpageWidget();
    }

    if (role == 'admin') {
      return const AdminShellWidget();
    }

    return const HomeWidget();
  }
}