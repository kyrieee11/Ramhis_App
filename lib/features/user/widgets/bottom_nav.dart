import 'package:flutter/material.dart';

import 'package:ramhis_app/features/user/screens/home_screen.dart';
import 'package:ramhis_app/features/user/screens/chat_screen.dart';
import 'package:ramhis_app/features/user/screens/account_screen.dart';
import 'package:ramhis_app/features/user/screens/events_screen.dart';

// Brand colors
const _kNavBgStart = Color(0xFF5666DA);
const _kNavBgEnd = Color(0xFF6475E8);

const _kActiveFg = Colors.white;
const _kIdleFg = Color(0xFFBFC8F3);

class CustomNavBar extends StatelessWidget {
  final int currentIndex;

  const CustomNavBar({
    super.key,
    required this.currentIndex,
  });

  void _onTap(BuildContext context, int index) {
    if (index == currentIndex) return;

    Widget page;

    switch (index) {
      case 0:
        page = const HomeScreen();
        break;
      case 1:
        page = const EventsWidget();
        break;
      case 2:
        page = const ChatCopyWidget();
        break;
      case 3:
        page = const AccountWidget();
        break;
      default:
        page = const HomeScreen();
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionDuration: const Duration(milliseconds: 220),
        reverseTransitionDuration: const Duration(milliseconds: 180),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            ),
            child: child,
          );
        },
      ),
    );
  }

  Widget _buildItem({
    required BuildContext context,
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final bool selected = currentIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () => _onTap(context, index),
        splashColor: Colors.white.withValues(alpha: 0.10),
        highlightColor: Colors.white.withValues(alpha: 0.06),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: AnimatedScale(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutBack,
            scale: selected ? 1.08 : 1.0,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: animation,
                        child: child,
                      ),
                    );
                  },
                  child: Icon(
                    selected ? activeIcon : icon,
                    key: ValueKey('$label-$selected'),
                    size: selected ? 25 : 24,
                    color: selected ? _kActiveFg : _kIdleFg,
                  ),
                ),
                const SizedBox(height: 5),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  style: TextStyle(
                    fontSize: selected ? 12 : 11,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    color: selected ? _kActiveFg : _kIdleFg,
                    letterSpacing: 0.1,
                  ),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        height: 74,
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              _kNavBgStart,
              _kNavBgEnd,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 14,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildItem(
              context: context,
              index: 0,
              icon: Icons.home_outlined,
              activeIcon: Icons.home_rounded,
              label: 'Home',
            ),
            _buildItem(
              context: context,
              index: 1,
              icon: Icons.event_outlined,
              activeIcon: Icons.event_rounded,
              label: 'Event',
            ),
            _buildItem(
              context: context,
              index: 2,
              icon: Icons.chat_bubble_outline_rounded,
              activeIcon: Icons.chat_rounded,
              label: 'Chat',
            ),
            _buildItem(
              context: context,
              index: 3,
              icon: Icons.person_outline_rounded,
              activeIcon: Icons.person_rounded,
              label: 'Account',
            ),
          ],
        ),
      ),
    );
  }
}