import 'package:flutter/material.dart';

import 'package:ramhis_app/features/user/screens/home_screen.dart';
import 'package:ramhis_app/features/user/screens/chat_screen.dart';
import 'package:ramhis_app/features/user/screens/account_screen.dart';
import 'package:ramhis_app/features/user/screens/events_screen.dart';

// RAMHIS Medical Blue Theme
const _kNavBg = Color(0xFF10539B);
const _kNavBgDark = Color(0xFF0B4380);

const _kActiveFg = Color(0xFFFFFFFF);
const _kActiveBg = Color(0xFF1863B5);
const _kActiveAccent = Color(0xFF8EC1DA);

const _kIdleFg = Color(0xFFCDE1EC);
const _kBorder = Color(0xFFE3F2FD);

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
          margin: const EdgeInsets.symmetric(
            horizontal: 5,
            vertical: 4,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 5,
          ),
          child: AnimatedScale(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutBack,
            scale: selected ? 1.04 : 1.0,
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
                    size: selected ? 23 : 22,
                    color: selected ? _kActiveFg : _kIdleFg,
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  style: TextStyle(
                    fontSize: selected ? 11.5 : 10.5,
                    fontWeight:
                        selected ? FontWeight.w800 : FontWeight.w600,
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
        height: 76,
        padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _kNavBg,
              _kNavBgDark,
            ],
          ),
          border: const Border(
            top: BorderSide(
              color: _kBorder,
              width: 0.8,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, -4),
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
